<#
.SYNOPSIS
Post rename cleanup for the 2026-08-17 naming scheme rewrite.

.DESCRIPTION
Moves scenarios\scenario_1\run_1\artefacts and evaluation up one level to
scenarios\scenario_1\ (flat single-run layout per the new naming scheme),
then removes the empty run_1 folder. Also patches the acquisition manifest
Path column in place so downstream lookups match the new layout.

Prerequisites:
- The 2026-08-17 file rewrites are already on disk (log_action.ps1,
  acquire_artefacts.ps1, .gitignore, README.md, vm_testbed.md, catalogue.md
  all updated). If you have not committed them yet, that is fine.
- VMware snapshots have OR have not been renamed. This script does not touch
  the VM. Rename them separately in VMware Snapshot Manager.

Run once from the repo root or anywhere. No arguments.

Author: Cleanup helper generated 2026-08-17
#>

$ErrorActionPreference = 'Stop'

$repo = 'D:\UOW\SEM3\msc-diss-7csef001w'
$src  = Join-Path $repo 'scenarios\scenario_1\run_1'
$dst  = Join-Path $repo 'scenarios\scenario_1'

function Info($m) { Write-Host "[Cleanup] $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "[Cleanup] $m" -ForegroundColor Green }
function Warn($m) { Write-Warning $m }

Info "Repo: $repo"

if (-not (Test-Path $src)) {
    Warn "Source $src does not exist. Nothing to move. Already migrated?"
    return
}

# ---------------------------------------------------------------------------
# 1. Move artefacts folder up
# ---------------------------------------------------------------------------
$srcArt = Join-Path $src 'artefacts'
$dstArt = Join-Path $dst 'artefacts'
if (Test-Path $srcArt) {
    if (Test-Path $dstArt) {
        throw "Destination $dstArt already exists. Refusing to overwrite. Inspect and delete manually first."
    }
    Info "Moving artefacts up..."
    Move-Item -LiteralPath $srcArt -Destination $dstArt -Force
    Ok "  artefacts moved"
}

# ---------------------------------------------------------------------------
# 2. Move evaluation folder up (may be empty)
# ---------------------------------------------------------------------------
$srcEval = Join-Path $src 'evaluation'
$dstEval = Join-Path $dst 'evaluation'
if (Test-Path $srcEval) {
    if (Test-Path $dstEval) {
        throw "Destination $dstEval already exists. Refusing to overwrite."
    }
    Info "Moving evaluation up..."
    Move-Item -LiteralPath $srcEval -Destination $dstEval -Force
    Ok "  evaluation moved"
} else {
    # Ensure destination exists even if source was empty
    if (-not (Test-Path $dstEval)) {
        New-Item -ItemType Directory -Path $dstEval -Force | Out-Null
        Info "  created empty evaluation folder"
    }
}

# ---------------------------------------------------------------------------
# 3. Remove empty run_1 folder
# ---------------------------------------------------------------------------
$leftover = Get-ChildItem -LiteralPath $src -Force -ErrorAction SilentlyContinue
if ($leftover) {
    Warn "run_1 still contains items after moves. Leaving in place for manual review:"
    $leftover | Format-Table Name, Length, Mode -AutoSize
} else {
    Info "Removing empty run_1..."
    Remove-Item -LiteralPath $src -Recurse -Force
    Ok "  run_1 removed"
}

# ---------------------------------------------------------------------------
# 4. Patch acquisition manifest Path column
# The hashes are unaffected by the move; only the Path strings change.
# ---------------------------------------------------------------------------
$manifest = Join-Path $dst 'artefacts\supporting\acquisition_manifest.csv'
if (Test-Path $manifest) {
    Info "Patching manifest Path column: scenario_1\\run_1\\ -> scenario_1\\"
    $content = Get-Content -LiteralPath $manifest -Raw
    $before  = ([regex]::Matches($content, [regex]::Escape('scenario_1\run_1\'))).Count
    $content = $content -replace [regex]::Escape('scenario_1\run_1\'), 'scenario_1\'
    Set-Content -LiteralPath $manifest -Value $content -NoNewline
    Ok "  patched $before path entries in $manifest"
} else {
    Warn "Manifest not found at $manifest. Skipping patch."
}

Write-Host ''
Ok "Cleanup done."
Write-Host ''
Write-Host "Next steps (do in this order):" -ForegroundColor Yellow
Write-Host "  1. VMware snapshots should already be renamed to (verify in Snapshot Manager):"
Write-Host "       baseline_candidate       (was B00-CANDIDATE-W11-25H2-26200.6584-20260717)"
Write-Host "       baseline_pre_scenarios   (was S00-UNIVERSAL-PRE)"
Write-Host "       scenario1_post           (was S01-R01-POST)"
Write-Host "  2. Verify the .vmsd contains the new snapshot name:"
Write-Host "       Select-String -Path 'D:\UOW\SEM3\DISS-Win11-Testbed-VM\*.vmsd' -Pattern 'scenario1_post'"
Write-Host "  3. Copy the guest ground-truth CSV out and rename it:"
Write-Host "       (from guest) rename C:\DISS_TESTDATA\S01-R01-action-log.csv to scenario1_actions.csv"
Write-Host "       (on host)    save to $dst\evaluation\ground_truth.csv"
Write-Host "  4. Commit the rewrite from your normal PowerShell:"
Write-Host "       cd $repo"
Write-Host "       git add -A"
Write-Host "       git status  # review the rename+content changes"
Write-Host "       git commit -m 'Rename to scenario{N}_post naming scheme; flatten single-run folders'"
Write-Host ''
Write-Host "If you want the manifest regenerated from scratch (rehash, not just Path patch):"
Write-Host "  Close VMware entirely first, then:"
Write-Host "  cd $repo\scripts\scenarios"
Write-Host "  .\acquire_artefacts.ps1 -Scenario 1"
Write-Host "  # This re-mounts scenario1_post, re-copies the 433 files, re-hashes."
Write-Host "  # Takes ~90 s. Result should exactly match the current manifest (same files)."
