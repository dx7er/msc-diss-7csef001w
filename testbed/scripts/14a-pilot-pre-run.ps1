<#
    Step 14a - Pilot pre-run capture (GUEST)
    Testbed: TB-W11-25H2-01

    Purpose:
        Record baseline state and record T0 for a pilot repetition, so that
        after the scenario is executed the post-run state can be diffed
        against this.

    When to run:
        First thing after the VM boots from the restored B00-CANDIDATE
        snapshot, and BEFORE performing any scenario action.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\14a-pilot-pre-run.ps1 -RunId P00-R01

    Output:
        C:\DISS_PILOT\<RunId>\pre-run-state.txt
        C:\DISS_PILOT\<RunId>\pre-prefetch-inventory.txt
        C:\DISS_PILOT\<RunId>\pre-security-events-last50.txt
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^P\d{2}-R\d{2}$')]
    [string]$RunId
)

$ErrorActionPreference = 'Continue'
$pilotRoot = "C:\DISS_PILOT\$RunId"
New-Item -ItemType Directory -Path $pilotRoot -Force | Out-Null

$t0Utc = [DateTime]::UtcNow.ToString("o")

Write-Host "[Pilot $RunId] T0 (UTC) = $t0Utc" -ForegroundColor Cyan

$state = Join-Path $pilotRoot 'pre-run-state.txt'
"=== Pilot pre-run state ==="                                            | Out-File $state -Encoding utf8
"RunId              : $RunId"                                            | Out-File $state -Append -Encoding utf8
"T0 (UTC)           : $t0Utc"                                            | Out-File $state -Append -Encoding utf8
"Computer name      : $env:COMPUTERNAME"                                 | Out-File $state -Append -Encoding utf8
"User               : $env:USERNAME"                                     | Out-File $state -Append -Encoding utf8
"Last boot UTC      : $((Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToUniversalTime().ToString('o'))" | Out-File $state -Append -Encoding utf8
"Uptime minutes     : $([math]::Round((New-TimeSpan -Start ((Get-CimInstance Win32_OperatingSystem).LastBootUpTime) -End (Get-Date)).TotalMinutes, 1))" | Out-File $state -Append -Encoding utf8
"Timezone Id        : $((Get-TimeZone).Id)"                              | Out-File $state -Append -Encoding utf8

Write-Host "[Pilot $RunId] Capturing Prefetch inventory" -ForegroundColor Cyan
Get-ChildItem 'C:\Windows\Prefetch' -Filter *.pf -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object Name, Length, LastWriteTimeUtc |
    Format-Table -AutoSize |
    Out-File (Join-Path $pilotRoot 'pre-prefetch-inventory.txt') -Encoding utf8

Write-Host "[Pilot $RunId] Capturing last 50 Security events" -ForegroundColor Cyan
Get-WinEvent -LogName Security -MaxEvents 50 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
    Format-Table -AutoSize -Wrap |
    Out-File (Join-Path $pilotRoot 'pre-security-events-last50.txt') -Encoding utf8

Write-Host ""
Write-Host "[Pilot $RunId] Pre-run capture complete." -ForegroundColor Green
Write-Host ""
Write-Host "Now perform the pilot scenario:" -ForegroundColor Yellow
Write-Host "  1. Open Notepad. Close it. Open Notepad. Close it."
Write-Host "  2. Open File Explorer. Browse:"
Write-Host "     C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9\ALPHA\BRAVO\CHARLIE"
Write-Host "     Wait 15-30 seconds at each level. Do NOT navigate elsewhere."
Write-Host "  3. NEVER open C:\DISS_TESTDATA\PILOT\P00R01_UNBROWSED_Q4M2 (negative control)."
Write-Host "  4. Press Win+L. Wait 30 seconds. Unlock."
Write-Host "  5. Optional: connect controlled USB, browse it, copy 1 file, safe-eject."
Write-Host "  6. Close Explorer. Wait 60-120 seconds."
Write-Host "  7. Fill in ground-truth log with actions and UTC timestamps as you go."
Write-Host "  8. When done, run: 14b-pilot-post-run.ps1 -RunId $RunId"
