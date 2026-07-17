<#
    Step 11 - Capture baseline systeminfo BEFORE the candidate snapshot
    Testbed: TB-W11-25H2-01

    Purpose:
        Record the exact state of the guest (systeminfo, running services,
        installed programs, .pf inventory, event log latest records) just
        before the candidate snapshot is taken. This is your evidence that
        the state described in the report matches what's in the snapshot.

    Prerequisites (do these manually BEFORE running this script):
        1. Step 10 (guest) done - VMware timesync disabled.
        2. Step 10 (host) done - VMware Workstation isolation applied.
        3. Windows.old removed from C:\ (if not already).
        4. VM restarted twice.
        5. Network adapter Disconnected.
        6. Waited approximately 10 minutes for background activity to settle.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\11-candidate-baseline-capture.ps1

        Then shut Windows down normally (do NOT reboot).
        Then in VMware Workstation, take a powered-off snapshot named:
            B00-CANDIDATE-W11-25H2-26200.6584-20260717

    Output:
        C:\DISS_Config\systeminfo.txt
        C:\DISS_Config\running-services.txt
        C:\DISS_Config\installed-programs.txt
        C:\DISS_Config\prefetch-baseline-inventory.txt
        C:\DISS_Config\latest-security-events.txt
        C:\DISS_Config\baseline-summary.txt
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'
New-Item -ItemType Directory -Path $config -Force | Out-Null

Write-Host "[Step 11] Capturing systeminfo" -ForegroundColor Cyan
systeminfo > (Join-Path $config 'systeminfo.txt')

Write-Host "[Step 11] Recording running services" -ForegroundColor Cyan
Get-Service |
    Where-Object { $_.Status -eq 'Running' } |
    Sort-Object Name |
    Select-Object Name, DisplayName, StartType |
    Format-Table -AutoSize |
    Out-File (Join-Path $config 'running-services.txt') -Encoding utf8

Write-Host "[Step 11] Recording installed programs (registry-based)" -ForegroundColor Cyan
$uninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty -Path $uninstallPaths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Sort-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Format-Table -AutoSize |
    Out-File (Join-Path $config 'installed-programs.txt') -Encoding utf8

Write-Host "[Step 11] Inventorying Prefetch (.pf) files" -ForegroundColor Cyan
Get-ChildItem 'C:\Windows\Prefetch' -Filter *.pf -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object Name, Length, LastWriteTimeUtc |
    Format-Table -AutoSize |
    Out-File (Join-Path $config 'prefetch-baseline-inventory.txt') -Encoding utf8

Write-Host "[Step 11] Capturing latest 50 Security event log records" -ForegroundColor Cyan
Get-WinEvent -LogName Security -MaxEvents 50 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
    Format-Table -AutoSize -Wrap |
    Out-File (Join-Path $config 'latest-security-events.txt') -Encoding utf8

Write-Host "[Step 11] Writing baseline summary" -ForegroundColor Cyan
$summary = Join-Path $config 'baseline-summary.txt'
"=== Baseline capture summary ==="                         | Out-File $summary -Encoding utf8
"Captured UTC        : $([DateTime]::UtcNow.ToString('o'))" | Out-File $summary -Append -Encoding utf8
"Computer name       : $env:COMPUTERNAME"                   | Out-File $summary -Append -Encoding utf8
"User (running)      : $env:USERNAME"                       | Out-File $summary -Append -Encoding utf8
"OS build            : $((Get-CimInstance Win32_OperatingSystem).Version)" | Out-File $summary -Append -Encoding utf8
"Last boot UTC       : $((Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString('o'))" | Out-File $summary -Append -Encoding utf8
"Uptime (minutes)    : $([math]::Round((New-TimeSpan -Start ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime) -End (Get-Date)).TotalMinutes, 1))" | Out-File $summary -Append -Encoding utf8
"C: free (GB)        : $([math]::Round((Get-PSDrive C).Free / 1GB, 2))" | Out-File $summary -Append -Encoding utf8
Get-Content $summary

Write-Host ""
Write-Host "[Step 11] Complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps (MANUAL):" -ForegroundColor Yellow
Write-Host "  1. Copy the full C:\DISS_Config directory to host D:\UOW\SEM3\DISS_Config\ NOW."
Write-Host "  2. Shut Windows down normally: Start > Power > Shut down."
Write-Host "  3. In VMware Workstation, VM > Snapshot > Take Snapshot with name:"
Write-Host "     B00-CANDIDATE-W11-25H2-26200.6584-20260717"
Write-Host "  4. In snapshot description, include: Windows 26200.6584, VMware Tools 12.4.5,"
Write-Host "     4 vCPU / 7 GB RAM / 80 GB, UTC, audit on, WU disabled, host-only network,"
Write-Host "     BitLocker off."
