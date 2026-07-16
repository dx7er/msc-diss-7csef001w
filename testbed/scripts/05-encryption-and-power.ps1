<#
    Step 5 - Check encryption and power behaviour
    Testbed: TB-W11-25H2-01

    Purpose:
        1. Confirm BitLocker is OFF on C:. Encryption blocks offline VMDK
           mount from the host, so it must be off for Step 13 acquisition.
        2. Disable hibernation and Fast Startup so every experimental
           shutdown is a full flush. Partial shutdowns leave dirty
           registry hives and skew event log continuity.

    IMPORTANT:
        - Do NOT remove the virtual TPM in VMware. It must remain PRESENT.
          It is unused (BitLocker off) but its removal changes hardware
          identity mid-study, which invalidates the testbed specification.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\05-encryption-and-power.ps1

    Output (guest paths, copied later to repo):
        C:\DISS_Config\BitLocker-Status.txt
        C:\DISS_Config\Power-Config.txt
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'

Write-Host "[Step 5] Ensuring $config exists" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $config -Force | Out-Null

Write-Host "[Step 5] Checking BitLocker status on C:" -ForegroundColor Cyan
manage-bde -status C: 2>&1 |
    Tee-Object -FilePath (Join-Path $config 'BitLocker-Status.txt')

Write-Host ""
Write-Host "[Step 5] IF Conversion Status shows anything other than 'Fully Decrypted'," -ForegroundColor Yellow
Write-Host "         run this manually AFTER the script and WAIT until fully decrypted:" -ForegroundColor Yellow
Write-Host "             manage-bde -off C:" -ForegroundColor Yellow
Write-Host "             manage-bde -status C:   # poll until 'Fully Decrypted'" -ForegroundColor Yellow
Write-Host "         Then re-run this script to update BitLocker-Status.txt." -ForegroundColor Yellow
Write-Host ""

Write-Host "[Step 5] Disabling hibernation (removes hiberfil.sys and Fast Startup)" -ForegroundColor Cyan
powercfg.exe /hibernate off

Write-Host "[Step 5] Setting AC standby timeout to Never (0)" -ForegroundColor Cyan
powercfg.exe /change standby-timeout-ac 0

Write-Host "[Step 5] Recording active power scheme and sleep settings" -ForegroundColor Cyan
$powerOut = Join-Path $config 'Power-Config.txt'

"=== Active power scheme ===" | Out-File $powerOut -Encoding utf8
powercfg.exe /getactivescheme | Out-File $powerOut -Append -Encoding utf8

""                              | Out-File $powerOut -Append -Encoding utf8
"=== Hibernation ==="           | Out-File $powerOut -Append -Encoding utf8
$hiberfil = Test-Path 'C:\hiberfil.sys'
"hiberfil.sys present : $hiberfil" | Out-File $powerOut -Append -Encoding utf8

""                              | Out-File $powerOut -Append -Encoding utf8
"=== Sleep subgroup (SCHEME_CURRENT SUB_SLEEP) ===" | Out-File $powerOut -Append -Encoding utf8
powercfg.exe /query SCHEME_CURRENT SUB_SLEEP | Out-File $powerOut -Append -Encoding utf8

Get-Content $powerOut

Write-Host ""
Write-Host "[Step 5] Complete. Verify:" -ForegroundColor Green
Write-Host "  - BitLocker-Status.txt: 'Conversion Status: Fully Decrypted' and 'Protection Status: Protection Off'"
Write-Host "  - Power-Config.txt: 'hiberfil.sys present : False'"
Write-Host "  - Standby timeout on AC = 0 (never sleep)"
Write-Host ""
Write-Host "Files written to $config" -ForegroundColor Green
Get-ChildItem $config | Select-Object Name, Length, LastWriteTimeUtc
