<#
.SYNOPSIS
Precondition setup for Scenario 3 (Nested folder navigation).

.DESCRIPTION
Creates the nested folder tree used by Scenario 3 inside the guest VM. The
tree is created via New-Item (PowerShell), NOT Explorer, so no ShellBag
entries are written for these folders during setup. Only the deliberate
A02 to A07 Explorer clicks performed during the scenario should produce
ShellBag rows in UsrClass.dat / NTUSER.DAT.

Tree layout (all lowercase snake_case per naming scheme 2026-08-17):

    C:\DISS_TESTDATA\scenario3_nav\
        level1_a\
            level2_a\
                level3_a\
                    level4_a\
                        level5_a\
        level1_b\   (negative control, never browse during A01..A08)

.NOTES
Run inside the guest (DISS-Win11-25H2-Testbed VM) as user 'dfanalyst',
BEFORE loading the Log-Action helper and BEFORE opening File Explorer:

    powershell -ExecutionPolicy Bypass -File .\scenario3_prepare_tree.ps1

Or paste the whole file into a PowerShell window. Non-elevated PowerShell
is fine; the tree lives under C:\DISS_TESTDATA which is world-writable in
this testbed.

Author: Syed Muhammad Saqlain Abbas (W21634541)
Repo:   github.com/dx7er/msc-diss-7csef001w
Module: 7CSEF001W.2 MSc Cyber Security & Forensics Project
#>

$root = 'C:\DISS_TESTDATA\scenario3_nav'

New-Item -ItemType Directory -Force -Path "$root\level1_a\level2_a\level3_a\level4_a\level5_a" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\level1_b" | Out-Null

Write-Host "Scenario 3 tree created under $root"
Get-ChildItem -Recurse $root | Select-Object FullName
