<#
    Step 14b - Pilot post-run capture (GUEST)
    Testbed: TB-W11-25H2-01

    Purpose:
        Record end-of-scenario state so we know what was added or changed
        between pre-run and post-run. Do NOT shut down until this
        script has finished writing outputs.

    When to run:
        Immediately after finishing the pilot actions, BEFORE shutdown.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\14b-pilot-post-run.ps1 -RunId P00-R01

    Output (in C:\DISS_PILOT\<RunId>\):
        post-run-state.txt
        post-prefetch-inventory.txt
        prefetch-diff-added-or-updated.txt
        post-security-events-since-t0.txt
        environment-summary.txt
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^P\d{2}-R\d{2}$')]
    [string]$RunId
)

$ErrorActionPreference = 'Continue'
$pilotRoot = "C:\DISS_PILOT\$RunId"
if (-not (Test-Path $pilotRoot)) {
    throw "Pre-run directory not found: $pilotRoot. Did you run 14a-pilot-pre-run.ps1 first?"
}

# Read T0 back
$t0Line = Get-Content (Join-Path $pilotRoot 'pre-run-state.txt') | Select-String 'T0 \(UTC\)\s+:\s+(.+)'
$t0 = [DateTime]::Parse($t0Line.Matches[0].Groups[1].Value).ToUniversalTime()
$tEnd = [DateTime]::UtcNow

Write-Host "[Pilot $RunId] T0 : $($t0.ToString('o'))" -ForegroundColor Cyan
Write-Host "[Pilot $RunId] Tend: $($tEnd.ToString('o'))" -ForegroundColor Cyan
Write-Host "[Pilot $RunId] Elapsed minutes: $([math]::Round(($tEnd - $t0).TotalMinutes, 1))" -ForegroundColor Cyan

$state = Join-Path $pilotRoot 'post-run-state.txt'
"=== Pilot post-run state ==="                        | Out-File $state -Encoding utf8
"RunId              : $RunId"                         | Out-File $state -Append -Encoding utf8
"T0 (UTC)           : $($t0.ToString('o'))"           | Out-File $state -Append -Encoding utf8
"Tend (UTC)         : $($tEnd.ToString('o'))"         | Out-File $state -Append -Encoding utf8
"Elapsed (minutes)  : $([math]::Round(($tEnd - $t0).TotalMinutes, 1))" | Out-File $state -Append -Encoding utf8

Write-Host "[Pilot $RunId] Capturing post-Prefetch inventory" -ForegroundColor Cyan
Get-ChildItem 'C:\Windows\Prefetch' -Filter *.pf -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object Name, Length, LastWriteTimeUtc |
    Format-Table -AutoSize |
    Out-File (Join-Path $pilotRoot 'post-prefetch-inventory.txt') -Encoding utf8

Write-Host "[Pilot $RunId] Computing Prefetch delta (added or modified during pilot)" -ForegroundColor Cyan
$pf = Get-ChildItem 'C:\Windows\Prefetch' -Filter *.pf -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTimeUtc -ge $t0 }
$pf | Sort-Object LastWriteTimeUtc |
    Select-Object Name, Length, LastWriteTimeUtc |
    Format-Table -AutoSize |
    Out-File (Join-Path $pilotRoot 'prefetch-diff-added-or-updated.txt') -Encoding utf8

Write-Host "[Pilot $RunId] Capturing Security events since T0" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{ LogName='Security'; StartTime=$t0 } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, @{n='MessageShort';e={$_.Message -split "`n" | Select-Object -First 1}} |
    Format-Table -AutoSize -Wrap |
    Out-File (Join-Path $pilotRoot 'post-security-events-since-t0.txt') -Encoding utf8

Write-Host "[Pilot $RunId] Environment summary" -ForegroundColor Cyan
$env = Join-Path $pilotRoot 'environment-summary.txt'
"=== Environment summary ==="                                       | Out-File $env -Encoding utf8
"OS build           : $((Get-CimInstance Win32_OperatingSystem).Version)" | Out-File $env -Append -Encoding utf8
"Timezone Id        : $((Get-TimeZone).Id)"                         | Out-File $env -Append -Encoding utf8
"Free disk C: (GB)  : $([math]::Round((Get-PSDrive C).Free / 1GB, 2))" | Out-File $env -Append -Encoding utf8
"Post capture UTC   : $($tEnd.ToString('o'))"                       | Out-File $env -Append -Encoding utf8

Write-Host ""
Write-Host "[Pilot $RunId] Post-run capture complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "  1. Copy C:\DISS_PILOT\$RunId to host D:\UOW\SEM3\DISS_Config\pilots\$RunId"
Write-Host "  2. Shut Windows down normally."
Write-Host "  3. On host, use 13-validate-offline-acquisition-HOST.ps1 to extract"
Write-Host "     Prefetch/EVTX/registry from a copy of the VM's post-run state."
Write-Host "  4. Do NOT boot the VM again for this run. Revert to B00-CANDIDATE for R02."
