<#
.SYNOPSIS
    Parses forensic artefacts for one scenario (or one run of a multi-run scenario)
    using Eric Zimmerman's CLI tools.

.DESCRIPTION
    Runs three parsers against the raw evidence collected in Phase 3:

        PECmd     against artefacts/prefetch/    -> prefetch CSV + timeline CSV
        EvtxECmd  against artefacts/event_logs/  -> combined events CSV
        SBECmd    against artefacts/shellbags/   -> shellbags CSV

    Outputs land in a fresh analysis/ folder inside artefacts/, mirroring the
    three artefact classes as subfolders. The raw evidence is never touched;
    only parsed CSVs are written.

    Scenario layout auto-detected:
      Single-run: scenarios/scenario_N/artefacts/...
      Multi-run : scenarios/scenario_N/run_M/artefacts/...

.PARAMETER Scenario
    Scenario number, 1 to 10. Required.

.PARAMETER Run
    Run number, 1 to 3. Required for multi-run scenarios (S04, S07);
    omit for single-run scenarios.

.EXAMPLE
    .\extract_artefacts.ps1 -Scenario 1
    Extracts single-run Scenario 1.

.EXAMPLE
    .\extract_artefacts.ps1 -Scenario 4 -Run 2
    Extracts Run 2 of multi-run Scenario 4.

.NOTES
    Zimmerman tools expected at D:\UOW\SEM3\Tools\ZimmermanTools\net9\
    Written for Phase 4 of the MSc dissertation (2026-08-23).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [int]$Scenario,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3)]
    [int]$Run
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Locate Zimmerman tools on the host
# ---------------------------------------------------------------------------
$ToolsRoot = 'D:\UOW\SEM3\Tools\ZimmermanTools\net9'
$PECmd     = Join-Path $ToolsRoot 'PECmd.exe'
$EvtxECmd  = Join-Path $ToolsRoot 'EvtxECmd\EvtxECmd.exe'
$SBECmd    = Join-Path $ToolsRoot 'SBECmd.exe'

foreach ($tool in @($PECmd, $EvtxECmd, $SBECmd)) {
    if (-not (Test-Path $tool)) {
        throw "Zimmerman tool not found: $tool. Re-run Get-ZimmermanTools.ps1 or fix the path at the top of this script."
    }
}

# ---------------------------------------------------------------------------
# 2. Resolve repository root and scenario paths
# ---------------------------------------------------------------------------
$RepoRoot     = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ScenarioRoot = Join-Path $RepoRoot ("scenarios\scenario_{0}" -f $Scenario)

if (-not (Test-Path $ScenarioRoot)) {
    throw "Scenario folder not found: $ScenarioRoot"
}

if ($PSBoundParameters.ContainsKey('Run')) {
    $WorkRoot = Join-Path $ScenarioRoot ("run_{0}" -f $Run)
    $Label    = "Scenario $Scenario Run $Run"
}
else {
    $WorkRoot = $ScenarioRoot
    $Label    = "Scenario $Scenario"
}

$ArtefactsRoot = Join-Path $WorkRoot 'artefacts'
if (-not (Test-Path $ArtefactsRoot)) {
    throw "Artefacts folder not found under $WorkRoot. If this is a multi-run scenario, pass -Run."
}

$AnalysisRoot = Join-Path $ArtefactsRoot 'analysis'

