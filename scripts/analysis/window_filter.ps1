<#
.SYNOPSIS
    Narrows parsed forensic CSVs down to only the rows that fall inside any
    ground-truth action window (with a +/-2s tolerance).

.DESCRIPTION
    Reads scenarios/scenario_N/[run_M/]evaluation/ground_truth.csv, pairs each
    action's start and end rows, expands each pair into a [start-Pad, end+Pad]
    UTC window, then filters:

        analysis/prefetch/scenario_N[_runM]_prefetch_Timeline.csv   by RunTime
        analysis/event_logs/*_EvtxECmd_Output.csv                   by TimeCreated

    Outputs land under analysis/windowed/ preserving the same subfolder layout.
    A windows.csv summary is also written so the exact bounds used are
    auditable alongside the filtered evidence.

    ShellBags CSVs are NOT time-filtered. Shellbag timestamps (LastInteracted,
    LastWriteTime, etc.) do not reliably fall inside action windows because a
    folder may have been navigated to before the scenario started; the whole
    UsrClass.csv is small enough (<20 rows in every scenario) to review as a
    block. They are copied through unchanged so the correlation step still
    finds them under analysis/windowed/shellbags/.

    The PECmd main CSV (scenario_N[_runM]_prefetch.csv) is also NOT filtered:
    each row already carries up to 8 run timestamps (LastRun plus 7
    PreviousRun columns), so a single-column time filter would give a
    misleading view. Use the Timeline CSV for time-windowed prefetch review,
    then pivot back to the main CSV for volume, hash, and DLL details.

.PARAMETER Scenario
    Scenario number, 1 to 10. Required.

.PARAMETER Run
    Run number, 1 to 3. Required for multi-run scenarios (S04, S07);
    omit for single-run scenarios.

.PARAMETER PadSeconds
    Tolerance added at each end of every action window. Default 2s.
    Matches the methodology tolerance justified in the write-up
    (VM clock skew + Windows event-write latency).

.EXAMPLE
    .\window_filter.ps1 -Scenario 1
    Filters single-run Scenario 1 with a +/-2s pad.

.EXAMPLE
    .\window_filter.ps1 -Scenario 7 -Run 2 -PadSeconds 3
    Filters Run 2 of multi-run Scenario 7 with a +/-3s pad.

.NOTES
    Assumes EvtxECmd default UTC output (verified via S7 spot-check 2026-08-25).
    Assumes VM system clock is UTC (dissertation testbed convention).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [int]$Scenario,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3)]
    [int]$Run,

    [Parameter(Mandatory = $false)]
    [int]$PadSeconds = 2
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# 1. Resolve paths
# ---------------------------------------------------------------------------
$RepoRoot     = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ScenarioRoot = Join-Path $RepoRoot ("scenarios\scenario_{0}" -f $Scenario)

if ($PSBoundParameters.ContainsKey('Run')) {
    $WorkRoot   = Join-Path $ScenarioRoot ("run_{0}" -f $Run)
    $Label      = "Scenario $Scenario Run $Run"
    $PfBaseName = "scenario_{0}_run{1}_prefetch"     -f $Scenario, $Run
}
else {
    $WorkRoot   = $ScenarioRoot
    $Label      = "Scenario $Scenario"
    $PfBaseName = "scenario_{0}_prefetch"            -f $Scenario
}

$GtCsv      = Join-Path $WorkRoot 'evaluation\ground_truth.csv'
$AnalysisIn = Join-Path $WorkRoot 'analysis'
$WindowedOut = Join-Path $WorkRoot 'analysis\windowed'

foreach ($p in @($GtCsv, $AnalysisIn)) {
    if (-not (Test-Path $p)) { throw "Required path missing: $p" }
}

if (Test-Path $WindowedOut) {
    Write-Host "Cleaning existing windowed folder: $WindowedOut" -ForegroundColor Yellow
    Remove-Item -LiteralPath $WindowedOut -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $WindowedOut 'prefetch'),
                                    (Join-Path $WindowedOut 'event_logs'),
                                    (Join-Path $WindowedOut 'shellbags') -Force | Out-Null

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Window-filtering $Label"                            -ForegroundColor Cyan
Write-Host " Ground truth : $GtCsv"                              -ForegroundColor Cyan
Write-Host " Pad (each side) : +/-$PadSeconds s"                 -ForegroundColor Cyan
Write-Host " Output : $WindowedOut"                              -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Build windows from ground truth
# ---------------------------------------------------------------------------
# Ground-truth UTC field carries an explicit +00:00 offset, so
# [datetimeoffset]::Parse returns Kind=Utc-equivalent instants safely.
$gtRows = Import-Csv -Path $GtCsv

$windows = @()
foreach ($grp in ($gtRows | Where-Object { $_.Action -ne 'PRE' } | Group-Object -Property Action)) {
    $s = $grp.Group | Where-Object { $_.Phase -eq 'start' } | Select-Object -First 1
    $e = $grp.Group | Where-Object { $_.Phase -eq 'end'   } | Select-Object -First 1
    if (-not $s) { continue }

    $startUtc = ([datetimeoffset]::Parse($s.UTC)).UtcDateTime.AddSeconds(-$PadSeconds)
    if ($e) {
        $endUtc = ([datetimeoffset]::Parse($e.UTC)).UtcDateTime.AddSeconds($PadSeconds)
    }
    else {
        # No end row -> treat as instant, pad both sides.
        $endUtc = ([datetimeoffset]::Parse($s.UTC)).UtcDateTime.AddSeconds($PadSeconds)
    }

    $windows += [pscustomobject]@{
        Action    = $grp.Name
        Note      = $s.Note
        StartUtc  = $startUtc
        EndUtc    = $endUtc
        DurationSec = [math]::Round(($endUtc - $startUtc).TotalSeconds, 2)
    }
}

$windows = $windows | Sort-Object StartUtc
$windows | Select-Object Action, Note,
    @{n='StartUtc'; e={ $_.StartUtc.ToString('yyyy-MM-dd HH:mm:ss.fff') }},
    @{n='EndUtc';   e={ $_.EndUtc.ToString(  'yyyy-MM-dd HH:mm:ss.fff') }},
    DurationSec |
    Export-Csv -Path (Join-Path $WindowedOut 'windows.csv') -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host ("Built {0} windows from ground truth (pad +/-{1}s):" -f $windows.Count, $PadSeconds)
$windows | Format-Table Action, Note,
    @{n='StartUtc'; e={ $_.StartUtc.ToString('HH:mm:ss.fff') }},
    @{n='EndUtc';   e={ $_.EndUtc.ToString(  'HH:mm:ss.fff') }},
    DurationSec -AutoSize

# Small closure to test a UTC datetime against every window.
$Test = {
    param([datetime]$dt)
    foreach ($w in $script:windows) {
        if ($dt -ge $w.StartUtc -and $dt -le $w.EndUtc) { return $true }
    }
    return $false
}
$script:windows = $windows

# ---------------------------------------------------------------------------
# 3. Prefetch Timeline (one row per run event)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[1 of 2] Prefetch Timeline" -ForegroundColor White

$pfTlIn  = Join-Path $AnalysisIn ("prefetch\{0}_Timeline.csv" -f $PfBaseName)
$pfTlOut = Join-Path $WindowedOut ("prefetch\{0}_Timeline_windowed.csv" -f $PfBaseName)

if (-not (Test-Path $pfTlIn)) {
    Write-Host "  Missing: $pfTlIn (skipped)" -ForegroundColor DarkYellow
}
else {
    $tlRows = Import-Csv -Path $pfTlIn
    $tlKept = foreach ($r in $tlRows) {
        # RunTime format from PECmd: yyyy-MM-dd HH:mm:ss (UTC when VM is UTC).
        try {
            $dt = [datetime]::SpecifyKind([datetime]::Parse($r.RunTime), [System.DateTimeKind]::Utc)
            if (& $Test $dt) { $r }
        } catch { }
    }
    $tlKept | Export-Csv -Path $pfTlOut -NoTypeInformation -Encoding UTF8
    Write-Host ("  {0} timeline rows -> {1} rows kept" -f $tlRows.Count, @($tlKept).Count)
}

# ---------------------------------------------------------------------------
# 4. EVTX combined output (streamed because file is ~30 MB per scenario)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[2 of 2] EVTX events" -ForegroundColor White

$evtxIn = Get-ChildItem -Path (Join-Path $AnalysisIn 'event_logs') -Filter '*_EvtxECmd_Output.csv' -ErrorAction SilentlyContinue |
          Select-Object -First 1

if (-not $evtxIn) {
    Write-Host "  Missing EvtxECmd output CSV (skipped)" -ForegroundColor DarkYellow
}
else {
    $evtxOut = Join-Path $WindowedOut 'event_logs\events_windowed.csv'

    # Stream line-by-line so we don't materialise 30k+ pscustomobjects in memory.
    # TimeCreated is column 3 (1-indexed). It has format yyyy-MM-dd HH:mm:ss.fffffff
    # with no timezone marker; VM is UTC by convention so we tag it Kind=Utc.
    $reader = [System.IO.StreamReader]::new($evtxIn.FullName)
    $writer = [System.IO.StreamWriter]::new($evtxOut, $false, [System.Text.Encoding]::UTF8)

    $header = $reader.ReadLine()
    $writer.WriteLine($header)

    $inCount = 0
    $keptCount = 0

    while (($line = $reader.ReadLine()) -ne $null) {
        $inCount++
        # Split only up to the 4th field; TimeCreated in field index 2 (0-based)
        # never contains commas so a naive split is safe here.
        $parts = $line.Split(',', 4)
        if ($parts.Length -lt 3) { continue }
        $tc = $parts[2].Trim('"')
        try {
            $dt = [datetime]::SpecifyKind([datetime]::Parse($tc), [System.DateTimeKind]::Utc)
            if (& $Test $dt) {
                $writer.WriteLine($line)
                $keptCount++
            }
        } catch { }
    }
    $reader.Close()
    $writer.Close()
    Write-Host ("  {0} EVTX rows -> {1} rows kept" -f $inCount, $keptCount)
}

# ---------------------------------------------------------------------------
# 5. ShellBags pass-through (see script header for rationale)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[extra] ShellBags copy-through (not time-filtered by design)" -ForegroundColor White

foreach ($f in 'NTUSER.csv', 'UsrClass.csv') {
    $src = Join-Path $AnalysisIn "shellbags\$f"
    if (Test-Path $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $WindowedOut "shellbags\$f") -Force
        Write-Host ("  {0}: {1} rows" -f $f, ((Get-Content $src).Count - 1))
    }
}

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " $Label windowing complete"                          -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

Get-ChildItem -Path $WindowedOut -Recurse -File |
    Select-Object @{n='File'; e = { $_.FullName.Substring($WindowedOut.Length + 1) }},
                  @{n='SizeKB'; e = { [math]::Round($_.Length / 1KB, 1) }},
                  @{n='Rows'; e = {
                        if ($_.Extension -eq '.csv') { (Get-Content $_.FullName).Count - 1 }
                        else { '' }
                  }} |
    Format-Table -AutoSize
