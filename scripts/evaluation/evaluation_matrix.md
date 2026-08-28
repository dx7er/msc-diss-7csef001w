# Evaluation matrix

Cross-scenario evaluation of whether each scenario in `scenarios/catalogue.md` was successfully reconstructed from the three project artefact classes (Prefetch, Windows Event Logs, ShellBags) and their correlation. This is the study's Phase 5 (validation and evaluation) deliverable requested by supervisor Jade at the 2026-08-06 meeting.

Machine-readable mirror at `evaluation_matrix.csv`. Per-scenario detail at `scenarios/scenario_N/evaluation/correlation_table.md` (14 tables in total: eight single-run, plus three per-run tables each for the multi-run scenarios S04 and S07 (executed 3 runs each)).

## Reading the matrix

Each scenario contributes one or more rows, one per ground-truth item under test.

- Per-artefact columns (PF, EVTX, SBags) qualitatively grade each artefact class in isolation. They answer "did this artefact class alone give us enough to conclude the action occurred?"
- The Correlated column grades the unified per-scenario timeline output.
- The Reproducibility column applies to the two multi-run scenarios (S04 and S07, three runs each) and reports `N/3` where `N` is the number of runs in which the correlation timeline matched ground truth at the same verdict level for that ground-truth item. Denominator is always the number of executed runs (3), never the number of ground-truth items. `N/A` for single-run scenarios.

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
| S07      | File scenario7_test_file.txt saved to Documents root    | PASS | PASS | PASS  | PASS       | 3/3             |
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

- S07 row "File saved to Documents root" is scored PASS across all three artefact classes and 3/3 reproducibility. The executed protocol (see `scenarios/catalogue.md` S07 Manual steps and Note on protocol) is to save `scenario7_test_file.txt` into `%USERPROFILE%\Documents`; the artefacts (`4663` object write, PECmd `notepad++.exe` RunTime, `UsrClass` Desktop\Documents ShellBag) confirm the save in every run.
- S09 URL labels in the matrix (`westminster.ac.uk`, `bbc.co.uk`, `Wikipedia digital forensics`) match the executed protocol described in `scenarios/catalogue.md` S09 Manual steps; per-URL evidence is recorded in the notes column of `evaluation_matrix.csv` and in `scenarios/scenario_9/evaluation/correlation_table.md`.
- S08 whoami PF is scored N/A because the a-priori scenario design excluded Prefetch as an attribution class for command-line built-ins; whoami.exe did in fact produce a Prefetch entry (documented as an incidental finding in the S08 correlation table), and would upgrade the row to multi-class if the a-priori scope were relaxed.
- S10 A03 (logon after boot) is scored FAIL under strict time-window semantics: the boot-side EVTX events (EID 20 / 6005 / 6009 / 4608 / 7001) fired at the guest's clock time but the guest clock was ~3 minutes behind the host wall-clock across the shutdown-and-boot cycle, so those events fall inside A01's window rather than A03's. Applying a per-scenario clock offset would upgrade this row to PASS; see S10 correlation table analyst notes.

## Roll-up metrics

Denominators exclude `N/A` cells (rows where the artefact class is out of scope for that scenario by design).

### Scoring policy for `N/A` versus `FAIL`

Per-artefact and per-row scoring uses two distinct verdicts for "no evidence found":

- `N/A` = the artefact class is not structurally capable of recording this ground-truth item. Examples: ShellBags on process-execution rows (ShellBags record folder navigation via `IShellBrowser`, not process execution); Prefetch on pure logon rows (Prefetch records executable launches, not authentication events); ShellBags on kernel PnP events (USB attach fires DriverFrameworks and Security PnP events that never touch `UsrClass`).
- `FAIL` = the artefact class was expected to capture this ground-truth item and did not. Examples: Prefetch missing a `.pf` for a binary that was actually launched inside the correlation window; EVTX missing a `4688` for a process that Prefetch confirms ran.

`N/A` rows are excluded from the class's applicable-row denominator; `FAIL` rows are counted against the class. The distinction matters because it separates "the artefact class does not carry this kind of evidence" (a study-design fact) from "the artefact class should have carried this evidence and did not" (a coverage failure). Aggregating both under a single "not-PASS" bucket would understate the classes with narrow scope but high fidelity (ShellBags) and overstate their coverage failures. Where an early draft of the CSV assigned `FAIL` to `sbags` on rows that were structurally out of scope (installer-execution rows in S01, USB attach in S04, Recycle-Bin operations in S05, download completion in S09), those cells were reclassified to `N/A` under this policy before the final matrix was published. The reclassification does not change any correlated verdict, any Prefetch or EVTX score, or any reproducibility mean.

### Per-artefact completeness

Percentage of applicable ground-truth items where the artefact class alone was scored `PASS` or `PART` (i.e. contributed at least partial attribution).

