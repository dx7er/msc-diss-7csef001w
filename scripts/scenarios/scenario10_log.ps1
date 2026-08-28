<#
.SYNOPSIS
Session-persistent ground-truth logger for Scenario 10 (System shutdown
and power on).

.DESCRIPTION
Scenario 10 spans two interactive logon sessions of the 'dfanalyst' user
separated by a full VM shutdown and power-on cycle. The shutdown at A01
terminates the operating system, so the in-memory log used by the
standard scripts/scenarios/log_action.ps1 helper is lost. This variant
writes every action row directly to a CSV on disk in append mode, so
the same file accumulates rows across both sessions.

The output CSV columns match the standard helper (Action, Phase, UTC,
Note) so the merged file drops into the same downstream pipeline used
by every other scenario (evaluation/ground_truth.csv).

.NOTES
Run inside the guest (DISS-Win11-25H2-Testbed VM) as user 'dfanalyst'.
Non-elevated PowerShell is fine.

Session 1 (fresh boot from baseline_pre_scenarios):

    . C:\DISS_TESTDATA\scenario10_log.ps1
    Init-Scenario10Log       # creates a fresh CSV, wiping any prior run
    Log-Action10 PRE start "baseline_pre_scenarios, dfanalyst signed in"
    Log-Action10 A01 start "Start > Power > Shut down clicked"
    # perform shutdown; the VM powers off; this session dies

Between sessions the host analyst notes the wall-clock UTC of:
  * VM powered off (A02)
  * VM powered on (A03)
using VMware Workstation as the source of truth for those two events.

Session 2 (after the VM is powered back on and dfanalyst signs in):

    . C:\DISS_TESTDATA\scenario10_log.ps1
    Log-Action10 A01 end   "session terminated on shutdown; end time approximated"
    Log-Action10 A02 start "VM powered off (host-observed UTC in note)"
    Log-Action10 A02 end   "waited 30 s"
    Log-Action10 A03 start "VM powered on (host-observed UTC in note)"
    Log-Action10 A03 end   "VM POST reached, sign-in screen approaching"
    Log-Action10 A04 start "sign-in screen visible"
    Log-Action10 A04 end   "credentials entered"
    Log-Action10 A05 start "sign-in as dfanalyst (retrospective)"
    Log-Action10 A05 end   "desktop loaded"
    Log-Action10 A06 start "wait 90 s for post-boot Prefetch layout regeneration"
    # sleep 90 s
    Log-Action10 A06 end   "post-boot settle complete"
    Finalise-Scenario10Log # prints summary; the CSV is already on disk

Exact end time for A01 is best derived post hoc from System 1074 and
6006 in the event log during Phase 4; the researcher-recorded end time
here is an approximate wall-clock note only. A02 and A03 timestamps
should carry the host-observed UTC in the Note field for cross-check
against System 27, 12, 13 events. The scenario's evidential value is
in event log matching, not in the researcher timestamps.

.NOTES
Author: Syed Muhammad Saqlain Abbas (W21634541)
Repo:   github.com/dx7er/msc-diss-7csef001w
Module: 7CSEF001W.2 MSc Cyber Security & Forensics Project
#>

$script:S10LogRoot = 'C:\DISS_TESTDATA'
$script:S10LogFile = Join-Path $script:S10LogRoot 'scenario10_actions.csv'

function Init-Scenario10Log {
    <#
    .SYNOPSIS
    Prepare a fresh scenario10_actions.csv with the standard header row.
    Overwrites any file left over from a prior aborted run.
    #>
    if (-not (Test-Path $script:S10LogRoot)) {
        New-Item -ItemType Directory -Force -Path $script:S10LogRoot | Out-Null
    }
    '"Action","Phase","UTC","Note"' | Out-File -FilePath $script:S10LogFile -Encoding UTF8
    Write-Host "Initialised $script:S10LogFile"
}

function Log-Action10 {
    <#
    .SYNOPSIS
    Append one timestamped action row to scenario10_actions.csv.

    .DESCRIPTION
    Writes immediately to disk so the row survives if this PowerShell
    host or the entire OS is terminated (e.g. by a shutdown). No
    in-memory buffer.

    .PARAMETER id
    Action ID, e.g. PRE, A01, A02.

    .PARAMETER phase
    Either 'start' or 'end'.

    .PARAMETER note
    Optional free-text description. Include host-observed UTC here for
    A02 and A03. Included in the CSV.
    #>
    param(
        [Parameter(Mandatory)][string]$id,
        [Parameter(Mandatory)][string]$phase,
        [string]$note = ''
    )
    if (-not (Test-Path $script:S10LogFile)) {
        Init-Scenario10Log
    }
    $ts   = Get-Date -Format o
    $safe = $note -replace '"', '""'
    $line = '"{0}","{1}","{2}","{3}"' -f $id, $phase, $ts, $safe
    Add-Content -Path $script:S10LogFile -Value $line -Encoding UTF8
    Write-Host "$id $phase $ts $note"
}

function Show-Scenario10Log {
    <#
    .SYNOPSIS
    Print the accumulated scenario10_actions.csv as a formatted table.
    #>
    if (Test-Path $script:S10LogFile) {
        Import-Csv $script:S10LogFile | Format-Table -AutoSize
    } else {
        Write-Host "No log file at $script:S10LogFile"
    }
}

function Finalise-Scenario10Log {
    <#
    .SYNOPSIS
    Print a one-line summary of the accumulated log. The file itself is
    already on disk; nothing more to write.
    #>
    if (Test-Path $script:S10LogFile) {
        $rows = Import-Csv $script:S10LogFile
        Write-Host "scenario10_actions.csv: $($rows.Count) rows at $script:S10LogFile"
        Show-Scenario10Log
    } else {
        Write-Host "No log file at $script:S10LogFile"
    }
}
