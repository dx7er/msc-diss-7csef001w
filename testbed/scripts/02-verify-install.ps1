<#
    Step 2 - Verify Windows installation matches proposal
    Testbed: TB-W11-25H2-01

    Purpose:
        Confirm EditionID = Professional, DisplayVersion = 25H2, and capture
        CurrentBuild/UBR exactly. Record the primary account SID (per-user
        forensic artefacts are indexed by SID). Establish C:\DISS_Config as
        the guest-side config output directory used by all later steps.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\02-verify-install.ps1

    Output (guest paths, copied later to repo):
        C:\DISS_Config\Windows-Version.txt
        C:\DISS_Config\Whoami.txt
        C:\DISS_Config\Whoami-User.txt
        C:\DISS_Config\Local-Users.txt
#>

$ErrorActionPreference = 'Stop'
$config = 'C:\DISS_Config'

Write-Host "[Step 2] Creating $config" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $config -Force | Out-Null

Write-Host "[Step 2] Capturing Windows edition, version, build, UBR" -ForegroundColor Cyan
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
    Select-Object ProductName, EditionID, DisplayVersion, CurrentBuild, UBR |
    Format-List |
    Out-File (Join-Path $config 'Windows-Version.txt') -Encoding utf8

Get-Content (Join-Path $config 'Windows-Version.txt')

Write-Host "[Step 2] Capturing current user identity and SID" -ForegroundColor Cyan
whoami                | Out-File (Join-Path $config 'Whoami.txt')       -Encoding utf8
whoami /user /fo list | Out-File (Join-Path $config 'Whoami-User.txt')  -Encoding utf8

Write-Host "[Step 2] Enumerating local user accounts" -ForegroundColor Cyan
Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordExpires |
    Format-Table -AutoSize |
    Out-File (Join-Path $config 'Local-Users.txt') -Encoding utf8

Write-Host ""
Write-Host "[Step 2] Complete. Verify the following before continuing to Step 3:" -ForegroundColor Green
Write-Host "  - EditionID       = Professional"
Write-Host "  - DisplayVersion  = 25H2"
Write-Host "  - CurrentBuild and UBR recorded"
Write-Host "  - Primary account SID captured in Whoami-User.txt"
Write-Host ""
Write-Host "Files written to $config" -ForegroundColor Green
Get-ChildItem $config | Select-Object Name, Length, LastWriteTimeUtc