# ---------------------------------------------------------------------------
# 3. Prepare a fresh analysis/ tree
# ---------------------------------------------------------------------------
if (Test-Path $AnalysisRoot) {
    Write-Host "Cleaning existing analysis folder: $AnalysisRoot" -ForegroundColor Yellow
    Remove-Item -LiteralPath $AnalysisRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $AnalysisRoot | Out-Null

$PrefetchOut  = Join-Path $AnalysisRoot 'prefetch'
$EventLogsOut = Join-Path $AnalysisRoot 'event_logs'
$ShellBagsOut = Join-Path $AnalysisRoot 'shellbags'

foreach ($d in @($PrefetchOut, $EventLogsOut, $ShellBagsOut)) {
    New-Item -ItemType Directory -Path $d | Out-Null
}

$PrefetchDir  = Join-Path $ArtefactsRoot 'prefetch'
$EventLogsDir = Join-Path $ArtefactsRoot 'event_logs'
$ShellBagsDir = Join-Path $ArtefactsRoot 'shellbags'

# ---------------------------------------------------------------------------
# 4. Run the parsers
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Extracting artefacts for $Label"                    -ForegroundColor Cyan
Write-Host " Source : $ArtefactsRoot"                            -ForegroundColor Cyan
Write-Host " Output : $AnalysisRoot"                             -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# --- Prefetch --------------------------------------------------------------
# PECmd has no output-lock-check bug, so --csvf is safe and gives us a
# scenario-named CSV that matches the manual headline runs.
Write-Host ""
Write-Host "[1 of 3] PECmd  (Prefetch)" -ForegroundColor White
if (Test-Path $PrefetchDir) {
    if ($PSBoundParameters.ContainsKey('Run')) {
        $PrefetchCsvName = "scenario_{0}_run{1}_prefetch.csv" -f $Scenario, $Run
    }
    else {
        $PrefetchCsvName = "scenario_{0}_prefetch.csv" -f $Scenario
    }
    & $PECmd -d $PrefetchDir --csv $PrefetchOut --csvf $PrefetchCsvName -q
}
else {
    Write-Host "  Skipped, no prefetch folder present." -ForegroundColor DarkYellow
}

# --- Event Logs ------------------------------------------------------------
# EvtxECmd v2026.5.0 misreports a lock check when --csvf points at a file that
# does not exist yet, so we omit --csvf and let it auto-name the output
# (documented in project memory feedback_zimmerman_tool_quirks).
Write-Host ""
Write-Host "[2 of 3] EvtxECmd  (Event Logs)" -ForegroundColor White
if (Test-Path $EventLogsDir) {
    & $EvtxECmd -d $EventLogsDir --csv $EventLogsOut
}
else {
    Write-Host "  Skipped, no event_logs folder present." -ForegroundColor DarkYellow
}

# --- Shellbags -------------------------------------------------------------
# SBECmd v2026.5.0 has the same lock-check bug as EvtxECmd but silently prints
# a false "Exported to:" success line. Workaround: pre-create empty target
# CSVs so the lock check passes, then rename SBECmd's 0_-prefixed outputs on
# top of the dummies. Same fix documented in feedback_zimmerman_tool_quirks.
Write-Host ""
Write-Host "[3 of 3] SBECmd  (Shellbags)" -ForegroundColor White
if (Test-Path $ShellBagsDir) {
    $DummyUsr = Join-Path $ShellBagsOut 'UsrClass.csv'
    $DummyNtu = Join-Path $ShellBagsOut 'NTUSER.csv'
    New-Item -ItemType File -Path $DummyUsr, $DummyNtu -Force | Out-Null

    & $SBECmd -d $ShellBagsDir --csv $ShellBagsOut --nl

    # Delete the empty placeholders and promote SBECmd's real outputs.
    Remove-Item -LiteralPath $DummyUsr, $DummyNtu -Force -ErrorAction SilentlyContinue

    $RealUsr = Join-Path $ShellBagsOut '0_UsrClass.csv'
    $RealNtu = Join-Path $ShellBagsOut '0_NTUSER.csv'
    if (Test-Path $RealUsr) { Rename-Item -LiteralPath $RealUsr 'UsrClass.csv' -Force }
    if (Test-Path $RealNtu) { Rename-Item -LiteralPath $RealNtu 'NTUSER.csv'   -Force }
}
else {
    Write-Host "  Skipped, no shellbags folder present." -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " Extraction complete for $Label"                    -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

Get-ChildItem -Path $AnalysisRoot -Recurse -File |
    Select-Object @{n='File'; e = { $_.FullName.Substring($AnalysisRoot.Length + 1) }},
                  @{n='SizeKB'; e = { [math]::Round($_.Length / 1KB, 1) }} |
    Format-Table -AutoSize
