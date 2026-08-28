<#
.SYNOPSIS
Precondition setup for Scenario 5 (File deletion via Explorer and Recycle Bin).

.DESCRIPTION
Stages a single deletion target file inside the guest VM. The file is
written via Set-Content (PowerShell), NOT dragged in through Explorer,
so no ShellBag entries are written for its parent folder during setup.
Only the deliberate A01 to A05 Explorer clicks performed during the
scenario should produce ShellBag rows in UsrClass.dat / NTUSER.DAT.

Path (lowercase snake_case per naming scheme 2026-08-17):

    C:\DISS_TESTDATA\scenario5_delete\
        scenario5_target.txt

Contents include a fixed marker string plus the UTC of staging so the
exact file body is reproducible from the ground_truth.csv. Size is a
handful of bytes; the file goes to the Recycle Bin (well under the
4 GB per file skip threshold) rather than being permanently deleted.

.NOTES
Run inside the guest (DISS-Win11-25H2-Testbed VM) as user 'dfanalyst',
BEFORE loading the Log-Action helper and BEFORE opening File Explorer:

    powershell -ExecutionPolicy Bypass -File .\scenario5_prepare_file.ps1

Or paste the whole file into a PowerShell window. Non-elevated PowerShell
is fine; the folder lives under C:\DISS_TESTDATA which is world-writable
in this testbed.

Author: Syed Muhammad Saqlain Abbas (W21634541)
Repo:   github.com/dx7er/msc-diss-7csef001w
Module: 7CSEF001W.2 MSc Cyber Security & Forensics Project
#>

$root = 'C:\DISS_TESTDATA\scenario5_delete'
$file = Join-Path $root 'scenario5_target.txt'

New-Item -ItemType Directory -Force -Path $root | Out-Null

$stagedUtc = (Get-Date).ToUniversalTime().ToString('o')
$body = @(
    'Scenario 5 deletion target file.',
    "Staged (UTC): $stagedUtc",
    'This file is created by scenario5_prepare_file.ps1 before scenario execution.',
    'It is deleted to the Recycle Bin during A02 and permanently removed during A05.'
) -join "`r`n"

Set-Content -Path $file -Value $body -Encoding UTF8 -NoNewline

Write-Host "Scenario 5 target staged at $file"
Get-Item $file | Select-Object FullName, Length, LastWriteTimeUtc

$sha = (Get-FileHash -Algorithm SHA256 -Path $file).Hash
Write-Host "SHA-256: $sha"
Write-Host ""
Write-Host "Record the following in the ground_truth.csv (Note or ObservedOutcome column):"
Write-Host "  StagedUTC : $stagedUtc"
Write-Host "  SHA256    : $sha"
