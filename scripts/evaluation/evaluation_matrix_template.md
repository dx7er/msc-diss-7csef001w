# Evaluation Matrix

Judges whether each scenario in `scenarios/scenario-catalogue.md` was successfully reconstructed from the three artefact classes and their correlation, per Jade's 2026-08-06 requirement.

The matrix is the primary Phase 5 (validation and evaluation) deliverable. It is populated after Phase 4 (extraction and correlation) completes.

## Reading the matrix

Each scenario has one or more rows, one per ground-truth item under test.

- **Per-artefact columns (PF, EVTX, SBags):** qualitative pass/fail for each artefact class in isolation. Answers "did this artefact class alone give us enough to conclude the action occurred?"
- **Correlated column:** qualitative pass/fail for the unified timeline output.
- **Reproducibility column:** for scenarios executed multiple times (S04 and S07 only, 3 reps each), reports `N/3` where `N` is the number of repetitions in which the correlation timeline correctly reconstructed the item. `N/A` for single-run scenarios.

## Cell values

| Value  | Meaning                                                                                             |
|--------|-----------------------------------------------------------------------------------------------------|
| `PASS` | Artefact class produced the expected evidence; ground-truth action recoverable from it alone.       |
| `PART` | Partial. Some but not all ground-truth fields recoverable (e.g. timestamp yes, target path no).     |
| `FAIL` | Expected evidence absent, missing, or contradicts ground truth.                                     |
| `N/A`  | Artefact class not applicable to this scenario by design (negative control) OR single-run scenario for the Reproducibility column. |
| `N/3`  | Quantitative: number of the three repetitions in which correlation matched ground truth in full.    |

## Matrix

