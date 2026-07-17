<#
    Step 8 - Check Prefetch readiness
    Testbed: TB-W11-25H2-01

    Purpose:
        Confirm Prefetch is enabled and SysMain is running. Windows 11
        sometimes disables Prefetch on SSDs. If it's off we cannot proceed
        as scoped. Do NOT delete any .pf files. Do NOT modify the registry
        blindly if the value is missing or unexpected - the pilot proves
        whether Prefetch is actually being generated.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\08-prefetch-readiness.ps1

    Output:
        C:\DISS_Config\Prefetch-Config.txt
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'
New-Item -ItemType Directory -Path $config -Force | Out-Null
$out = Join-Path $config 'Prefetch-Config.txt'

"=== PrefetchParameters registry ==="  | Out-File $out -Encoding utf8
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' |
    Select-Object EnablePrefetcher, EnableSuperfetch |
    Format-List |
    Out-File $out -Append -Encoding utf8

"=== SysMain service ==="              | Out-File $out -Append -Encoding utf8
Get-Service SysMain |
    Select-Object Name, Status, StartType |
    Format-List |
    Out-File $out -Append -Encoding utf8

"=== Physical disks ==="               | Out-File $out -Append -Encoding utf8
Get-PhysicalDisk |
    Select-Object FriendlyName, MediaType, BusType, Size |
    Format-Table -AutoSize |
    Out-File $out -Append -Encoding utf8

"=== Prefetch directory contents (top 15 by write time) ===" | Out-File $out -Append -Encoding utf8
Get-ChildItem 'C:\Windows\Prefetch' -Filter *.pf -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 15 Name, Length, LastWriteTimeUtc |
    Format-Table -AutoSize |
    Out-File $out -Append -Encoding utf8

Get-Content $out

Write-Host ""
Write-Host "[Step 8] Expected results:" -ForegroundColor Green
Write-Host "  EnablePrefetcher = 3 (or 2)"
Write-Host "  SysMain: Status Running, StartType Automatic"
Write-Host "  Prefetch directory contains .pf files (not empty)"
Write-Host ""
Write-Host "If EnablePrefetcher is 0 or SysMain is Stopped, STOP. Do not fix here." -ForegroundColor Yellow
Write-Host "Escalate to Jade before proceeding. Prefetch may need to be re-enabled" -ForegroundColor Yellow
Write-Host "manually or the study scope narrowed to Event Logs and ShellBags only." -ForegroundColor Yellow