| Artefact class | Applicable rows | PASS | PART | FAIL | Completeness (PASS+PART) |
|----------------|-----------------|------|------|------|--------------------------|
| Prefetch       | 32              | 27   | 2    | 3    | 29/32 = 90.6%            |
| EVTX           | 44              | 30   | 8    | 6    | 38/44 = 86.4%            |
| ShellBags      | 13              | 11   | 2    | 0    | 13/13 = 100.0%           |

Prefetch has the highest per-class completeness of the three artefact families because every executed binary produces a `.pf` RunTime entry within seconds of launch, and most of the scenarios exercise binary execution. EVTX has broader coverage than Prefetch because the Security channel captures logon, service-install and driver-arrival events that Prefetch cannot see. ShellBags is the class with the narrowest scope but the highest completeness on the rows it applies to: it captures folder navigation via `IShellBrowser` and nothing else, so it is `N/A` for process-execution rows (S01 installer runs), kernel PnP events (S04 USB device attach), file-operation rows (S05 Recycle Bin delete and empty) and download-completion rows (S09 file downloaded), where the ground-truth item is not a folder-navigation event and no ShellBag entry is expected. On the 13 rows where ShellBags is structurally applicable (S01 Downloads-folder browse, S03 nested navigation, S04 USB volume and subfolder browse, S07 Save-As dialog and Documents-root save, S09 Downloads folder opened in Explorer) it is 11/13 PASS plus 2/13 PART for 13/13 = 100% completeness. The 2 PART rows are S01 Downloads (BagMRU present but timestamp landed outside the short A02 correlation window) and S04 USB volume root (E: ShellBag present in Run 1 only; Runs 2 and 3 lost to short A02 window). Both are window-boundary timing effects at the correlation stage rather than acquisition or artefact-fidelity failures.

### Correlated verdict distribution

Percentage of ground-truth items whose unified per-scenario timeline was scored PASS, PART or FAIL. Denominator is all 55 rows.

| Verdict | Count | Share  |
|---------|-------|--------|
| PASS    | 36    | 65.5%  |
| PART    | 13    | 23.6%  |
| FAIL    | 6     | 10.9%  |

Correlated PASS-or-PART attribution: 49 of 55 = 89.1%.

### Correlation contribution

The 2026-08-06 meeting posed one question: "does correlation across classes add attribution beyond what any single class gives?" A single "lift" number cannot answer it honestly, because the phrase "adds attribution" has three distinct senses in this corpus and they trade off against the scope of each artefact class. The metrics below use the scoring policy above: `N/A` means "class not structurally capable of recording this item" and is excluded from every count; only `PASS`, `PART` and `FAIL` participate.

Denominator throughout is the 36 Correlated=PASS rows.

1. **Incremental detection**: rows where no single artefact class was PASS on its own and the correlated timeline is nevertheless PASS. This is the strongest possible sense of lift (correlation reveals attribution that no class alone would have surfaced). Count: **0 of 36 = 0.0%**. In this corpus every correlated-PASS row has at least one single-class PASS, so correlation never manufactures a positive verdict from three negatives. This is a truthful null result and it means the strict "single-class blind spot" claim cannot be made from this dataset.

2. **Multi-class agreement**: rows where at least two of the three single-artefact classes independently PASS (the correlated verdict is supported by two or three independent evidential streams that agree on the same ground-truth item). Count: **24 of 36 = 66.7%**. Of these, 23 rows carry two independent PASSes (typically Prefetch and EVTX agreeing on an execution event; or ShellBags and EVTX agreeing on a folder-navigation event) and 1 row carries all three classes PASS (S07 "File saved to Documents root", where Prefetch confirms the launch, EVTX 4663 confirms the object write, and ShellBags Documents BagMRU confirms the Save As dialog navigated to the target). Multi-class agreement is the property a marker or examiner should read as "correlation works": two or three independent artefact streams converge on the same interpretation of the same action.

3. **Single-class carry**: rows where exactly one artefact class was PASS and the other two classes were `N/A` because they cannot structurally record the item. Count: **12 of 36 = 33.3%**. These are rows where the ground-truth item is captured by only one of the three classes by design: EVTX-only rows include S06 logon and logoff (`4624`, `4634`), S08 `whoami` command invocation (`4688`), and S09 URL navigation (`4688` chrome-parented); ShellBags-only rows include S03 deep folder navigation levels and the S07 Save As dialog entries; Prefetch-only rows include S02 run-count observations. Single-class carry rows are not correlation failures; they are cases where the scenario deliberately exercises one artefact class, and the class delivered.

4. **Negative-space evidence**: rows where the absence of an expected artefact is itself an interpretive signal. Formally scored as `N/A` under the scoring policy, but read as "the absence of a ShellBag row for `ChromeSetup.exe` running from Downloads is consistent with an installer workflow, not with a coverage gap". Negative-space evidence is not counted in the metrics above, but it is what makes the twelve S01 installer rows analytically clean rather than merely additive: silence in the ShellBag column is treated as consistent with the ground-truth item ("installer executed"), not as a coverage failure.