| Scenario | Ground-truth item                                       | PF   | EVTX | SBags | Correlated | Reproducibility | Notes |
|----------|---------------------------------------------------------|------|------|-------|------------|-----------------|-------|
| S01      | Chrome installer executed                               |      |      |       |            | N/A             |       |
| S01      | WinRAR installer executed                               |      |      |       |            | N/A             |       |
| S01      | VLC installer executed                                  |      |      |       |            | N/A             |       |
| S01      | Adobe Reader installer executed                         |      |      |       |            | N/A             |       |
| S01      | Zoom installer executed                                 |      |      |       |            | N/A             |       |
| S01      | Notepad++ installer executed                            |      |      |       |            | N/A             |       |
| S01      | Chrome install completed successfully                   |      |      |       |            | N/A             |       |
| S01      | WinRAR install completed successfully                   |      |      |       |            | N/A             |       |
| S01      | VLC install completed successfully                      |      |      |       |            | N/A             |       |
| S01      | Adobe Reader install completed successfully             |      |      |       |            | N/A             |       |
| S01      | Zoom install completed (+ service 7045)                 |      |      |       |            | N/A             |       |
| S01      | Notepad++ install completed successfully                |      |      |       |            | N/A             |       |
| S01      | User navigated to Downloads folder                      |      |      |       |            | N/A             |       |
| S04      | USB device attached (VID/PID/serial)                    | N/A  |      |       |            | /3              |       |
| S04      | USB volume root browsed                                 | N/A  | N/A  |       |            | /3              |       |
| S04      | USB subfolder browsed                                   | N/A  | N/A  |       |            | /3              |       |
| S04      | EXE launched from USB volume                            |      |      | N/A   |            | /3              |       |
| S04      | USB device safely ejected                               | N/A  |      | N/A   |            | /3              |       |
| S07      | notepad++.exe launched                                  |      |      | N/A   |            | /3              |       |
| S07      | User navigated to Documents in Save-As dialog           | N/A  | N/A  |       |            | /3              |       |
| S07      | New subfolder S07_Output_R\<NN\> created                | N/A  | N/A  |       |            | /3              |       |
| S07      | File s07-test-R\<NN\>.txt saved to new subfolder        |      |      |       |            | /3              |       |
| S07      | Save-As dialog ShellBags entry present                  | N/A  | N/A  |       |            | /3              |       |
| S02      | notepad.exe launched (3 times)                          |      |      | N/A   |            | N/A             |       |
| S02      | calc.exe launched (3 times)                             |      |      | N/A   |            | N/A             |       |
| S02      | chrome.exe launched (3 times)                           |      |      | N/A   |            | N/A             |       |
| S02      | winrar.exe launched (3 times)                           |      |      | N/A   |            | N/A             |       |
| S02      | vlc.exe launched (3 times)                              |      |      | N/A   |            | N/A             |       |
| S02      | notepad++.exe launched (3 times)                        |      |      | N/A   |            | N/A             |       |
| S02      | Prefetch run count = 3 per app                          |      | N/A  | N/A   |            | N/A             |       |
| S03      | Level-1 folder browsed                                  | N/A  | N/A  |       |            | N/A             |       |
| S03      | Level-2 folder browsed                                  | N/A  | N/A  |       |            | N/A             |       |
| S03      | Level-3 folder browsed                                  | N/A  | N/A  |       |            | N/A             |       |
| S03      | Level-4 folder browsed                                  | N/A  | N/A  |       |            | N/A             |       |
| S03      | Level-5 folder browsed                                  | N/A  | N/A  |       |            | N/A             |       |
| S03      | Sibling folder NOT browsed (neg. control)               | N/A  | N/A  |       |            | N/A             |       |
| S05      | File deleted to Recycle Bin                             |      |      |       |            | N/A             |       |
| S05      | Recycle Bin emptied                                     |      |      |       |            | N/A             |       |
| S06      | Interactive logon (type 2) at T1                        | N/A  |      | N/A   |            | N/A             |       |
| S06      | Workstation locked at T2                                | N/A  |      | N/A   |            | N/A             |       |
| S06      | Workstation unlocked at T3                              | N/A  |      | N/A   |            | N/A             |       |
| S06      | Logoff at T4                                            | N/A  |      | N/A   |            | N/A             |       |
| S08      | cmd.exe executed                                        |      |      | N/A   |            | N/A             |       |
| S08      | whoami invoked with args                                | N/A  |      | N/A   |            | N/A             |       |
| S08      | dir invoked with args                                   | N/A  |      | N/A   |            | N/A             |       |
| S08      | powershell.exe executed                                 |      |      | N/A   |            | N/A             |       |
| S08      | Get-Process invoked                                     | N/A  |      | N/A   |            | N/A             |       |
| S09      | Chrome launched                                         |      |      | N/A   |            | N/A             |       |
| S09      | URL 1 visited (example.com)                             | N/A  |      | N/A   |            | N/A             |       |
| S09      | URL 2 visited (bbc.co.uk)                               | N/A  |      | N/A   |            | N/A             |       |
| S09      | URL 3 visited (download source)                         | N/A  |      | N/A   |            | N/A             |       |
| S09      | File downloaded                                         |      |      |       |            | N/A             |       |
| S09      | Downloads folder opened in Explorer                     |      |      |       |            | N/A             |       |
| S10      | Clean shutdown at T1                                    |      |      | N/A   |            | N/A             |       |
| S10      | Power-on at T2                                          |      |      | N/A   |            | N/A             |       |
| S10      | Interactive logon after boot at T3                      | N/A  |      | N/A   |            | N/A             |       |

## Roll-up metrics

Computed once the matrix is populated:

- **Per-artefact completeness:** percentage of ground-truth items each artefact class alone marked `PASS` or `PART`.
- **Correlation lift:** percentage of ground-truth items where `Correlated` = `PASS` but at least one single-artefact column is `FAIL` or `PART`. This is the correlation-vs-single-source contribution.
- **Reproducibility mean:** mean `N/3` across S04 and S07 rows (only scenarios with 3 reps); expected >= 2.5/3 if the testbed is stable.
- **Per-scenario coverage:** percentage `PASS` per scenario; feeds scenario-level discussion in the report.

A live `.csv` mirror of this matrix is at `evaluation/evaluation-matrix.csv` and is what analysis scripts consume.
