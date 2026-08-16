<#
    Interactive host-side ground-truth logger for P00-R01 and P00-R02.

    Keep this script running on the host while carrying out each action in
    the guest. It timestamps the action independently of the artefacts being
    evaluated and writes each row immediately so a partial run is recoverable.

    Start before restoring/booting the VM:
        powershell.exe -ExecutionPolicy Bypass -File .\14c-log-ground-truth-HOST.ps1 -RunId P00-R01

    Resume an interrupted log:
        powershell.exe -ExecutionPolicy Bypass -File .\14c-log-ground-truth-HOST.ps1 -RunId P00-R01 -Resume
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('P00-R01', 'P00-R02')]
    [string]$RunId,

    [string]$OutputDirectory,

    [switch]$Resume
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = "D:\UOW\SEM3\DISS_Config\pilots\$RunId"
}

$browsedPath = 'C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9'
$unbrowsedPath = 'C:\DISS_TESTDATA\PILOT\P00R01_UNBROWSED_Q4M2'
$outputPath = Join-Path $OutputDirectory "$RunId-ground-truth.csv"

$actions = @(
    [pscustomobject]@{ Id='A01'; Action='Restore B00-CANDIDATE and boot the VM'; Executable='vmware-vmx.exe'; Path=''; Expected='Boot completed'; Offset='' },
    [pscustomobject]@{ Id='A02'; Action='Wait 60 seconds for one-off VMware time correction'; Executable=''; Path=''; Expected='Wait completed'; Offset='' },
    [pscustomobject]@{ Id='A03'; Action='Record guest-minus-host clock offset before activity'; Executable='powershell.exe'; Path=''; Expected='Clock offset recorded'; Offset='Before' },
    [pscustomobject]@{ Id='A04'; Action='Run 14a-pilot-pre-run.ps1 in the guest'; Executable='powershell.exe'; Path="C:\DISS_PILOT\$RunId"; Expected='Pre-run capture completed'; Offset='' },
    [pscustomobject]@{ Id='A05'; Action='Open File Explorer'; Executable='explorer.exe'; Path=$browsedPath; Expected='Explorer opened'; Offset='' },
    [pscustomobject]@{ Id='A06'; Action='Browse the positive-control root'; Executable='explorer.exe'; Path=$browsedPath; Expected='Folder displayed'; Offset='' },
    [pscustomobject]@{ Id='A07'; Action='Browse ALPHA'; Executable='explorer.exe'; Path="$browsedPath\ALPHA"; Expected='Folder displayed'; Offset='' },
    [pscustomobject]@{ Id='A08'; Action='Browse BRAVO'; Executable='explorer.exe'; Path="$browsedPath\ALPHA\BRAVO"; Expected='Folder displayed'; Offset='' },
    [pscustomobject]@{ Id='A09'; Action='Browse CHARLIE'; Executable='explorer.exe'; Path="$browsedPath\ALPHA\BRAVO\CHARLIE"; Expected='Folder displayed'; Offset='' },
    [pscustomobject]@{ Id='A10'; Action='Open Notepad first time'; Executable='notepad.exe'; Path=''; Expected='Notepad opened'; Offset='' },
    [pscustomobject]@{ Id='A11'; Action='Close Notepad first time'; Executable='notepad.exe'; Path=''; Expected='Notepad closed'; Offset='' },
    [pscustomobject]@{ Id='A12'; Action='Open Notepad second time'; Executable='notepad.exe'; Path=''; Expected='Notepad opened'; Offset='' },
    [pscustomobject]@{ Id='A13'; Action='Close Notepad second time'; Executable='notepad.exe'; Path=''; Expected='Notepad closed'; Offset='' },
    [pscustomobject]@{ Id='A14'; Action='Lock the guest with Win+L, wait 30 seconds, then unlock'; Executable=''; Path=''; Expected='Guest locked and unlocked'; Offset='' },
    [pscustomobject]@{ Id='A15'; Action='Attach the controlled USB device'; Executable=''; Path=''; Expected='USB attached'; Offset='' },
    [pscustomobject]@{ Id='A16'; Action='Browse the controlled USB root and test folder'; Executable='explorer.exe'; Path='<record USB paths in outcome>'; Expected='USB folders displayed'; Offset='' },
    [pscustomobject]@{ Id='A17'; Action='Copy one synthetic file from USB to local Documents'; Executable='explorer.exe'; Path='<record source and destination in outcome>'; Expected='File copied'; Offset='' },
    [pscustomobject]@{ Id='A18'; Action='Safely eject and disconnect the controlled USB'; Executable=''; Path=''; Expected='USB ejected'; Offset='' },
    [pscustomobject]@{ Id='A19'; Action='Close File Explorer'; Executable='explorer.exe'; Path=''; Expected='Explorer closed'; Offset='' },
    [pscustomobject]@{ Id='A20'; Action='Wait 60 to 120 seconds for artefact flush'; Executable=''; Path=''; Expected='Wait completed'; Offset='' },
    [pscustomobject]@{ Id='A21'; Action='Record guest-minus-host clock offset after activity'; Executable='powershell.exe'; Path=''; Expected='Clock offset recorded'; Offset='After' },
    [pscustomobject]@{ Id='A22'; Action='Run 14b-pilot-post-run.ps1 in the guest'; Executable='powershell.exe'; Path="C:\DISS_PILOT\$RunId"; Expected='Post-run capture completed'; Offset='' },
    [pscustomobject]@{ Id='A23'; Action='Shut Windows down normally'; Executable='shutdown.exe'; Path=''; Expected='Guest shut down'; Offset='' }
)

