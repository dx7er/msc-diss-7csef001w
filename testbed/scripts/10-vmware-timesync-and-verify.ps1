<#
    Step 10 (guest portion) - Disable VMware periodic timesync and verify state
    Testbed: TB-W11-25H2-01

    Purpose:
        Disable VMware Tools periodic time synchronisation inside the guest.
        Retain the one-off correction at boot and snapshot restore.
        Capture network adapter state to prove isolation.

        The rest of Step 10 (drag-drop, copy-paste, shared folders, CD/DVD,
        network to Host-only, AutoProtect off, snapshot mode power-off,
        USB controller behaviour) is done in VMware Workstation UI on the
        host while the VM is shut down. See testbed-checklist.md.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\10-vmware-timesync-and-verify.ps1

    Output:
        C:\DISS_Config\VMware-Timesync-Before.txt
        C:\DISS_Config\VMware-Timesync-After.txt
        C:\DISS_Config\Network-Isolation.txt
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'
New-Item -ItemType Directory -Path $config -Force | Out-Null

$toolbox = 'C:\Program Files\VMware\VMware Tools\VMwareToolboxCmd.exe'

Write-Host "[Step 10] Recording VMware timesync status BEFORE" -ForegroundColor Cyan
if (Test-Path $toolbox) {
    & $toolbox timesync status 2>&1 |
        Tee-Object -FilePath (Join-Path $config 'VMware-Timesync-Before.txt')
} else {
    Write-Warning "VMware Tools not found at $toolbox"
    "VMware Tools missing" | Out-File (Join-Path $config 'VMware-Timesync-Before.txt') -Encoding utf8
}

Write-Host "[Step 10] Disabling VMware periodic timesync" -ForegroundColor Cyan
if (Test-Path $toolbox) { & $toolbox timesync disable | Out-Null }

Write-Host "[Step 10] Recording VMware timesync status AFTER" -ForegroundColor Cyan
if (Test-Path $toolbox) {
    & $toolbox timesync status 2>&1 |
        Tee-Object -FilePath (Join-Path $config 'VMware-Timesync-After.txt')
}

Write-Host "[Step 10] Capturing network adapter state (should show no internet)" -ForegroundColor Cyan
$netOut = Join-Path $config 'Network-Isolation.txt'
"=== Network adapters ==="  | Out-File $netOut -Encoding utf8
Get-NetAdapter |
    Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress |
    Format-Table -AutoSize |
    Out-File $netOut -Append -Encoding utf8

"=== IP configuration ==="  | Out-File $netOut -Append -Encoding utf8
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.PrefixOrigin -ne 'WellKnown' } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength, AddressState |
    Format-Table -AutoSize |
    Out-File $netOut -Append -Encoding utf8

"=== Default routes ==="   | Out-File $netOut -Append -Encoding utf8
Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Select-Object InterfaceAlias, NextHop, RouteMetric |
    Format-Table -AutoSize |
    Out-File $netOut -Append -Encoding utf8

"=== Reachability test (should fail if isolated) ===" | Out-File $netOut -Append -Encoding utf8
try {
    Test-NetConnection -ComputerName "1.1.1.1" -InformationLevel Quiet -WarningAction SilentlyContinue |
        Out-File $netOut -Append -Encoding utf8
} catch {
    "Test-NetConnection failed - likely fully isolated" | Out-File $netOut -Append -Encoding utf8
}

Get-Content $netOut

Write-Host ""
Write-Host "[Step 10 guest] Complete." -ForegroundColor Green
Write-Host ""
Write-Host "[Step 10 host] Now do these in VMware Workstation UI (VM shut down):" -ForegroundColor Yellow
Write-Host "  1. VM > Settings > Options > VMware Tools:      updates = Manual"
Write-Host "  2. VM > Settings > Options > Guest Isolation:   drag-drop = OFF, copy-paste = OFF"
Write-Host "  3. VM > Settings > Options > Shared Folders:    Disabled, remove any"
Write-Host "  4. VM > Settings > Hardware > CD/DVD:           uncheck Connected AND Connect-at-power-on, disconnect ISO"
Write-Host "  5. VM > Settings > Options > AutoProtect:       disabled"
Write-Host "  6. VM > Settings > Options > Snapshots:         Power off (not suspend)"
Write-Host "  7. VM > Settings > Hardware > USB Controller:   Keep. 'Ask me what to do'. No auto-connect."
Write-Host "  8. VM > Settings > Hardware > Network Adapter:  Host-only, uncheck Connected AND Connect-at-power-on"
