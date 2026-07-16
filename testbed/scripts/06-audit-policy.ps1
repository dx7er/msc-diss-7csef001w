<#
    Step 6 - Configure audit policy
    Testbed: TB-W11-25H2-01

    Purpose:
        Enable Windows audit subcategories required for correlation with
        Prefetch, ShellBags and USB activity. Enable process-command-line
        recording so Security event 4688 contains the full invocation.

    Approach:
        Codex Step 6 uses secpol.msc and gpedit.msc UI. Both settings are
        registry-backed and can be applied without UI, giving an equivalent,
        scriptable and defensible result.

    Registry-backed policies applied:
        HKLM\SYSTEM\CurrentControlSet\Control\Lsa
            SCENoApplyLegacyAuditPolicy = 1
              (equivalent to Local Policies > Security Options >
               "Audit: Force audit policy subcategory settings ..." = Enabled)

        HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit
            ProcessCreationIncludeCmdLine_Enabled = 1
              (equivalent to Computer Configuration > Administrative
               Templates > System > Audit Process Creation >
               "Include command line in process creation events" = Enabled)

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\06-audit-policy.ps1

    Output (guest paths, copied later to repo):
        C:\DISS_Config\audit-before.csv
        C:\DISS_Config\audit-subcategories.txt
        C:\DISS_Config\audit-after.csv
        C:\DISS_Config\audit-policy-backup.csv
        C:\DISS_Config\audit-registry.txt
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'

Write-Host "[Step 6] Ensuring $config exists" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $config -Force | Out-Null

$beforeCsv    = Join-Path $config 'audit-before.csv'
$subcatTxt    = Join-Path $config 'audit-subcategories.txt'
$afterCsv     = Join-Path $config 'audit-after.csv'
$backupCsv    = Join-Path $config 'audit-policy-backup.csv'
$registryTxt  = Join-Path $config 'audit-registry.txt'

Write-Host "[Step 6] Capturing baseline audit policy (before changes)" -ForegroundColor Cyan
auditpol /get /category:* /r         > $beforeCsv
auditpol /list /subcategory:*        > $subcatTxt

Write-Host "[Step 6] Ensuring SCENoApplyLegacyAuditPolicy = 1 (subcategory override)" -ForegroundColor Cyan
$lsaPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
Set-ItemProperty -Path $lsaPath -Name 'SCENoApplyLegacyAuditPolicy' -Value 1 -Type DWord

Write-Host "[Step 6] Enabling audit subcategories" -ForegroundColor Cyan
auditpol /set /subcategory:"Process Creation"          /success:enable
auditpol /set /subcategory:"Process Termination"       /success:enable
auditpol /set /subcategory:"Logon"                     /success:enable /failure:enable
auditpol /set /subcategory:"Logoff"                    /success:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable
auditpol /set /subcategory:"Plug and Play Events"      /success:enable
auditpol /set /subcategory:"Removable Storage"         /success:enable /failure:enable

Write-Host "[Step 6] Enabling 'Include command line in process creation events'" -ForegroundColor Cyan
$auditGpPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit'
if (-not (Test-Path $auditGpPath)) {
    New-Item -Path $auditGpPath -Force | Out-Null
}
Set-ItemProperty -Path $auditGpPath -Name 'ProcessCreationIncludeCmdLine_Enabled' -Value 1 -Type DWord

Write-Host "[Step 6] Capturing final audit policy (after changes)" -ForegroundColor Cyan
auditpol /get /category:* /r > $afterCsv
auditpol /backup /file:$backupCsv

Write-Host "[Step 6] Recording relevant registry state" -ForegroundColor Cyan
"=== HKLM\SYSTEM\CurrentControlSet\Control\Lsa ===" | Out-File $registryTxt -Encoding utf8
Get-ItemProperty -Path $lsaPath -Name SCENoApplyLegacyAuditPolicy |
    Select-Object SCENoApplyLegacyAuditPolicy |
    Format-List |
    Out-File $registryTxt -Append -Encoding utf8

"" | Out-File $registryTxt -Append -Encoding utf8
"=== HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit ===" | Out-File $registryTxt -Append -Encoding utf8
Get-ItemProperty -Path $auditGpPath -Name ProcessCreationIncludeCmdLine_Enabled |
    Select-Object ProcessCreationIncludeCmdLine_Enabled |
    Format-List |
    Out-File $registryTxt -Append -Encoding utf8

Write-Host ""
Write-Host "[Step 6] Verification (running 'auditpol /get' on relevant subcategories):" -ForegroundColor Green
auditpol /get /subcategory:"Process Creation","Process Termination","Logon","Logoff","Other Logon/Logoff Events","Plug and Play Events","Removable Storage"

Write-Host ""
Write-Host "[Step 6] Expected results:" -ForegroundColor Green
Write-Host "  Process Creation           = Success"
Write-Host "  Process Termination        = Success"
Write-Host "  Logon                      = Success and Failure"
Write-Host "  Logoff                     = Success"
Write-Host "  Other Logon/Logoff Events  = Success"
Write-Host "  Plug and Play Events       = Success"
Write-Host "  Removable Storage          = Success and Failure"
Write-Host ""
Write-Host "Files written to $config" -ForegroundColor Green
Get-ChildItem $config | Select-Object Name, Length, LastWriteTimeUtc
