<#
.SYNOPSIS
    Report VID, PID, serial number, and volume identity of USB storage devices
    currently attached to the host. Used once before Scenario 4 Run 1 to record
    the DISS-USB stick identity for ground truth.

.DESCRIPTION
    Filters Win32_DiskDrive to bus type USB, correlates each disk to its
    volume (label, drive letter, filesystem, size), and extracts VID, PID,
    and serial from the PNPDeviceID. Same physical stick across all 3 reps,
    so this only needs running once, before the stick is disconnected from
    the host and attached to the VM.

.EXAMPLE
    .\scenario4_capture_usb_identity.ps1

.NOTES
    Reads only. Runs unelevated. No side effects on the stick or the host.
    Output rows are intended to be copied verbatim into
    scenarios/scenario_4/evaluation/usb_identity.txt for chain of custody.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "USB storage devices attached to host at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC$([TimeZoneInfo]::Local.GetUtcOffset((Get-Date)))" -ForegroundColor Cyan
Write-Host ""

$usbDisks = Get-CimInstance Win32_DiskDrive | Where-Object { $_.InterfaceType -eq 'USB' }

if (-not $usbDisks) {
    Write-Warning "No USB storage devices detected. Plug the DISS-USB stick into the host and re-run."
    return
}

foreach ($disk in $usbDisks) {
    $pnp = $disk.PNPDeviceID
    $vid  = if ($pnp -match 'VID_([0-9A-F]{4})')  { $Matches[1] } else { '(unknown)' }
    $pid  = if ($pnp -match 'PID_([0-9A-F]{4})')  { $Matches[1] } else { '(unknown)' }
    $serial = ($pnp -split '\\')[-1]

    Write-Host "Disk:            $($disk.DeviceID)"  -ForegroundColor Yellow
    Write-Host "Model:           $($disk.Model)"
    Write-Host "Size:            $([math]::Round($disk.Size/1GB,2)) GB"
    Write-Host "VID:             $vid"
    Write-Host "PID:             $pid"
    Write-Host "Serial (PnP):    $serial"
    Write-Host "PNPDeviceID:     $pnp"
    Write-Host "PnP hardware:    USB\VID_${vid}&PID_${pid}"

    $partitions = Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition
    foreach ($part in $partitions) {
        $volumes = Get-CimAssociatedInstance -InputObject $part -ResultClassName Win32_LogicalDisk
        foreach ($vol in $volumes) {
            Write-Host "Drive letter:    $($vol.DeviceID)"
            Write-Host "Volume label:    $($vol.VolumeName)"
            Write-Host "Filesystem:      $($vol.FileSystem)"
            Write-Host "Volume serial:   $($vol.VolumeSerialNumber)"
        }
    }
    Write-Host ""
}

Write-Host "If the DISS-USB stick is listed:" -ForegroundColor Green
Write-Host "  1. Confirm 'Volume label' = DISS-USB and 'Filesystem' = NTFS."
Write-Host "  2. Copy the VID, PID and Serial (PnP) lines into"
Write-Host "     scenarios\scenario_4\evaluation\usb_identity.txt (any run's evaluation folder is fine; same identity applies to all 3 runs)."
Write-Host "  3. Safely eject the stick from the host before attaching it to the VM for Run 1."
