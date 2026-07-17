<#
    Step 7 - Increase Event Log capacity
    Testbed: TB-W11-25H2-01

    Purpose:
        Default Security log is 20 MB. Under Process Creation auditing
        it rolls over quickly. Rollover during a scenario destroys
        evidence. Enlarge Security, System, Application, and enable
        DriverFrameworks-UserMode for USB event capture.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\07-event-log-capacity.ps1

    Output:
        C:\DISS_Config\USB-Event-Channels.txt
        C:\DISS_Config\Security-Log-Config.xml
        C:\DISS_Config\System-Log-Config.xml
        C:\DISS_Config\Application-Log-Config.xml
        C:\DISS_Config\DriverFrameworks-Log-Config.xml
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'
New-Item -ItemType Directory -Path $config -Force | Out-Null

Write-Host "[Step 7] Enlarging Security (256 MB), System (128 MB), Application (128 MB)" -ForegroundColor Cyan
wevtutil sl Security    /ms:268435456
wevtutil sl System      /ms:134217728
wevtutil sl Application /ms:134217728

Write-Host "[Step 7] Inventorying USB-related channels" -ForegroundColor Cyan
wevtutil el |
    Select-String -Pattern "DriverFrameworks|Partition|Kernel-PnP|UserPnp|Storage" |
    Out-File (Join-Path $config 'USB-Event-Channels.txt') -Encoding utf8
Get-Content (Join-Path $config 'USB-Event-Channels.txt')

Write-Host "[Step 7] Enabling DriverFrameworks-UserMode/Operational at 32 MB" -ForegroundColor Cyan
$dfChannel = 'Microsoft-Windows-DriverFrameworks-UserMode/Operational'
try {
    wevtutil sl $dfChannel /e:true /ms:33554432
    Write-Host "  Enabled: $dfChannel"
} catch {
    Write-Warning "Could not enable $dfChannel - may not exist on this build."
}

Write-Host "[Step 7] Exporting final log configurations" -ForegroundColor Cyan
wevtutil gl Security    /f:xml > (Join-Path $config 'Security-Log-Config.xml')
wevtutil gl System      /f:xml > (Join-Path $config 'System-Log-Config.xml')
wevtutil gl Application /f:xml > (Join-Path $config 'Application-Log-Config.xml')
try {
    wevtutil gl $dfChannel /f:xml > (Join-Path $config 'DriverFrameworks-Log-Config.xml')
} catch {}

Write-Host ""
Write-Host "[Step 7] Complete. Do NOT clear the logs. Baseline restore provides fresh state." -ForegroundColor Green
Get-ChildItem $config | Select-Object Name, Length, LastWriteTimeUtc
