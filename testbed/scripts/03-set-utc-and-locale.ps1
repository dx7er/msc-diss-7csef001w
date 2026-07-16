<#
    Step 3 - Set UTC timezone and capture locale
    Testbed: TB-W11-25H2-01

    Purpose:
        Force the guest to UTC so every parsed forensic timestamp is
        unambiguous. Capture the system locale, user language list and
        culture for the methodology chapter.

    Note:
        The computer rename step from the master checklist is SKIPPED.
        The computer name was set to 'disstestbedvm' during OOBE (Step 1)
        and is being retained.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\03-set-utc-and-locale.ps1

    Output (guest paths, copied later to repo):
        C:\DISS_Config\Timezone-Before.txt
        C:\DISS_Config\Timezone-After.txt
        C:\DISS_Config\Locale.txt
        C:\DISS_Config\Language-List.txt
        C:\DISS_Config\Culture.txt
#>

$ErrorActionPreference = 'Stop'
$config = 'C:\DISS_Config'

Write-Host "[Step 3] Ensuring $config exists" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $config -Force | Out-Null

Write-Host "[Step 3] Recording current timezone (before change)" -ForegroundColor Cyan
Get-TimeZone | Format-List | Out-File (Join-Path $config 'Timezone-Before.txt') -Encoding utf8
Get-Content (Join-Path $config 'Timezone-Before.txt')

Write-Host "[Step 3] Setting timezone to UTC" -ForegroundColor Cyan
Set-TimeZone -Id "UTC"

Write-Host "[Step 3] Recording current timezone (after change)" -ForegroundColor Cyan
Get-TimeZone | Format-List | Out-File (Join-Path $config 'Timezone-After.txt') -Encoding utf8
Get-Content (Join-Path $config 'Timezone-After.txt')

Write-Host "[Step 3] Current UTC time (ISO 8601)" -ForegroundColor Cyan
$utcNow = [DateTime]::UtcNow.ToString("o")
Write-Host "  $utcNow"
$utcNow | Out-File (Join-Path $config 'Timezone-After.txt') -Append -Encoding utf8

Write-Host "[Step 3] Capturing system locale" -ForegroundColor Cyan
Get-WinSystemLocale | Format-List |
    Out-File (Join-Path $config 'Locale.txt') -Encoding utf8

Write-Host "[Step 3] Capturing user language list" -ForegroundColor Cyan
Get-WinUserLanguageList |
    Out-File (Join-Path $config 'Language-List.txt') -Encoding utf8

Write-Host "[Step 3] Capturing culture" -ForegroundColor Cyan
Get-Culture | Format-List |
    Out-File (Join-Path $config 'Culture.txt') -Encoding utf8

Write-Host ""
Write-Host "[Step 3] Complete. Verify:" -ForegroundColor Green
Write-Host "  - Timezone Id     = UTC"
Write-Host "  - BaseUtcOffset   = 00:00:00"
Write-Host "  - UTC time above matches your host UTC time"
Write-Host ""
Write-Host "Files written to $config" -ForegroundColor Green
Get-ChildItem $config | Select-Object Name, Length, LastWriteTimeUtc
