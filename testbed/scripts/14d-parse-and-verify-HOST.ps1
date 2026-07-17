<#
    Step 14d - Parse pilot artefacts and verify expected evidence (HOST)
    Testbed: TB-W11-25H2-01

    Purpose:
        Run PECmd, EvtxECmd and SBECmd against the artefacts extracted
        by 13-validate-offline-acquisition-HOST.ps1 from the post-pilot
        VM copy, then check for the expected pilot evidence:
            - Notepad Prefetch entry
            - Security event 4688 for Notepad
            - Security events 4800 (lock) and 4801 (unlock)
            - ShellBag entries for the BROWSED path
            - ShellBag entries for the UNBROWSED negative control (should NOT exist)

    Prerequisites:
        - EricZimmermanTools installed at $EzToolsRoot below. Install with:
            winget install EricZimmerman.PECmd
            winget install EricZimmerman.EvtxECmd
            winget install EricZimmerman.SBECmd
          Or download the toolchain from https://ericzimmerman.github.io/
        - 13-validate-offline-acquisition-HOST.ps1 has produced extracted
          artefacts under a folder like D:\UOW\SEM3\Backups\<pilot>-VALIDATION\.

    Run on HOST in admin PowerShell:
        powershell.exe -ExecutionPolicy Bypass -File .\14d-parse-and-verify-HOST.ps1 -RunId P00-R01 -SourceDir "D:\UOW\SEM3\Backups\P00-R01-VALIDATION"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$RunId,

    [Parameter(Mandatory=$true)]
    [string]$SourceDir,

    [string]$EzToolsRoot = 'C:\ForensicTools',

    [string]$GuestUser = 'dfanalyst'
)

$ErrorActionPreference = 'Stop'

$pecmd     = Join-Path $EzToolsRoot 'PECmd\PECmd.exe'
$evtxecmd  = Join-Path $EzToolsRoot 'EvtxECmd\EvtxECmd.exe'
$sbecmd    = Join-Path $EzToolsRoot 'SBECmd\SBECmd.exe'

foreach ($t in @($pecmd,$evtxecmd,$sbecmd)) {
    if (-not (Test-Path $t)) { throw "Missing tool: $t. Install EricZimmermanTools and set -EzToolsRoot." }
}

$out = Join-Path $SourceDir 'parsed'
New-Item -ItemType Directory -Path $out -Force | Out-Null

$prefDir  = Join-Path $SourceDir 'Windows\Prefetch'
$evtxDir  = Join-Path $SourceDir 'Windows\System32\winevt\Logs'
$hivesDir = Join-Path $SourceDir "Users\$GuestUser"

Write-Host "[$RunId] Parsing Prefetch" -ForegroundColor Cyan
& $pecmd -d $prefDir --csv $out --csvf "$RunId-prefetch.csv" | Out-Host

Write-Host "[$RunId] Parsing Event Logs (Security, System, DriverFrameworks)" -ForegroundColor Cyan
foreach ($log in @('Security.evtx','System.evtx','Microsoft-Windows-DriverFrameworks-UserMode%4Operational.evtx')) {
    $path = Join-Path $evtxDir $log
    if (Test-Path $path) {
        & $evtxecmd -f $path --csv $out --csvf "$RunId-$($log -replace '\.evtx$').csv" | Out-Host
    }
}

Write-Host "[$RunId] Parsing ShellBags" -ForegroundColor Cyan
& $sbecmd -d $hivesDir --csv $out --nl | Out-Host

Write-Host ""
Write-Host "[$RunId] Verification checks:" -ForegroundColor Green

# Prefetch: expect NOTEPAD.EXE-*.pf
$prefCsv = Get-ChildItem $out -Filter "$RunId-prefetch.csv" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($prefCsv) {
    $rows = Import-Csv $prefCsv.FullName
    $notepad = $rows | Where-Object { $_.ExecutableName -match 'NOTEPAD' -or $_.SourceFilename -match 'NOTEPAD' }
    Write-Host ("  Notepad Prefetch entry     : {0}" -f $(if ($notepad) { 'FOUND' } else { 'MISSING' }))
}

# Event 4688 for Notepad
$secCsv = Get-ChildItem $out -Filter "$RunId-Security.csv" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($secCsv) {
    $sec = Import-Csv $secCsv.FullName
    $notepad4688 = $sec | Where-Object { $_.EventId -eq '4688' -and $_.Payload -match 'notepad\.exe' }
    Write-Host ("  Security 4688 for Notepad  : {0}" -f $(if ($notepad4688) { 'FOUND' } else { 'MISSING' }))
    $lock  = $sec | Where-Object { $_.EventId -eq '4800' }
    $unlock= $sec | Where-Object { $_.EventId -eq '4801' }
    Write-Host ("  Security 4800 (lock)       : {0}" -f $(if ($lock)   { 'FOUND' } else { 'MISSING' }))
    Write-Host ("  Security 4801 (unlock)     : {0}" -f $(if ($unlock) { 'FOUND' } else { 'MISSING' }))
}

# ShellBag entries
$sbCsvs = Get-ChildItem $out -Filter "*ShellBags*.csv" -ErrorAction SilentlyContinue
if ($sbCsvs) {
    $sb = $sbCsvs | ForEach-Object { Import-Csv $_.FullName }
    $browsed   = $sb | Where-Object { $_.AbsolutePath -match 'A7K9' }
    $unbrowsed = $sb | Where-Object { $_.AbsolutePath -match 'Q4M2' }
    Write-Host ("  ShellBag BROWSED (A7K9)    : {0}" -f $(if ($browsed)   { 'FOUND (expected)' }   else { 'MISSING (unexpected)' }))
    Write-Host ("  ShellBag UNBROWSED (Q4M2)  : {0}" -f $(if ($unbrowsed) { 'FOUND (LEAK)' }        else { 'NOT PRESENT (expected)' }))
}

Write-Host ""
Write-Host "Parsed CSVs written to: $out"
Write-Host "Store this whole folder under D:\UOW\SEM3\DISS_Config\pilots\$RunId\parsed for provenance."
