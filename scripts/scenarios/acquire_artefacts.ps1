<#
.SYNOPSIS
Offline artefact acquisition for one scenario run using Arsenal Image Mounter.

.DESCRIPTION
Resolves the correct snapshot VMDK from .vmsd, mounts it read only via AIM's
DiscUtils provider, robocopies the target artefacts into
scenarios/scenario_N/run_M/artefacts/{class}/, dismounts cleanly, and writes a
SHA 256 manifest. Idempotent: cleans up any prior AIM mounts on start.

.PARAMETER Scenario
Scenario ID, e.g. S01.

.PARAMETER Run
Repetition ID, e.g. R01.

.PARAMETER VmDir
VM directory containing .vmx, .vmsd, .vmdk. Default D:\UOW\SEM3\DISS-Win11-Testbed-VM.

.PARAMETER RepoRoot
Repository root. Default D:\UOW\SEM3\msc-diss-7csef001w.

.PARAMETER GuestUser
Guest username whose profile is extracted. Default dfanalyst.

.PARAMETER AimCli
Path to aim_cli.exe.

.EXAMPLE
.\acquire_artefacts.ps1 -Scenario S01 -Run R01

.NOTES
Must run elevated. VMware Workstation must be closed. Snapshot named
S{Scenario}-R{Run}-POST must exist.

Author: Syed Muhammad Saqlain Abbas (W21634541) | Module 7CSEF001W.2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Scenario,
    [Parameter(Mandatory)][string]$Run,
    [string]$VmDir     = 'D:\UOW\SEM3\DISS-Win11-Testbed-VM',
    [string]$RepoRoot  = 'D:\UOW\SEM3\msc-diss-7csef001w',
    [string]$GuestUser = 'dfanalyst',
    [string]$AimCli    = 'C:\Users\SSNAQVI\Desktop\Arsenal-Image-Mounter-v3.13.368\Arsenal-Image-Mounter-v3.13.368\aim_cli.exe'
)

$ErrorActionPreference = 'Stop'
# Not using StrictMode: it throws PropertyNotFoundStrict on .Count of empty
# Get-ChildItem results, which is a normal outcome when a folder is empty.

$runId        = "$Scenario-$Run"
$snapshotName = "$runId-POST"

# Translate S01 / R01 into scenario_1 / run_1 folder names used under scenarios\.
$scenarioNum  = [int]($Scenario -replace '^[Ss]','')
$runNum       = [int]($Run      -replace '^[Rr]','')
$scenarioDir  = "scenario_$scenarioNum"
$runDir       = "run_$runNum"

function Info($m) { Write-Host "[Acquire] $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "[Acquire] $m" -ForegroundColor Green }
function Warn($m) { Write-Warning $m }

# ============================================================================
# 1. Preconditions
# ============================================================================
Info "$runId offline acquisition starting"

# Elevation
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    throw "Not elevated. Right click PowerShell and Run as Administrator."
}

if (-not (Test-Path $AimCli)) { throw "aim_cli.exe not found at $AimCli." }
if (-not (Test-Path $VmDir))  { throw "VM directory not found: $VmDir." }

