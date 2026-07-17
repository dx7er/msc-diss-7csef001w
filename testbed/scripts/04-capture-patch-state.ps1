<#
    Step 4 - Capture final patch state (Windows, Defender, VMware Tools)
    Testbed: TB-W11-25H2-01

    Purpose:
        Run AFTER all Windows Updates, Microsoft Store updates, VMware Tools
        install, and scenario-app installs are complete AND the VM has been
        rebooted twice. Captures the frozen patch state so the report can
        cite exact hotfix IDs, Defender signature version and Tools version.

    Prerequisites (do these manually before running this script):
        1. VM network adapter set to NAT (temporarily, for downloads only).
        2. Settings > Windows Update > Check for updates. Install all normal
           stable updates (NOT preview updates). Reboot. Repeat until
           "You're up to date" with no pending updates.
        3. Open Microsoft Store > Library > Get updates. Update any apps
           used in scenarios (skip anything you will not use).
        4. Install VMware Tools if not already installed
           (VM menu > Install VMware Tools, then run setup64 in the guest).
        5. Install every scenario application needed. For this study,
           Notepad ships by default. If you add other apps, note them in
           vm-specification.md.
        6. Restart the VM twice (two clean reboots).

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\04-capture-patch-state.ps1

    Output (guest paths, copied later to repo):
        C:\DISS_Config\Installed-Hotfixes.txt
        C:\DISS_Config\Defender-Version.txt
        C:\DISS_Config\VMware-Tools-Version.txt
        C:\DISS_Config\OS-Uptime-And-Boot.txt
#>

$ErrorActionPreference = 'Stop'
$config = 'C:\DISS_Config'

Write-Host "[Step 4] Ensuring $config exists" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $config -Force | Out-Null

Write-Host "[Step 4] Recording installed hotfixes" -ForegroundColor Cyan
Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object HotFixID, Description, InstalledOn |
    Format-Table -AutoSize |
    Out-File (Join-Path $config 'Installed-Hotfixes.txt') -Encoding utf8
Write-Host "  $(Get-HotFix | Measure-Object | Select-Object -ExpandProperty Count) hotfix entries recorded"

Write-Host "[Step 4] Recording Defender version state" -ForegroundColor Cyan
Get-MpComputerStatus |
    Select-Object AMProductVersion, AMEngineVersion,
                  AntivirusSignatureVersion, AntivirusSignatureLastUpdated,
                  NISSignatureVersion, NISEngineVersion |
    Format-List |
    Out-File (Join-Path $config 'Defender-Version.txt') -Encoding utf8
Get-Content (Join-Path $config 'Defender-Version.txt')

Write-Host "[Step 4] Recording VMware Tools version" -ForegroundColor Cyan
$toolsPath = 'C:\Program Files\VMware\VMware Tools\vmtoolsd.exe'
if (Test-Path $toolsPath) {
    (Get-Item $toolsPath).VersionInfo |
        Select-Object FileVersion, ProductVersion, CompanyName |
        Format-List |
        Out-File (Join-Path $config 'VMware-Tools-Version.txt') -Encoding utf8
    Get-Content (Join-Path $config 'VMware-Tools-Version.txt')
} else {
    "VMware Tools NOT INSTALLED at $toolsPath" |
        Out-File (Join-Path $config 'VMware-Tools-Version.txt') -Encoding utf8
    Write-Warning "VMware Tools not found. Install before proceeding to Step 5."
}

Write-Host "[Step 4] Recording OS boot and uptime info" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
[PSCustomObject]@{
    LastBootUpTimeUTC = $os.LastBootUpTime.ToUniversalTime().ToString("o")
    CurrentTimeUTC    = ([DateTime]::UtcNow).ToString("o")
    UptimeMinutes     = [math]::Round((New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date)).TotalMinutes, 1)
    Caption           = $os.Caption
    Version           = $os.Version
    BuildNumber       = $os.BuildNumber
    OSArchitecture    = $os.OSArchitecture
    InstallDateUTC    = $os.InstallDate.ToUniversalTime().ToString("o")
} | Format-List | Out-File (Join-Path $config 'OS-Uptime-And-Boot.txt') -Encoding utf8
Get-Content (Join-Path $config 'OS-Uptime-And-Boot.txt')

Write-Host ""
Write-Host "[Step 4] Complete. Verify:" -ForegroundColor Green
Write-Host "  - Installed-Hotfixes.txt lists all cumulative and security updates"
Write-Host "  - Defender-Version.txt shows a recent AntivirusSignatureLastUpdated"
Write-Host "  - VMware-Tools-Version.txt shows a real FileVersion (not the missing warning)"
Write-Host "  - Uptime is short (freshly rebooted)"
Write-Host ""
Write-Host "Files written to $config" -ForegroundColor Green
Get-ChildItem $config | Select-Object Name, Length, LastWriteTimeUtc
