# Record-level verification pass, 2026-09-06

Before Chapter 6 was written, every cell whose note asserted a specific record was re-checked against the parsed output in `scenarios/*/artefacts/analysis/`. Eight verdicts were changed and five notes were rewritten. The corrected matrix is `evaluation_matrix_corrected.csv`. This file records what changed and why, so the change is auditable.

## Verdict changes

| Scenario | Proposition | Field | Was | Now | Evidence checked |
|---|---|---|---|---|---|
| S01 | Notepad++ installer executed | evtx, correlated | PART | PASS | `windowed/events_windowed.csv` contains 4688 EventRecordId 34111 (09:18:49.15) and 34119 (09:18:51.34), both naming `C:\Users\dfanalyst\Downloads\npp.8.9.6.2.Installer.x64.exe`. Execution is directly evidenced; only completion lacks an installer-channel record. |
| S02 | Prefetch run count = 3 per app | pf, correlated | PASS | PART | `scenario_2_prefetch.csv`: RunCount is 3 for CalculatorApp, Notepad++, VLC and WinRAR, but the current Notepad entry is 4 and Chrome carries multiple entries at counts 2, 3, 3, 4, 4, 4, 12 and 14. |
| S07 | File saved to Documents root | evtx | PASS | N/A | All six 4663 records inside the Run 1 Save As window name `\Device\CdRom0\` or `\Device\CdRom0\setup.exe`. None names the saved file. File-system auditing was not enabled for profile paths, so no 4663 for that write was possible. |
| S09 | URL 1 visited (westminster.ac.uk) | evtx, correlated | PASS | PART | No hostname string appears in any of the 654 windowed records. The cited CAPI2 4097 record carries a certificate-authority name and thumbprint only. |
| S09 | Downloads folder opened in Explorer | evtx | PASS | N/A | All five windowed 4663 records name `\Device\CdRom0\`. The attribution rests on `UsrClass` `Desktop\Downloads` LastInteracted 09:13:47. |

## Note-only corrections, no verdict change

- **S01 Downloads navigation.** The BagMRU node exists with an empty LastInteracted; only the registry LastWriteTime moved, and it moved after the window closed.
- **S04 USB volume root.** `Desktop\E:\` is present in all three runs with empty FirstInteracted and LastInteracted. Only Run 1 carries an interacted node, `Desktop\This PC\E:` at 11:46:35. The 1 of 3 result is caused by which shell surface populates the interaction fields, not by first-visit inflation.
- **S06 lock.** Security 4800 is present at 16:04:15.98, which is 3.5 s after the A03 window closed. The earlier note claiming the audit subcategory is off by default is withdrawn.
- **S06 unlock.** Security 4801 is present at 16:05:49.38, which is 34 s before the A05 window opened. The row remains FAIL under the window rule, but the failure is temporal attribution from a retrospective marker, not artefact absence.
- **S10 logon after boot.** The guest-versus-host offset is 251.4 s at A02 and 172.0 s at A03. The offsets differ, so no constant correction exists and the earlier claim that a per-scenario offset would upgrade the row is withdrawn.

## Effect on roll-up metrics

| Metric | Before | After |
|---|---|---|
| Prefetch completeness | 29/32 = 90.6% | 29/32 = 90.6% |
| Event Log completeness | 38/44 = 86.4% | 36/42 = 85.7% |
| ShellBags completeness | 13/13 = 100.0% | 13/13 = 100.0% |
| Correlated PASS | 36 (65.5%) | 35 (63.6%) |
| Correlated PART | 13 (23.6%) | 14 (25.5%) |
| Correlated FAIL | 6 (10.9%) | 6 (10.9%) |
| Correlated PASS or PART | 49/55 = 89.1% | 49/55 = 89.1% |
| Incremental detection | 0/36 = 0.0% | 0/35 = 0.0% |
| Multi-class agreement | 24/36 = 66.7% | 24/35 = 68.6% |
| Single-class carry | 12/36 = 33.3% | 11/35 = 31.4% |

Per-scenario PASS counts after correction: S01 11/13, S02 6/7, S03 2/6, S04 4/5, S05 0/2, S06 2/4, S07 4/4, S08 2/5, S09 3/6, S10 1/3.

## Provenance

The corrections were applied cell by cell during the verification session and every change is listed in the table above. `evaluation_matrix.md` was updated on 23 September 2026 to carry the corrected figures. The pre-verification coding is retained unaltered in `evaluation_matrix.csv`, and the earlier version of `evaluation_matrix.md` is in git history (commit `b1e3cb7`).

## Action-level verdicts

The same verification withdrew the evidence for four CONFIRMED action-level verdicts, which were downgraded to PARTIAL in the per-scenario correlation tables:

| Scenario | Action | Was | Now | Reason |
|---|---|---|---|---|
| S07 Run 1 | A03 File menu, Save As | CONFIRMED | PARTIAL | The `4663` records in the window name `\Device\CdRom0\`, not the saved file. The save rests on ShellBags and Prefetch sequence, not a direct record of the write. |
| S07 Run 2 | A03 File menu, Save As | CONFIRMED | PARTIAL | Same as Run 1. |
| S07 Run 3 | A03 File menu, Save As | CONFIRMED | PARTIAL | Same as Run 1. |
| S09 | A02 Navigate to UoW website | CONFIRMED | PARTIAL | CAPI2 4097 names a certificate authority, not the destination hostname. No windowed record names westminster.ac.uk. |

Action-level totals across the 14 correlation tables (98 actions): CONFIRMED 51 to **47** (48.0%), PARTIAL 24 to **28** (28.6%), MISSED **23** (23.5%) unchanged. CONFIRMED or PARTIAL stays **75/98 = 76.5%**.
