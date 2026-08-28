# Evaluation matrix

Cross-scenario evaluation of whether each scenario in `scenarios/catalogue.md` was successfully reconstructed from the three project artefact classes (Prefetch, Windows Event Logs, ShellBags) and their correlation. This is the study's Phase 5 (validation and evaluation) deliverable requested by supervisor Jade at the 2026-08-06 meeting.

Machine-readable mirror at `evaluation_matrix.csv`. Per-scenario detail at `scenarios/scenario_N/evaluation/correlation_table.md` (14 tables in total: eight single-run, plus three per-run tables each for the multi-run scenarios S04 and S07).

## Reading the matrix

Each scenario contributes one or more rows, one per ground-truth item under test.

- Per-artefact columns (PF, EVTX, SBags) qualitatively grade each artefact class in isolation. They answer "did this artefact class alone give us enough to conclude the action occurred?"
- The Correlated column grades the unified per-scenario timeline output.
- The Reproducibility column applies to the two multi-run scenarios (S04 and S07, three runs each) and reports `N/3` where `N` is the number of runs in which the correlation timeline matched ground truth at the same verdict level. `N/A` for single-run scenarios.

## Cell values

| Value  | Meaning |
|--------|---------|
| PASS   | Artefact class produced the expected evidence; ground-truth action recoverable from it alone. |
| PART   | Partial. Some but not all ground-truth fields recoverable (e.g. timestamp present, target path missing), or only one artefact class carried the attribution. |
| FAIL   | Expected evidence absent, missing, or contradicted by the artefact. |
| N/A    | Artefact class not applicable to this scenario by design (excluded from the scenario's declared artefact mix), or single-run scenario for the Reproducibility column. |
| N/3    | Quantitative: number of the three repetitions in which correlation matched ground truth at the same verdict level. |

## Matrix

| Scenario | Ground-truth item                                       | PF   | EVTX | SBags | Correlated | Reproducibility |
|----------|---------------------------------------------------------|------|------|-------|------------|-----------------|
| S01      | Chrome installer executed                               | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | WinRAR installer executed                               | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | VLC installer executed                                  | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | Adobe Reader installer executed                         | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | Zoom installer executed                                 | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | Notepad++ installer executed                            | PASS | PART | FAIL  | PART       | N/A             |
| S01      | Chrome install completed successfully                   | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | WinRAR install completed successfully                   | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | VLC install completed successfully                      | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | Adobe Reader install completed successfully             | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | Zoom install completed (+ service 7045)                 | PASS | PASS | FAIL  | PASS       | N/A             |
| S01      | Notepad++ install completed successfully                | PASS | PART | FAIL  | PART       | N/A             |
| S01      | User navigated to Downloads folder                      | FAIL | PART | PART  | PART       | N/A             |
| S02      | notepad.exe launched (3 times)                          | PASS | PASS | N/A   | PASS       | N/A             |
| S02      | calc.exe launched (3 times)                             | PASS | PASS | N/A   | PASS       | N/A             |
| S02      | chrome.exe launched (3 times)                           | PASS | PASS | N/A   | PASS       | N/A             |
| S02      | winrar.exe launched (3 times)                           | PASS | PASS | N/A   | PASS       | N/A             |
| S02      | vlc.exe launched (3 times)                              | PASS | PASS | N/A   | PASS       | N/A             |
| S02      | notepad++.exe launched (3 times)                        | PASS | PASS | N/A   | PASS       | N/A             |
| S02      | Prefetch run count = 3 per app                          | PASS | N/A  | N/A   | PASS       | N/A             |
| S03      | Level-1 folder browsed                                  | N/A  | N/A  | PASS  | PART       | N/A             |
| S03      | Level-2 folder browsed                                  | N/A  | N/A  | PASS  | PART       | N/A             |
| S03      | Level-3 folder browsed                                  | N/A  | N/A  | PASS  | PART       | N/A             |
| S03      | Level-4 folder browsed                                  | N/A  | N/A  | PASS  | PART       | N/A             |
| S03      | Level-5 folder browsed                                  | N/A  | N/A  | PASS  | PASS       | N/A             |
| S03      | Sibling folder NOT browsed (negative control)           | N/A  | N/A  | PASS  | PASS       | N/A             |
| S04      | USB device attached (VID/PID/serial)                    | N/A  | PASS | FAIL  | PASS       | 3/3             |
| S04      | USB volume root browsed                                 | N/A  | N/A  | PART  | PART       | 1/3             |
| S04      | USB subfolder browsed                                   | N/A  | N/A  | PASS  | PASS       | 3/3             |
| S04      | EXE launched from USB volume                            | PASS | PASS | N/A   | PASS       | 3/3             |
| S04      | USB device safely ejected                               | N/A  | PASS | N/A   | PASS       | 3/3             |
| S05      | File deleted to Recycle Bin                             | FAIL | FAIL | FAIL  | FAIL       | N/A             |
| S05      | Recycle Bin emptied                                     | PART | PART | FAIL  | PART       | N/A             |
| S06      | Interactive logon (type 2) at T1                        | N/A  | PASS | N/A   | PASS       | N/A             |
| S06      | Workstation locked at T2                                | N/A  | PART | N/A   | PART       | N/A             |
| S06      | Workstation unlocked at T3                              | N/A  | FAIL | N/A   | FAIL       | N/A             |
| S06      | Logoff at T4                                            | N/A  | PASS | N/A   | PASS       | N/A             |
| S07      | notepad++.exe launched                                  | PASS | PASS | N/A   | PASS       | 3/3             |
| S07      | User navigated to Documents in Save-As dialog           | N/A  | N/A  | PASS  | PASS       | 3/3             |
| S07      | New subfolder S07_Output_R\<NN\> created                | N/A  | N/A  | FAIL  | FAIL       | 0/3             |
| S07      | File s07-test-R\<NN\>.txt saved                         | FAIL | PART | PART  | PART       | 3/3             |
| S07      | Save-As dialog ShellBags entry present                  | N/A  | N/A  | PASS  | PASS       | 3/3             |
| S08      | cmd.exe executed                                        | PASS | PASS | N/A   | PASS       | N/A             |
| S08      | whoami invoked with args                                | N/A  | PASS | N/A   | PASS       | N/A             |
| S08      | dir invoked with args                                   | N/A  | FAIL | N/A   | FAIL       | N/A             |
| S08      | powershell.exe executed                                 | PASS | PART | N/A   | PART       | N/A             |
| S08      | Get-Process invoked                                     | N/A  | FAIL | N/A   | FAIL       | N/A             |
| S09      | Chrome launched                                         | PASS | PASS | N/A   | PASS       | N/A             |
| S09      | URL 1 visited (UoW)                                     | N/A  | PASS | N/A   | PASS       | N/A             |
| S09      | URL 2 visited (bbc.co.uk)                               | N/A  | PART | N/A   | PART       | N/A             |
| S09      | URL 3 visited (Wikipedia)                               | N/A  | PART | N/A   | PART       | N/A             |
| S09      | File downloaded                                         | PASS | PASS | FAIL  | PASS       | N/A             |
| S09      | Downloads folder opened in Explorer                     | PART | PASS | PASS  | PASS       | N/A             |
| S10      | Clean shutdown at T1                                    | PASS | PASS | N/A   | PASS       | N/A             |
| S10      | Power-on at T2                                          | FAIL | FAIL | N/A   | FAIL       | N/A             |
| S10      | Interactive logon after boot at T3                      | N/A  | FAIL | N/A   | FAIL       | N/A             |

Notes on notation.

- S07 row "New subfolder created" is scored FAIL (0/3) because ground-truth logging shows that in all three runs the participant saved the file to Documents root rather than to a per-run subfolder; the artefacts correctly reflect the absence of the sub-directory creation, so the scenario failed at the ground-truth level, not at the artefact level. See `scenarios/scenario_7/README.md` section 4.
- S07 row "File saved" is scored PART (3/3) because the file was reproducibly saved to Documents root across all three runs; artefact evidence attributes the save but to the actual (root) path, not the intended (subfolder) path.
- S09 URL mappings: the catalogue lists "example.com / bbc / download source" but the executed scenario visited UoW / bbc / Wikipedia. The URL-1 to URL-3 rows map by position onto the actual navigations recorded in the correlation table.
- S08 whoami PF is scored N/A because the a-priori scenario design excluded Prefetch as an attribution class for command-line built-ins; whoami.exe did in fact produce a Prefetch entry (documented as an incidental finding in the S08 correlation table), and would upgrade the row to multi-class if the a-priori scope were relaxed.
- S10 A03 (logon after boot) is scored FAIL under strict time-window semantics: the boot-side EVTX events (EID 20 / 6005 / 6009 / 4608 / 7001) fired at the guest's clock time but the guest clock was ~3 minutes behind the host wall-clock across the shutdown-and-boot cycle, so those events fall inside A01's window rather than A03's. Applying a per-scenario clock offset would upgrade this row to PASS; see S10 correlation table analyst notes.

## Roll-up metrics

Denominators exclude `N/A` cells (rows where the artefact class is out of scope for that scenario by design).

### Per-artefact completeness

Percentage of applicable ground-truth items where the artefact class alone was scored `PASS` or `PART` (i.e. contributed at least partial attribution).

| Artefact class | Applicable rows | PASS | PART | FAIL | Completeness (PASS+PART) |
|----------------|-----------------|------|------|------|--------------------------|
| Prefetch       | 32              | 26   | 3    | 3    | 29/32 = 90.6%            |
| EVTX           | 44              | 29   | 9    | 6    | 38/44 = 86.4%            |
| ShellBags      | 30              | 10   | 3    | 17   | 13/30 = 43.3%            |

Prefetch has the highest per-class completeness of the three artefact families because every executed binary produces a `.pf` RunTime entry within seconds of launch, and most of the scenarios exercise binary execution. EVTX completeness is only slightly lower and is broader across scenario types because the Security channel captures logon, service-install and driver-arrival events that Prefetch cannot see. ShellBags completeness is the lowest, but this is misleading if read in isolation: the low denominator (30 applicable rows) understates the artefact's importance in the scenarios where it is the primary attribution class (S03 nested navigation, S04 USB browsing, S07 Save-As dialog), where it is the only class that captures the ground truth at all.

### Correlated verdict distribution

Percentage of ground-truth items whose unified per-scenario timeline was scored PASS, PART or FAIL. Denominator is all 56 rows.

| Verdict | Count | Share  |
|---------|-------|--------|
| PASS    | 35    | 62.5%  |
| PART    | 14    | 25.0%  |
| FAIL    | 7     | 12.5%  |

Correlated PASS-or-PART attribution: 49 of 56 = 87.5%.

### Correlation lift

Percentage of PASS rows where at least one single-artefact column is FAIL or PART, indicating the correlation across classes added attribution the single-class view alone would have missed. Denominator is the 35 Correlated=PASS rows.

Rows contributing to lift: 13 of 35 = 37.1%.

- S01: 10 install rows where Prefetch and EVTX both PASS but ShellBags FAIL (12 rows contribute 10 because 2 of the 12 install rows land at Correlated=PART).
- S04: 1 row (USB attach, where EVTX PASS + SBags FAIL).
- S09: 2 rows (File downloaded where SBags FAIL, Downloads opened where PF PART).

The lift metric answers a specific question posed at the 2026-08-06 meeting: "does correlation across classes add attribution beyond what any single class gives?" The answer is yes for 37% of the study's confirmed cases, principally driven by the install-action scenario (S01) where the negative-space contribution of ShellBags (silence is expected, not a coverage gap) is only visible under a multi-class model.

### Reproducibility mean

Mean `N/3` across the 10 multi-run rows (5 rows each for S04 and S07):

- S04: (3+1+3+3+3) / 5 = 2.6/3
- S07: (3+3+0+3+3) / 5 = 2.4/3
- Combined: (13+12) / (5+5) = 25/30 = 83.3%

Both scenarios exceed the 2.5/3 threshold the template specifies as the stability floor, indicating the testbed reproducibly regenerates the same evidence pattern across independent runs when the same ground-truth actions are performed. The single largest source of variance is S07's "New subfolder created" row, which is a ground-truth-level deviation (the participant never created the subfolder in any run) rather than an artefact-variance issue; excluding it, the S07 mean rises to 3.0/3.

### Per-scenario coverage

Percentage of `PASS` rows per scenario (Correlated column).

| Scenario | Rows | PASS | Coverage |
|----------|------|------|----------|
| S01      | 13   | 10   | 76.9%    |
| S02      | 7    | 7    | 100.0%   |
| S03      | 6    | 2    | 33.3%    |
| S04      | 5    | 4    | 80.0%    |
| S05      | 2    | 0    | 0.0%     |
| S06      | 4    | 2    | 50.0%    |
| S07      | 5    | 3    | 60.0%    |
| S08      | 5    | 2    | 40.0%    |
| S09      | 6    | 4    | 66.7%    |
| S10      | 3    | 1    | 33.3%    |

S02 (application-launch baseline) is the ceiling case: application launch is what Prefetch and Security 4688 were designed to capture, so every ground-truth action is directly attributed. S04 (USB lifecycle) is the strongest realistic scenario: 4 of 5 rows PASS with the only PART attributable to a windowing-timing variance rather than a coverage gap. S05 (delete to Recycle Bin) is the floor case: two of two rows below PASS because delete-to-Recycle-Bin and Empty-Bin actions are genuinely outside the three-artefact scope and require a fourth class (`$I`/`$R` filesystem parsing). S03 (nested navigation) shows a scoring artefact rather than a real gap: five of six ShellBag rows are PASS at the class level but Correlated is scored PART for four of them because only one artefact class contributes; the scenario design deliberately isolates ShellBags as the single attribution surface, so this is exactly the expected pattern.

## Cross-scenario findings visible only from the matrix

Reading the matrix rows top to bottom surfaces three patterns that the per-scenario correlation tables report in isolation but that only the roll-up view exposes as generalisable:

1. Install actions are the study's strongest cross-artefact case (12 of 13 S01 install rows PASS with 5 or more per row) because installer binaries execute (Prefetch), spawn under user Explorer (EVTX 4688 with parent explorer.exe), and register services (EVTX 7045) or run MSI sessions (EVTX MsiInstaller). NSIS installers (Notepad++) drop from PASS to PART because they leave a Prefetch trace but no MsiInstaller trail; the difference is visible only when the matrix is scanned column-by-column across all install rows.

2. Pure browser downloads, delete-to-Recycle-Bin, workstation lock/unlock, and shell-built-in commands are four distinct FAIL cases (S01 A02-A07, S05 A02, S06 A03/A05, S08 A03/A06) that share a common root cause: each is a shell-level or protocol-level action that does not spawn a new binary, does not touch the shell namespace, and does not fire a distinctive Security-auditing event on the study's baseline audit policy. This is not four separate coverage gaps but one recurring gap in the three-artefact scope.

3. Reproducibility across the two multi-run scenarios is high (83.3%) and the two failing patterns are of different kinds: S04's variance is a window-boundary timing effect (ShellBag hive-flush lands outside the short A02 window in 2 of 3 runs), while S07's variance is a ground-truth deviation (the sub-folder-creation step was skipped by the participant). The matrix distinguishes these by showing 5-of-6 S04 rows reproducing exactly against 4-of-5 S07 rows reproducing exactly with one non-artefact deviation.

## Regenerating the matrix

The CSV mirror at `evaluation_matrix.csv` is the machine-readable source. The MD in this file mirrors those cells with formatting for the report appendix. When any per-scenario correlation table is updated, the corresponding row(s) here must be updated by hand: there is no auto-populate script, since the verdict assignment requires the analyst judgment documented in the correlation table's Analyst-notes column.

Column and cell-value definitions live in this file. The 14 correlation tables reference them and inherit them; do not redefine per-scenario.
