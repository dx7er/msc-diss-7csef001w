<#
.SYNOPSIS
    One shot Scenario 4 USB stick preparation. Formats NTFS with label DISS-USB,
    stages HelloWorld.exe under \PORTABLE\, verifies the SHA 256 hash, and
    writes usb_identity.txt to scenarios\scenario_4\evaluation\ for chain of
    custody. Run once before Scenario 4 Run 1.

.DESCRIPTION
    Combines the manual format / copy / capture steps of the Scenario 4 runbook
    into a single scripted flow. Safe by default: enumerates USB disks, prompts
    for the disk number, and refuses to touch anything that is not on the USB
    bus. All destructive operations happen only after the user types the disk
    number to confirm.

    Steps executed:
      1. Locate the repo root by walking up from this script's location.
      2. Verify the source HelloWorld.exe exists at
         scenarios\scenario_4\setup\HelloWorld.exe and matches the recorded
         build hash.
      3. Enumerate USB disks (Win32_DiskDrive InterfaceType = USB) and print
         them with size, model, PNP identity.
      4. Prompt for the disk number of the DISS-USB stick.
      5. Clear-Disk / New-Partition / Format-Volume (NTFS, label DISS-USB).
      6. Create \PORTABLE\ on the new volume and copy HelloWorld.exe.
      7. Verify the on stick SHA 256 matches the source hash.
      8. Extract VID / PID / serial from PNPDeviceID and write
         scenarios\scenario_4\evaluation\usb_identity.txt.
      9. Print an Eject reminder.

.EXAMPLE
    # Elevated PowerShell on the host
    cd D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios
    .\scenario4_prepare_usb.ps1

.NOTES
    Requires Administrator (Clear-Disk / New-Partition / Format-Volume).
    Runs on the host, not the guest. Same physical stick used for all 3 reps,
    so this script runs once total, before Run 1.
#>

[CmdletBinding()]
param(
    [string]$ExpectedHash = '0C1F7FDF4A47F67D36042559E0B2B91E557CC1DD12B097BB78BA01EC7182954A',
    [string]$VolumeLabel  = 'DISS-USB'
)

$ErrorActionPreference = 'Stop'

# ---- Elevation check -------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run in an elevated PowerShell (Run as Administrator).'
}

# ---- Locate repo root ------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent (Split-Path -Parent $scriptDir)
$setupExe  = Join-Path $repoRoot 'scenarios\scenario_4\setup\HelloWorld.exe'
$evalDir   = Join-Path $repoRoot 'scenarios\scenario_4\evaluation'
$identity  = Join-Path $evalDir  'usb_identity.txt'

if (-not (Test-Path $setupExe)) {
    throw "Cannot find $setupExe. Are you running from the msc-diss-7csef001w repo?"
}
New-Item -ItemType Directory -Path $evalDir -Force | Out-Null

# ---- Verify source hash before doing anything ------------------------------
$sourceHash = (Get-FileHash $setupExe -Algorithm SHA256).Hash.ToUpper()
if ($sourceHash -ne $ExpectedHash.ToUpper()) {
    throw "Source HelloWorld.exe hash mismatch. Expected $ExpectedHash, got $sourceHash. Repo may be corrupted; investigate before proceeding."
}
Write-Host "Source HelloWorld.exe hash OK: $sourceHash" -ForegroundColor Green
Write-Host ""

# ---- Enumerate USB disks ---------------------------------------------------
$usbDisks = Get-Disk | Where-Object BusType -eq 'USB'
if (-not $usbDisks) {
    throw 'No USB storage devices detected. Plug in the DISS-USB stick and rerun.'
}