# Enable SeBackupPrivilege in this process token so robocopy /b can read
# ACL protected files (NTUSER.DAT, UsrClass.dat, SYSTEM, SOFTWARE, hives).
# Elevation grants the privilege; it must still be explicitly enabled.
if (-not ('Priv.Enabler' -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Priv {
    public static class Enabler {
        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool OpenProcessToken(IntPtr h, uint da, out IntPtr th);
        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool LookupPrivilegeValueW(string sys, string name, out long luid);
        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool AdjustTokenPrivileges(IntPtr th, bool dis, ref TOKEN_PRIVILEGES np, uint bl, IntPtr pp, IntPtr rl);
        [DllImport("kernel32.dll")]
        private static extern IntPtr GetCurrentProcess();
        [StructLayout(LayoutKind.Sequential)]
        public struct TOKEN_PRIVILEGES { public int PrivilegeCount; public long Luid; public int Attributes; }
        public static bool Enable(string priv) {
            IntPtr t;
            if (!OpenProcessToken(GetCurrentProcess(), 0x20 | 0x8, out t)) return false;
            long luid;
            if (!LookupPrivilegeValueW(null, priv, out luid)) return false;
            var tp = new TOKEN_PRIVILEGES { PrivilegeCount = 1, Luid = luid, Attributes = 2 };
            return AdjustTokenPrivileges(t, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        }
    }
}
"@
}
[void][Priv.Enabler]::Enable("SeBackupPrivilege")
[void][Priv.Enabler]::Enable("SeRestorePrivilege")
[void][Priv.Enabler]::Enable("SeSecurityPrivilege")
Info "Enabled SeBackupPrivilege, SeRestorePrivilege, SeSecurityPrivilege"

# Nothing from VMware Workstation may be holding the VMDK
$blocking = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @('vmware','vmware-vmx','vmware-tray','vmplayer','vmrun') }
if ($blocking) {
    throw "VMware process(es) running: $(($blocking.Name | Select-Object -Unique) -join ', '). Close VMware first."
}
$locks = Get-ChildItem -LiteralPath $VmDir -Filter '*.lck' -Recurse -ErrorAction SilentlyContinue
if ($locks) { throw "VMware lock file(s) present in $VmDir. Close VMware entirely." }

# ============================================================================
# 2. Resolve snapshot to VMDK from .vmsd
# ============================================================================
$vmsd = Get-ChildItem -LiteralPath $VmDir -Filter '*.vmsd' | Select-Object -First 1
if (-not $vmsd) { throw "No .vmsd file in $VmDir." }
$vmsdText = Get-Content -LiteralPath $vmsd.FullName -Raw

$snapUid = $null
foreach ($line in $vmsdText -split "`r?`n") {
    if ($line -match '^\s*snapshot(\d+)\.displayName\s*=\s*"([^"]+)"' -and $Matches[2] -eq $snapshotName) {
        $snapUid = $Matches[1]; break
    }
}
if (-not $snapUid) { throw "Snapshot '$snapshotName' not found in $($vmsd.Name)." }

$vmdkFile = $null
$pattern  = "^\s*snapshot$snapUid\.disk0\.fileName\s*=\s*`"([^`"]+)`""
foreach ($line in $vmsdText -split "`r?`n") {
    if ($line -match $pattern) { $vmdkFile = $Matches[1]; break }
}
if (-not $vmdkFile) { throw "disk0.fileName for snapshot uid $snapUid not found." }
$vmdkPath = Join-Path $VmDir $vmdkFile
if (-not (Test-Path $vmdkPath)) { throw "VMDK missing: $vmdkPath" }
Info "Resolved '$snapshotName' -> $vmdkFile"

# ============================================================================
# 3. Clean up any prior AIM mounts (idempotent restart)
# ============================================================================
$listOutput = & $AimCli --list 2>&1 | Out-String
if ($listOutput -match 'Device number\s+(\d{6})') {
    Warn "Existing AIM mount(s) detected. Dismounting all before proceeding."
    $existingNums = [regex]::Matches($listOutput, 'Device number\s+(\d{6})') |
                    ForEach-Object { $_.Groups[1].Value }
    foreach ($n in $existingNums) {
        & $AimCli --dismount=$n --force 2>&1 | Out-Null
    }
    Start-Sleep -Seconds 2
}

# ============================================================================
# 4. Prepare output directories under scenarios\scenario_N\run_M\
# ============================================================================
$runRoot   = Join-Path $RepoRoot "scenarios\$scenarioDir\$runDir"
$artRoot   = Join-Path $runRoot 'artefacts'
$outDirs   = [ordered]@{
    prefetch   = Join-Path $artRoot 'prefetch'
    eventLogs  = Join-Path $artRoot 'event_logs'
    shellbags  = Join-Path $artRoot 'shellbags'
    supporting = Join-Path $artRoot 'supporting'
}
$evalDir   = Join-Path $runRoot 'evaluation'

foreach ($d in $outDirs.Values) {
    if (Test-Path $d) { Remove-Item $d -Recurse -Force }
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}
if (-not (Test-Path $evalDir)) { New-Item -ItemType Directory -Path $evalDir -Force | Out-Null }

Info "Landing under $runRoot"

# ============================================================================
# 5. Baseline: current drive letters
# ============================================================================
$lettersBefore = @(Get-Volume | Where-Object { $_.DriveLetter } |
                   Select-Object -ExpandProperty DriveLetter)

# ============================================================================
# 6. Mount VMDK via AIM
# aim_cli without --background blocks waiting for Ctrl+C. Launch it as a
# non blocking background process; we tear its mount down externally later.
# ============================================================================
Info "Mounting $vmdkFile via aim_cli (DiscUtils, read only, online)"
$aimLog = Join-Path $env:TEMP "aim_cli_$runId.log"
$aimMountProc = Start-Process -FilePath $AimCli `
    -ArgumentList @('--mount','--readonly','--online','--provider=DiscUtils',"--filename=$vmdkPath") `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $aimLog -RedirectStandardError "$aimLog.err"

$aimDeviceNum = $null
$driveLetter  = $null

try {
    # -----------------------------------------------------------------------
    # 7. Wait for AIM device to register AND Windows to assign a drive letter
    # -----------------------------------------------------------------------
    Info "Waiting for mount to attach and Windows to assign drive letters..."
    $deadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 750

        # aim_cli may exit early with an error before mount succeeds
        if ($aimMountProc.HasExited -and $aimMountProc.ExitCode -ne 0) {
            $errText = if (Test-Path "$aimLog.err") { Get-Content "$aimLog.err" -Raw } else { '' }
            throw "aim_cli exited early with code $($aimMountProc.ExitCode). Log: $errText"
        }

        # Find the AIM device number from --list
        if (-not $aimDeviceNum) {
            $ls = & $AimCli --list 2>&1 | Out-String
            if ($ls -match 'Device number\s+(\d{6})') {
                $aimDeviceNum = $Matches[1]
            }
        }

        # Find the new NTFS drive letter (largest one that just appeared, >50 GB)
        if (-not $driveLetter) {
            $candidate = Get-Volume |
                Where-Object {
                    $_.DriveLetter -and
                    $_.DriveLetter -notin $lettersBefore -and
                    $_.FileSystem -eq 'NTFS' -and
                    $_.Size -gt 50GB
                } | Sort-Object Size -Descending | Select-Object -First 1
            if ($candidate) { $driveLetter = "$($candidate.DriveLetter):" }
        }

        if ($aimDeviceNum -and $driveLetter) { break }
    }

    if (-not $aimDeviceNum) { throw "AIM device did not appear within 45 s." }
    if (-not $driveLetter)  {
        $allNew = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveLetter -notin $lettersBefore } |
                  Format-Table DriveLetter, FileSystem, @{n='SizeGB';e={[int]($_.Size/1GB)}}, FileSystemLabel -AutoSize | Out-String
        throw "No NTFS >50 GB drive letter appeared. New volumes seen: $allNew"
    }
    Ok "Mounted: AIM device $aimDeviceNum, NTFS at $driveLetter"

    # -----------------------------------------------------------------------
    # 8. Robocopy the target artefacts off the mounted volume
    # -----------------------------------------------------------------------
    # /b = backup mode uses SeBackupPrivilege to bypass ACLs on protected files.
    # Requires elevated PowerShell, verified in step 1.
    # We call robocopy ONCE PER FILE. Multi file /b calls silently fail on
    # heavily ACL'd files (SYSTEM, SOFTWARE, NTUSER.DAT, UsrClass.dat) even
    # when single file calls succeed. Per file loop matches the pattern
    # confirmed to work in isolation.
    $script:roboOpts = @('/b','/copy:DAT','/r:1','/w:1','/nfl','/ndl','/np','/njh','/njs')

    function Copy-OneFile {
        param([string]$SrcDir, [string]$File, [string]$DstDir)
        # Use script:roboOpts explicitly so scope lookup is unambiguous.
        # Redirect errors so a native command hiccup doesn't kill the script.
        $null = & robocopy $SrcDir $DstDir $File @script:roboOpts 2>&1
        $code = $LASTEXITCODE
        $dstPath = Join-Path $DstDir $File
        # Use .NET FileInfo directly. Works for hidden/system files, doesn't
        # go through the PowerShell provider layer that mishandles them.
        $fi = New-Object System.IO.FileInfo $dstPath
        if ($fi.Exists) {
            Write-Host ("  ok   {0,-58} {1,12:N0} bytes (exit {2})" -f $File, $fi.Length, $code)
            return $true
        } else {
            Write-Host ("  FAIL {0,-58} (exit {1})" -f $File, $code) -ForegroundColor Red
            return $false
        }
    }

    Info "Copying Windows\Prefetch\ (recursive)"
    robocopy "$driveLetter\Windows\Prefetch" $outDirs.prefetch '/e' @roboOpts | Out-Null
    $pfCount = @(Get-ChildItem $outDirs.prefetch -File -ErrorAction SilentlyContinue).Count
    Write-Host "  ok  Prefetch folder ($pfCount files, exit $LASTEXITCODE)"

    Info "Copying 5 event log channels"
    $evtxSrc = "$driveLetter\Windows\System32\winevt\Logs"
    foreach ($f in @('Security.evtx','System.evtx','Application.evtx',
                     'Microsoft-Windows-DriverFrameworks-UserMode%4Operational.evtx',
                     'Microsoft-Windows-Partition%4Diagnostic.evtx')) {
        Copy-OneFile $evtxSrc $f $outDirs.eventLogs | Out-Null
    }

    Info "Copying user hives (NTUSER.DAT and UsrClass.dat + transaction logs)"
    $userRoot = "$driveLetter\Users\$GuestUser"
    foreach ($f in @('NTUSER.DAT','NTUSER.DAT.LOG1','NTUSER.DAT.LOG2')) {
        Copy-OneFile $userRoot $f $outDirs.shellbags | Out-Null
    }
    $usrClassSrc = "$userRoot\AppData\Local\Microsoft\Windows"
    foreach ($f in @('UsrClass.dat','UsrClass.dat.LOG1','UsrClass.dat.LOG2')) {
        Copy-OneFile $usrClassSrc $f $outDirs.shellbags | Out-Null
    }

    Info "Copying system hives (SYSTEM, SOFTWARE) and Amcache.hve"
    foreach ($f in @('SYSTEM','SOFTWARE')) {
        Copy-OneFile "$driveLetter\Windows\System32\config" $f $outDirs.supporting | Out-Null
    }
    Copy-OneFile "$driveLetter\Windows\AppCompat\Programs" 'Amcache.hve' $outDirs.supporting | Out-Null
}
finally {
    # -----------------------------------------------------------------------
    # 9. Always dismount, even on error
    # -----------------------------------------------------------------------
    Info "Dismounting AIM device"
    if ($aimDeviceNum) {
        & $AimCli --dismount=$aimDeviceNum --force 2>&1 | Out-Null
    } else {
        & $AimCli --dismount --force 2>&1 | Out-Null
    }
    Start-Sleep -Seconds 2

    # The blocking aim_cli mount process exits when its mount goes away.
    # Kill it if still alive after grace period.
    if ($aimMountProc -and -not $aimMountProc.HasExited) {
        Stop-Process -Id $aimMountProc.Id -Force -ErrorAction SilentlyContinue
    }
    # Clean up log files
    Remove-Item $aimLog, "$aimLog.err" -Force -ErrorAction SilentlyContinue

    # Verify no AIM devices left
    $finalList = & $AimCli --list 2>&1 | Out-String
    if ($finalList -match 'Device number') {
        Warn "AIM devices still present after dismount attempt:`n$finalList"
    }
}

# ============================================================================
# 10. SHA 256 manifest across all extracted files
# ============================================================================
Info "Computing SHA 256 manifest"
$manifestPath = Join-Path $outDirs.supporting 'acquisition_manifest.csv'
$allFiles = @()
foreach ($d in $outDirs.Values) {
    # -Force so hidden hive files (NTUSER.DAT, UsrClass.dat, LOG1/LOG2) are counted
    $allFiles += Get-ChildItem -LiteralPath $d -Recurse -File -Force -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -ne 'acquisition_manifest.csv' }
}
if ($allFiles.Count -gt 0) {
    $allFiles | Get-FileHash -Algorithm SHA256 |
        Select-Object Algorithm, Hash, Path, @{n='SizeBytes';e={(Get-Item -LiteralPath $_.Path).Length}} |
        Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8
}

# ============================================================================
# 11. Summary
# ============================================================================
$totalBytes = ($allFiles | Measure-Object Length -Sum).Sum
Ok "$runId acquisition complete"
Write-Host "  Snapshot : $snapshotName ($vmdkFile)"
Write-Host "  Mount    : AIM device $aimDeviceNum at $driveLetter (dismounted)"
Write-Host "  Files    : $($allFiles.Count) ($([math]::Round($totalBytes / 1MB, 2)) MB total)"
Write-Host "  Manifest : $manifestPath"
Write-Host ''
Write-Host "Landing zones:" -ForegroundColor Yellow
foreach ($k in $outDirs.Keys) {
    $files = @(Get-ChildItem -LiteralPath $outDirs[$k] -Recurse -File -Force -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -ne 'acquisition_manifest.csv' })
    Write-Host ("  {0,-10} {1,5} files -> {2}" -f $k, $files.Count, $outDirs[$k])
}
Write-Host ("  {0,-10} {1,5}       -> {2}" -f 'evaluation', '(dir)', $evalDir)
