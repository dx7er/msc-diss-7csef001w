<#
    Step 12 (HOST) - Independent baseline backup with SHA-256 manifest
    Testbed: TB-W11-25H2-01

    Purpose:
        A VMware snapshot is metadata on top of split VMDKs; it is NOT a
        backup. If a base file is corrupted or accidentally deleted, the
        snapshot is worthless. This script copies the entire VM directory
        (including all split delta VMDKs) off the working location and
        computes a SHA-256 manifest of every file.

    Prerequisites:
        - VM is POWERED OFF.
        - VMware Workstation is CLOSED completely.
        - Adequate disk space at $dst location (VM folder is ~80 GB).

    Run on the HOST (not the guest), in admin PowerShell:
        powershell.exe -ExecutionPolicy Bypass -File .\12-baseline-backup-HOST.ps1

    Output:
        D:\UOW\SEM3\Backups\<backup-name>\   (mirror of VM folder)
        D:\UOW\SEM3\Backups\<backup-name>-SHA256.csv
#>

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$src         = 'D:\UOW\SEM3\DISS-Win11-Testbed-VM'
$backupsRoot = 'D:\UOW\SEM3\Backups'
$backupName  = 'B00-CANDIDATE-W11-25H2-26200.6584-20260717'
# ---------------------

$dst      = Join-Path $backupsRoot $backupName
$manifest = "$dst-SHA256.csv"

Write-Host "[Step 12] Verifying source exists" -ForegroundColor Cyan
if (-not (Test-Path $src)) { throw "Source not found: $src" }

Write-Host "[Step 12] Ensuring backups root exists" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $backupsRoot -Force | Out-Null

if (Test-Path $dst) {
    throw "Destination already exists: $dst. Rename or delete before proceeding."
}

Write-Host "[Step 12] Copying VM directory: $src -> $dst" -ForegroundColor Cyan
Write-Host "         (This may take several minutes depending on VM size.)"
Copy-Item -LiteralPath $src -Destination $dst -Recurse

Write-Host "[Step 12] Computing SHA-256 for every file in the backup" -ForegroundColor Cyan
Get-ChildItem -LiteralPath $dst -Recurse -File |
    Get-FileHash -Algorithm SHA256 |
    Select-Object Algorithm, Hash, Path |
    Export-Csv -Path $manifest -NoTypeInformation -Encoding utf8

$count = (Import-Csv $manifest | Measure-Object).Count
Write-Host ""
Write-Host "[Step 12] Complete." -ForegroundColor Green
Write-Host "  Backup folder    : $dst"
Write-Host "  Manifest         : $manifest"
Write-Host "  Files hashed     : $count"
Write-Host ""
Write-Host "Record the backup name in testbed/snapshots.md alongside the snapshot entry."