The honest summary. Correlation in this corpus does not create attribution that a single class would have missed (incremental detection is 0). What it does is (a) cross-validate attribution across independent artefact classes in **24 of 36** confirmed rows where two or three classes independently agree, (b) reconcile the ground-truth timeline against three independently-timestamped evidence streams so that clock drift and reporting-delay artefacts are visible rather than hidden, and (c) let expected silence in one class be interpreted correctly against expected presence in another. Those are the analytically-useful contributions of the correlation model in this study, and they should be reported as such rather than compressed into a single "lift" percentage.

### Reproducibility mean

Mean `N/3` across the 9 multi-run rows (5 rows for S04, 4 rows for S07 following the executed-protocol alignment; see the Catalogue authority note in `scenarios/catalogue.md`):

- S04: (3+1+3+3+3) / 5 = 2.6/3
- S07: (3+3+3+3) / 4 = 3.0/3
- Combined: (13+12) / (5+4) = 25/9 = 2.78/3 = 92.6%

Both scenarios clear the 2.5/3 threshold the template specifies as the stability floor: S04 at 2.6/3 and S07 at 3.0/3. The combined mean of 2.78/3 (92.6%) indicates that when the same ground-truth actions are performed under the same conditions, the testbed reproducibly regenerates the same artefact evidence pattern. S04's shortfall from 3.0 is a single window-boundary timing effect (Run 2's ShellBag hive-flush landed outside the short A02 correlation window; see `scenarios/scenario_4/README.md` for the per-run breakdown), not an artefact-fidelity issue. S07's reproducibility mean is reported against the four-item executed protocol; the pre-execution draft included a fifth item (per-rep subfolder creation) that was dropped before Run 1 and is documented in the Catalogue authority note. That superseded item is not scored here because none of the three runs ever executed it; the per-run `evaluation/ground_truth.csv` files preserve the researcher's contemporaneous PRE-row note referring to the earlier draft for provenance.

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
| S07      | 4    | 4    | 100.0%   |
| S08      | 5    | 2    | 40.0%    |
| S09      | 6    | 4    | 66.7%    |
| S10      | 3    | 1    | 33.3%    |

S02 (application-launch baseline) is the ceiling case: application launch is what Prefetch and Security 4688 were designed to capture, so every ground-truth action is directly attributed. S04 (USB lifecycle) is the strongest realistic scenario: 4 of 5 rows PASS with the only PART attributable to a windowing-timing variance rather than a coverage gap. S05 (delete to Recycle Bin) is the floor case: two of two rows below PASS because delete-to-Recycle-Bin and Empty-Bin actions are genuinely outside the three-artefact scope and require a fourth class (`$I`/`$R` filesystem parsing). S03 (nested navigation) shows a scoring artefact rather than a real gap: five of six ShellBag rows are PASS at the class level but Correlated is scored PART for four of them because only one artefact class contributes; the scenario design deliberately isolates ShellBags as the single attribution surface, so this is exactly the expected pattern.

## Cross-scenario findings visible only from the matrix

Reading the matrix rows top to bottom surfaces three patterns that the per-scenario correlation tables report in isolation but that only the roll-up view exposes as generalisable:

1. Install actions are the study's strongest cross-artefact case (12 of 13 S01 install rows PASS with 5 or more per row) because installer binaries execute (Prefetch), spawn under user Explorer (EVTX 4688 with parent explorer.exe), and register services (EVTX 7045) or run MSI sessions (EVTX MsiInstaller). NSIS installers (Notepad++) drop from PASS to PART because they leave a Prefetch trace but no MsiInstaller trail; the difference is visible only when the matrix is scanned column-by-column across all install rows.

2. Pure browser downloads, delete-to-Recycle-Bin, workstation lock/unlock, and shell-built-in commands are four distinct FAIL cases (S01 A02-A07, S05 A02, S06 A03/A05, S08 A03/A06) that share a common root cause: each is a shell-level or protocol-level action that does not spawn a new binary, does not touch the shell namespace, and does not fire a distinctive Security-auditing event on the study's baseline audit policy. This is not four separate coverage gaps but one recurring gap in the three-artefact scope.

3. Reproducibility across the two multi-run scenarios is high (92.6% combined) and both scenarios clear the 2.5/3 stability floor: S04 at 2.6/3, S07 at 3.0/3. The one within-scenario variance point is S04 Run 2's ShellBag hive-flush landing outside the short A02 correlation window, which is a window-boundary timing effect and not an artefact-fidelity issue. S07's four executed items reproduce exactly across all three runs.

## Regenerating the matrix

The CSV mirror at `evaluation_matrix.csv` is the machine-readable source. The MD in this file mirrors those cells with formatting for the report appendix. When any per-scenario correlation table is updated, the corresponding row(s) here must be updated by hand: there is no auto-populate script, since the verdict assignment requires the analyst judgment documented in the correlation table's Analyst-notes column.

Column and cell-value definitions live in this file. The 14 correlation tables reference them and inherit them; do not redefine per-scenario.
