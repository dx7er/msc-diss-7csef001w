<#
.SYNOPSIS
Session-persistent ground-truth logger for Scenario 6 (Logon, lock, unlock,
logoff cycle).

.DESCRIPTION
Scenario 6 spans three interactive logon sessions of the 'dfanalyst' user
(sign-out at A01, sign-in at A02, lock at A03, unlock at A05, sign-out at
A06, sign-in at A07). Each sign-out terminates the PowerShell host and
destroys the in-memory log used by the standard scripts/scenarios/log_action.ps1
helper. This variant writes every action row directly to a CSV on disk in
append mode, so the same file accumulates rows across all three sessions.

The output CSV columns match the standard helper (Action, Phase, UTC, Note)
so the merged file drops into the same downstream pipeline used by every
other scenario (evaluation/ground_truth.csv).

.NOTES
Run inside the guest (DISS-Win11-25H2-Testbed VM) as user 'dfanalyst'.
Non-elevated PowerShell is fine.

Session 1 (fresh boot from baseline_pre_scenarios):

    . C:\DISS_TESTDATA\scenario6_log.ps1
    Init-Scenario6Log        # creates a fresh CSV, wiping any prior run
    Log-Action6 A01 start "Sign out via Start menu"
    # perform sign-out; this PowerShell dies

Session 2 (after signing back in as dfanalyst):

    . C:\DISS_TESTDATA\scenario6_log.ps1
    Log-Action6 A01 end   "session terminated on sign-out; end time approximated"
    Log-Action6 A02 start "sign-in as dfanalyst (retrospective)"
    Log-Action6 A02 end   "desktop loaded"
    Log-Action6 A03 start "press Win+L"
    Log-Action6 A03 end   "workstation locked"
    # press Win+L; wait 15 s; unlock with password
    Log-Action6 A04 start "wait 15 s while locked (retrospective)"
    Log-Action6 A04 end
    Log-Action6 A05 start "unlock with password (retrospective)"
    Log-Action6 A05 end   "desktop restored"
    Log-Action6 A06 start "Sign out via Start menu"
    # perform sign-out; this PowerShell dies

Session 3 (after signing back in as dfanalyst):

    . C:\DISS_TESTDATA\scenario6_log.ps1
    Log-Action6 A06 end   "session terminated on sign-out; end time approximated"
    Log-Action6 A07 start "sign-in as dfanalyst (retrospective)"
    Log-Action6 A07 end   "desktop loaded"
    Finalise-Scenario6Log  # prints summary; the CSV is already on disk

Exact end times for A01 and A06 are best derived post hoc from Security
4634 in the event log during Phase 4; the researcher-recorded end times
here are approximate wall-clock notes only. The scenario's evidential
value is in event log matching, not in the researcher timestamps.

.NOTES
Author: Syed Muhammad Saqlain Abbas (W21634541)
Repo:   github.com/dx7er/msc-diss-7csef001w
Module: 7CSEF001W.2 MSc Cyber Security & Forensics Project
#>

$script:S6LogRoot = 'C:\DISS_TESTDATA'
$script:S6LogFile = Join-Path $script:S6LogRoot 'scenario6_actions.csv'

function Init-Scenario6Log {
    <#
    .SYNOPSIS
    Prepare a fresh scenario6_actions.csv with the standard header row.
    Overwrites any file left over from a prior aborted run.
    #>
    if (-not (Test-Path $script:S6LogRoot)) {
        New-Item -ItemType Directory -Force -Path $script:S6LogRoot | Out-Null
    }
    '"Action","Phase","UTC","Note"' | Out-File -FilePath $script:S6LogFile -Encoding UTF8
    Write-Host "Initialised $script:S6LogFile"
}

function Log-Action6 {
    <#
    .SYNOPSIS
    Append one timestamped action row to scenario6_actions.csv.

    .DESCRIPTION
    Writes immediately to disk so the row survives if this PowerShell host
    is terminated (e.g. by a sign-out). No in-memory buffer.

    .PARAMETER id
    Action ID, e.g. A01, A02.

    .PARAMETER phase
    Either 'start' or 'end'.

    .PARAMETER note
    Optional free-text description. Included in the CSV.
    #>
    param(
        [Parameter(Mandatory)][string]$id,
        [Parameter(Mandatory)][string]$phase,
        [string]$note = ''
    )
    if (-not (Test-Path $script:S6LogFile)) {
        Init-Scenario6Log
    }
    $ts   = Get-Date -Format o
    $safe = $note -replace '"', '""'
    $line = '"{0}","{1}","{2}","{3}"' -f $id, $phase, $ts, $safe
    Add-Content -Path $script:S6LogFile -Value $line -Encoding UTF8
    Write-Host "$id $phase $ts $note"
}

function Show-Scenario6Log {
    <#
    .SYNOPSIS
    Print the accumulated scenario6_actions.csv as a formatted table.
    #>
    if (Test-Path $script:S6LogFile) {
        Import-Csv $script:S6LogFile | Format-Table -AutoSize
    } else {
        Write-Host "No log file at $script:S6LogFile"
    }
}

function Finalise-Scenario6Log {
    <#
    .SYNOPSIS
    Print a one-line summary of the accumulated log. The file itself is
    already on disk; nothing more to write.
    #>
    if (Test-Path $script:S6LogFile) {
        $rows = Import-Csv $script:S6LogFile
        Write-Host "scenario6_actions.csv: $($rows.Count) rows at $script:S6LogFile"
        Show-Scenario6Log
    } else {
        Write-Host "No log file at $script:S6LogFile"
    }
}