Write-Host 'USB storage devices attached to the host:' -ForegroundColor Cyan
foreach ($gd in $usbDisks) {
    # Pair Get-Disk to Win32_DiskDrive by disk index for VID/PID/serial parsing
    $wmi  = Get-CimInstance Win32_DiskDrive | Where-Object Index -eq $gd.Number | Select-Object -First 1
    $pnp  = if ($wmi) { $wmi.PNPDeviceID } else { '' }
    $vid  = if ($pnp -match 'VID_([0-9A-F]{4})') { $Matches[1] } else { '(?)' }
    $pnid = if ($pnp -match 'PID_([0-9A-F]{4})') { $Matches[1] } else { '(?)' }
    $ser  = if ($pnp) { ($pnp -split '\\')[-1] } else { '(?)' }

    Write-Host ("  Disk {0}: {1}  ({2} GB)  VID={3} PID={4} Serial={5}" -f `
        $gd.Number, $gd.FriendlyName, [math]::Round($gd.Size/1GB,2), $vid, $pnid, $ser)
}
Write-Host ""

# ---- Prompt for disk number ------------------------------------------------
$diskNumber = Read-Host 'Enter the Disk number of the DISS-USB stick to WIPE and REFORMAT'
if ($diskNumber -notmatch '^\d+$') { throw "Not a number: $diskNumber" }
$diskNumber = [int]$diskNumber

$target = Get-Disk -Number $diskNumber -ErrorAction Stop
if ($target.BusType -ne 'USB') {
    throw "Disk $diskNumber has BusType $($target.BusType), not USB. Refusing to format non USB media."
}
Write-Host ""
Write-Host "About to WIPE Disk $diskNumber ($($target.FriendlyName), $([math]::Round($target.Size/1GB,2)) GB)." -ForegroundColor Yellow
$confirm = Read-Host 'Type YES to proceed'
if ($confirm -ne 'YES') { throw 'Aborted by user.' }

# ---- Format ---------------------------------------------------------------
# Use diskpart for the wipe + init + partition + format. On small USB sticks
# Clear-Disk + Initialize-Disk + New-Partition intermittently hits
# "Not enough available capacity" because the old partition table is not
# fully dropped. diskpart's `clean` zeros the sector, then `create partition
# primary` + `format quick` reliably produces a single NTFS volume.

Write-Host 'Wiping and reformatting via diskpart ...' -ForegroundColor Cyan
$dpScript = @"
select disk $diskNumber
clean
create partition primary
format fs=ntfs label=$VolumeLabel quick
assign
exit
"@
$dpTmp = New-TemporaryFile
Set-Content -Path $dpTmp -Value $dpScript -Encoding ASCII
$dpOut = & diskpart /s $dpTmp 2>&1
Remove-Item $dpTmp -Force
if ($LASTEXITCODE -ne 0) {
    $dpOut | ForEach-Object { Write-Host $_ }
    throw "diskpart returned exit code $LASTEXITCODE. See output above."
}

# Give the mount manager a moment to expose the new volume
Start-Sleep -Seconds 3

# Locate the freshly formatted DISS-USB volume on the correct disk
$part = Get-Partition -DiskNumber $diskNumber | Where-Object { $_.DriveLetter } | Select-Object -First 1
if (-not $part) {
    throw "diskpart completed but no drive letter is assigned to Disk $diskNumber. Check Disk Management."
}
$root = "$($part.DriveLetter):"
$vol  = Get-Volume -DriveLetter $part.DriveLetter
if ($vol.FileSystemLabel -ne $VolumeLabel) {
    Write-Warning "Volume label came back as '$($vol.FileSystemLabel)' rather than '$VolumeLabel'; forcing relabel."
    Set-Volume -DriveLetter $part.DriveLetter -NewFileSystemLabel $VolumeLabel
    $vol = Get-Volume -DriveLetter $part.DriveLetter
}
Write-Host "Formatted. Volume root: $root  Label: $($vol.FileSystemLabel)  FS: $($vol.FileSystem)" -ForegroundColor Green

# ---- Stage HelloWorld.exe --------------------------------------------------
$portable = Join-Path $root 'PORTABLE'
New-Item -ItemType Directory -Path $portable -Force | Out-Null
Copy-Item $setupExe (Join-Path $portable 'HelloWorld.exe') -Force

$stickHash = (Get-FileHash (Join-Path $portable 'HelloWorld.exe') -Algorithm SHA256).Hash.ToUpper()
if ($stickHash -ne $ExpectedHash.ToUpper()) {
    throw "On stick hash mismatch after copy. Expected $ExpectedHash, got $stickHash. Retry or replace stick."
}
Write-Host "HelloWorld.exe staged and verified: $stickHash" -ForegroundColor Green

# ---- Rebuild identity for the (now formatted) stick ------------------------
$disk = Get-CimInstance Win32_DiskDrive | Where-Object {
    $_.InterfaceType -eq 'USB' -and $_.Index -eq $diskNumber
} | Select-Object -First 1

$pnp    = $disk.PNPDeviceID
$vid    = if ($pnp -match 'VID_([0-9A-F]{4})') { $Matches[1] } else { '(unknown)' }
$pnid   = if ($pnp -match 'PID_([0-9A-F]{4})') { $Matches[1] } else { '(unknown)' }
$serial = ($pnp -split '\\')[-1]

$logicalVol = Get-CimAssociatedInstance -InputObject (
    Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition |
        Select-Object -First 1
) -ResultClassName Win32_LogicalDisk | Select-Object -First 1

$captureUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$content = @"
Scenario 4 DISS-USB identity
Captured: $captureUtc
Host:     $env:COMPUTERNAME
User:     $env:USERNAME

Disk index:      $($disk.Index)
Model:           $($disk.Model)
Size (GB):       $([math]::Round($disk.Size/1GB,2))
PNPDeviceID:     $pnp
VID:             $vid
PID:             $pnid
Serial (PnP):    $serial
Hardware ID:     USB\VID_${vid}&PID_${pnid}

Drive letter:    $($logicalVol.DeviceID)
Volume label:    $($logicalVol.VolumeName)
Filesystem:      $($logicalVol.FileSystem)
Volume serial:   $($logicalVol.VolumeSerialNumber)

Payload:
  Path:          \PORTABLE\HelloWorld.exe
  SHA-256:       $stickHash
  Source:        scenarios/scenario_4/setup/HelloWorld.exe
  Same physical stick across Run 1, Run 2, Run 3 (per catalogue).
"@

Set-Content -Path $identity -Value $content -Encoding UTF8
Write-Host ""
Write-Host "Wrote identity to $identity" -ForegroundColor Green
Write-Host ""
Write-Host $content
Write-Host ""
Write-Host "Prep complete. Next steps:" -ForegroundColor Cyan
Write-Host "  1. Safely eject the stick from the host (system tray, Eject DISS-USB)."
Write-Host "  2. Revert the VM to baseline_pre_scenarios, power on, sign in."
Write-Host "  3. Physically plug the stick back in, then VM > Removable Devices > Connect."
Write-Host "  4. Load logger, execute A01 to A07, Save-Log -Scenario 4 -Run 1."
