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

if (Get-Process -Name 'vmware-vmx' -ErrorAction SilentlyContinue) {
    throw 'A VMware virtual machine is running. Power off the evidence VM before backup.'
}

$vmLocks = @(Get-ChildItem -LiteralPath $src -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '*.lck' })
if ($vmLocks.Count -gt 0) {
    throw "VMware lock files are present in $src. Close VMware Workstation and confirm the VM is powered off."
}

$sourceFiles = @(Get-ChildItem -LiteralPath $src -Recurse -File)
$sourceBytes = ($sourceFiles | Measure-Object -Property Length -Sum).Sum
$destinationDrive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($backupsRoot).TrimEnd(':','\'))
if ($destinationDrive.Free -lt ($sourceBytes + 5GB)) {
    throw ('Insufficient free space. Required including 5 GB safety margin: {0:N2} GB; available: {1:N2} GB.' -f (($sourceBytes + 5GB) / 1GB), ($destinationDrive.Free / 1GB))
}

Write-Host "[Step 12] Ensuring backups root exists" -ForegroundColor Cyan
[System.IO.Directory]::CreateDirectory($backupsRoot) | Out-Null

if (Test-Path $dst) {
    throw "Destination already exists: $dst. Rename or delete before proceeding."
}

Write-Host "[Step 12] Copying VM directory: $src -> $dst" -ForegroundColor Cyan
Write-Host "         (This may take several minutes depending on VM size.)"
[System.IO.Directory]::CreateDirectory($dst) | Out-Null
Get-ChildItem -LiteralPath $src -Force |
    Copy-Item -Destination $dst -Recurse -Force

Write-Host "[Step 12] Comparing source and backup SHA-256 hashes" -ForegroundColor Cyan
$sourcePrefixLength = $src.TrimEnd('\').Length + 1
$manifestRows = foreach ($sourceFile in $sourceFiles) {
    $relativePath = $sourceFile.FullName.Substring($sourcePrefixLength)
    $backupFile = Join-Path $dst $relativePath
    if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf)) {
        throw "Backup file is missing: $backupFile"
    }

    $sourceHash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
    $backupHash = (Get-FileHash -LiteralPath $backupFile -Algorithm SHA256).Hash
    [pscustomobject]@{
        Algorithm      = 'SHA256'
        RelativePath   = $relativePath
        SizeBytes      = $sourceFile.Length
        SourceSHA256   = $sourceHash
        BackupSHA256   = $backupHash
        HashMatch      = ($sourceHash -eq $backupHash)
    }
}

$manifestRows | Export-Csv -Path $manifest -NoTypeInformation -Encoding utf8

$mismatches = @($manifestRows | Where-Object { -not $_.HashMatch })
if ($mismatches.Count -gt 0) {
    throw "$($mismatches.Count) backup file(s) failed SHA-256 verification. Do not use this backup."
}

$count = $manifestRows.Count
Write-Host ""
Write-Host "[Step 12] Complete." -ForegroundColor Green
Write-Host "  Backup folder    : $dst"
Write-Host "  Manifest         : $manifest"
Write-Host "  Files hashed     : $count"
Write-Host "  Hash mismatches  : 0"
Write-Host ""
Write-Host "Record the backup name in testbed/snapshots.md alongside the snapshot entry."
