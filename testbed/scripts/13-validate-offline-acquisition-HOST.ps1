<#
    Step 13 (HOST) - Validate offline forensic acquisition against a
    working copy of the candidate baseline.
    Testbed: TB-W11-25H2-01

    Purpose:
        Prove that we can pull artefacts out of the VMDK from the host,
        without booting the guest. If this fails, no evidence collected
        during scenarios is trustworthy.

    Approach:
        1. Use qemu-img (or 7-Zip) to open the working-copy VMDK read-only.
           This script uses 7-Zip because it's ubiquitous on Windows.
           Install: winget install 7zip.7zip
        2. Extract representative artefact files.
        3. SHA-256 hash them for the acquisition manifest.
        4. Do NOT mount the ONLY copy read-write.

    Prerequisites:
        - Step 12 backup exists at D:\UOW\SEM3\Backups\B00-CANDIDATE-*.
        - 7-Zip 24.09 or later installed.
        - VM is powered off; VMware Workstation is closed.

    Run on the HOST in admin PowerShell:
        powershell.exe -ExecutionPolicy Bypass -File .\13-validate-offline-acquisition-HOST.ps1
#>

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$backupRoot = 'D:\UOW\SEM3\Backups\B00-CANDIDATE-W11-25H2-26200.6584-20260717'
$stagingDir = 'D:\UOW\SEM3\Backups\B00-CANDIDATE-VALIDATION'
$sevenZip   = 'C:\Program Files\7-Zip\7z.exe'
$guestUser  = 'dfanalyst'
# ---------------------

Write-Host "[Step 13] Locating 7-Zip" -ForegroundColor Cyan
if (-not (Test-Path $sevenZip)) {
    throw "7-Zip not found at $sevenZip. Install with: winget install 7zip.7zip"
}

Write-Host "[Step 13] Verifying working copy exists" -ForegroundColor Cyan
# First try to find a descriptor VMDK (monolithic-sparse or split-sparse layouts).
$mainVmdk = Get-ChildItem -LiteralPath $backupRoot -Filter '*.vmdk' |
    Where-Object { $_.Name -notmatch '-s\d+\.vmdk$' -and $_.Name -notmatch '-flat\.vmdk$' } |
    Select-Object -First 1
# Preallocated (monolithic-flat) layouts have <name>.vmdk + <name>-flat.vmdk. 7-Zip
# reads the -flat file directly in that case.
if (-not $mainVmdk) {
    $mainVmdk = Get-ChildItem -LiteralPath $backupRoot -Filter '*-flat.vmdk' |
        Select-Object -First 1
    if ($mainVmdk) { Write-Host "  Preallocated layout detected; extracting from -flat directly." -ForegroundColor Yellow }
}
if (-not $mainVmdk) { throw "No VMDK found in $backupRoot" }
Write-Host "  Using: $($mainVmdk.FullName)"

Write-Host "[Step 13] Preparing staging directory" -ForegroundColor Cyan
if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force }
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

# Paths inside the guest we want to extract
$targets = @(
    "Windows\Prefetch",
    "Windows\System32\winevt\Logs",
    "Windows\System32\config\SYSTEM",
    "Windows\System32\config\SOFTWARE",
    "Windows\AppCompat\Programs\Amcache.hve",
    "Users\$guestUser\NTUSER.DAT",
    "Users\$guestUser\NTUSER.DAT.LOG1",
    "Users\$guestUser\NTUSER.DAT.LOG2",
    "Users\$guestUser\AppData\Local\Microsoft\Windows\UsrClass.dat",
    "Users\$guestUser\AppData\Local\Microsoft\Windows\UsrClass.dat.LOG1",
    "Users\$guestUser\AppData\Local\Microsoft\Windows\UsrClass.dat.LOG2"
)

Write-Host "[Step 13] Extracting targeted artefacts (read-only)" -ForegroundColor Cyan
foreach ($t in $targets) {
    Write-Host "  Extracting: $t"
    & $sevenZip x "-o$stagingDir" $mainVmdk.FullName $t -y | Out-Null
}

Write-Host "[Step 13] Computing SHA-256 manifest of extracted artefacts" -ForegroundColor Cyan
$manifest = Join-Path $stagingDir 'acquisition-manifest.csv'
Get-ChildItem -LiteralPath $stagingDir -Recurse -File |
    Where-Object { $_.Name -ne 'acquisition-manifest.csv' } |
    Get-FileHash -Algorithm SHA256 |
    Select-Object Algorithm, Hash, Path, @{n='SizeBytes';e={(Get-Item $_.Path).Length}} |
    Export-Csv -Path $manifest -NoTypeInformation -Encoding utf8

Write-Host ""
Write-Host "[Step 13] Complete." -ForegroundColor Green
Write-Host "  Extracted to     : $stagingDir"
Write-Host "  Manifest         : $manifest"
Write-Host ""
Write-Host "Verify:" -ForegroundColor Yellow
Write-Host "  - Prefetch\ contains .pf files"
Write-Host "  - winevt\Logs\ contains Security.evtx, System.evtx, Application.evtx"
Write-Host "  - Users\$guestUser\ contains NTUSER.DAT (non-zero bytes)"
Write-Host "  - UsrClass.dat exists"
Write-Host ""
Write-Host "If any of the above are missing or empty, acquisition method needs work"
Write-Host "before scenarios begin. Do not proceed to Step 14 pilots until this passes."