[System.IO.Directory]::CreateDirectory($OutputDirectory) | Out-Null

$completedIds = @()
if (Test-Path -LiteralPath $outputPath) {
    if (-not $Resume) {
        throw "Ground-truth log already exists: $outputPath. Use -Resume or select a different output directory."
    }
    $completedIds = @(Import-Csv -LiteralPath $outputPath | Select-Object -ExpandProperty ActionID)
}

Write-Host "Pilot ground-truth logger: $RunId" -ForegroundColor Cyan
Write-Host "Output: $outputPath"
Write-Host "NEGATIVE CONTROL: never open $unbrowsedPath in Explorer." -ForegroundColor Yellow
Write-Host 'USB is part of the formal scope. If unavailable, record SKIPPED and do not claim the USB promotion criterion passed.' -ForegroundColor Yellow

foreach ($action in $actions) {
    if ($completedIds -contains $action.Id) {
        Write-Host "Skipping completed action $($action.Id)" -ForegroundColor DarkGray
        continue
    }

    Write-Host ''
    Write-Host "$($action.Id): $($action.Action)" -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($action.Path)) {
        Write-Host "Target: $($action.Path)"
    }

    Read-Host 'Press ENTER immediately before starting the action' | Out-Null
    $startUtc = [DateTime]::UtcNow
    Write-Host "Host UTC start: $($startUtc.ToString('o'))" -ForegroundColor DarkGray

    $clockOffsetBefore = ''
    $clockOffsetAfter = ''
    if ($action.Offset -eq 'Before') {
        $clockOffsetBefore = Read-Host 'Enter measured guest-minus-host offset in seconds (for example -0.42)'
    }
    elseif ($action.Offset -eq 'After') {
        $clockOffsetAfter = Read-Host 'Enter measured guest-minus-host offset in seconds (for example -0.42)'
    }

    Read-Host 'Complete the action, return here, then press ENTER immediately' | Out-Null
    $endUtc = [DateTime]::UtcNow
    $observed = Read-Host "Observed outcome [ENTER = $($action.Expected)]"
    if ([string]::IsNullOrWhiteSpace($observed)) {
        $observed = $action.Expected
    }
    $deviation = Read-Host 'Deviation from procedure [ENTER = None]'
    if ([string]::IsNullOrWhiteSpace($deviation)) {
        $deviation = 'None'
    }

    [pscustomobject]@{
        RunId             = $RunId
        ActionID          = $action.Id
        ActualAction      = $action.Action
        HostUTCStart      = $startUtc.ToString('o')
        HostUTCEnd        = $endUtc.ToString('o')
        TargetExecutable  = $action.Executable
        TargetPath        = $action.Path
        ClockOffsetBefore = $clockOffsetBefore
        ClockOffsetAfter  = $clockOffsetAfter
        ObservedOutcome   = $observed
        Deviation         = $deviation
    } | Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding utf8 -Append
}

Write-Host ''
Write-Host "Ground-truth log complete: $outputPath" -ForegroundColor Green
