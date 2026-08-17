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

    . C:\Path\To\Log-Action.ps1

Then per action:

    Log-Action A01 start "Open Edge"
    # ... perform the GUI action ...
    Log-Action A01 end

At end of run:

    Save-Log -Scenario S01 -Run R01
        # -> writes C:\DISS_TESTDATA\S01-R01-action-log.csv

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
    Export the in-memory scenario log to a CSV named for the scenario and run.

    .PARAMETER Scenario
    Scenario ID, e.g. S01.

    .PARAMETER Run
    Repetition ID, e.g. R01.

    .PARAMETER Path
    Optional override for output directory (default C:\DISS_TESTDATA).

    .EXAMPLE
    Save-Log -Scenario S01 -Run R01
    #>
    param(
        [Parameter(Mandatory)][string]$Scenario,
        [Parameter(Mandatory)][string]$Run,
        [string]$Path = 'C:\DISS_TESTDATA'
    )
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    $file = Join-Path $Path "$Scenario-$Run-action-log.csv"
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
