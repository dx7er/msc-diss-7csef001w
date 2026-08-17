<#
.SYNOPSIS
Ground-truth logging helper for scenario execution.

.DESCRIPTION
Defines the Log-Action function used during manual scenario execution in the
Windows 11 testbed. Called before and after every GUI action during a scenario
run so the researcher captures precise UTC start / end timestamps without
polluting the guest with a persistent log file until export.

.NOTES
Dot-source this script at the start of every scenario run in guest PowerShell:

    . C:\Path\To\log_action.ps1

Then per action:

    Log-Action A01 start "Open Edge"
    # ... perform the GUI action ...
    Log-Action A01 end

At end of run, save under the new naming scheme:

    # Single run scenario (Scenario 1, Scenario 2, Scenario 3, Scenario 5,
    # Scenario 6, Scenario 8, Scenario 9, Scenario 10):
    Save-Log -Scenario 2
        # -> writes C:\DISS_TESTDATA\scenario2_actions.csv

    # Multi run scenario (Scenario 4 and Scenario 7 only):
    Save-Log -Scenario 4 -Run 1
        # -> writes C:\DISS_TESTDATA\scenario4_run1_actions.csv

Ground-truth CSV columns match the testbed template at
`testbed/scripts/14c-ground-truth-template.csv`.

Author: Syed Muhammad Saqlain Abbas (W21634541)
Repo:   github.com/dx7er/msc-diss-7csef001w
Module: 7CSEF001W.2 MSc Cyber Security & Forensics Project
#>

# In-memory log for the current run
$script:log = @()

function Log-Action {
    <#
    .SYNOPSIS
    Append a single timestamped action record to the in-memory scenario log.

    .PARAMETER id
    Action ID, e.g. A01, A02.

    .PARAMETER phase
    Either 'start' or 'end'. Anything else is accepted but breaks the standard
    start/end pairing convention used by the evaluation matrix.

    .PARAMETER note
    Optional free-text description. Included in the CSV export.

    .EXAMPLE
    Log-Action A01 start "Open Edge"

    .EXAMPLE
    Log-Action A01 end
    #>
    param(
        [Parameter(Mandatory)][string]$id,
        [Parameter(Mandatory)][string]$phase,
        [string]$note = ''
    )
    $ts = Get-Date -Format o
    $script:log += [PSCustomObject]@{
        Action = $id
        Phase  = $phase
        UTC    = $ts
        Note   = $note
    }
    Write-Host "$id $phase $ts $note"
}

function Save-Log {
    <#
    .SYNOPSIS
    Export the in-memory scenario log to a CSV named for the scenario (and run,
    for multi-run scenarios).

    .PARAMETER Scenario
    Scenario number as an integer, e.g. 2 for Scenario 2.

    .PARAMETER Run
    Optional repetition number as an integer, e.g. 1 for Run 1. Omit for
    single-run scenarios (Scenarios 1, 2, 3, 5, 6, 8, 9, 10). Provide for
    multi-run scenarios (Scenarios 4 and 7).

    .PARAMETER Path
    Optional override for output directory (default C:\DISS_TESTDATA).

    .EXAMPLE
    Save-Log -Scenario 2
        # -> C:\DISS_TESTDATA\scenario2_actions.csv

    .EXAMPLE
    Save-Log -Scenario 4 -Run 1
        # -> C:\DISS_TESTDATA\scenario4_run1_actions.csv
    #>
    param(
        [Parameter(Mandatory)][int]$Scenario,
        [int]$Run = 0,
        [string]$Path = 'C:\DISS_TESTDATA'
    )
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    if ($Run -eq 0) {
        $filename = "scenario${Scenario}_actions.csv"
    } else {
        $filename = "scenario${Scenario}_run${Run}_actions.csv"
    }
    $file = Join-Path $Path $filename
    $script:log | Export-Csv -Path $file -NoTypeInformation
    Write-Host "Wrote $($script:log.Count) rows to $file"
}

function Show-Log {
    <#
    .SYNOPSIS
    Display the current in-memory log as a formatted table.

    .EXAMPLE
    Show-Log
    #>
    $script:log | Format-Table -AutoSize
}

function Reset-Log {
    <#
    .SYNOPSIS
    Clear the in-memory log. Use only when starting a fresh run.

    .EXAMPLE
    Reset-Log
    #>
    $script:log = @()
    Write-Host "Log cleared"
}
