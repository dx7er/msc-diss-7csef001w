# Scenario 7 Run 3 correlation table

Scenario: Save As from Notepad++ to Documents (main body). Run 3 of 3. See `scenarios/scenario_7/run_1/evaluation/correlation_table.md` for scenario overview and interpretive observations.

**Precondition:** Same as Runs 1 and 2. GT is a clean 14-row log (no duplicate rows). A02 UTC marker: 2026-08-23T01:37:55.7549893Z.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 01:37:10 | Launch Notepad++ from Start | NOTEPAD++.EXE 01:37:15 (direct hit); GUP.EXE 01:37:16; MSEDGE.EXE 01:37:09 (Edge background) | Security 4688 x6, 4689 x13, 5379 x7 credential reads, Edge Application EID 256 x1 (an Edge tab logged during window) | no match | CONFIRMED | Reproduces Runs 1 and 2 A01 pattern. Multi-class attribution. |
| A02 | 01:37:48 | Type Scenario 7 test content with UTC marker | FILECOAUTH, MSEDGEWEBVIEW2 x2, RUNTIMEBROKER x4, SPPSVC, STOREDESKTOPEXTENSION, SVCHOST x3, USEROOBEBROKER, WMIAPSRV (heavier background than Runs 1 and 2) | Security 4688 x42 parent services.exe, 4689 x19, 5379 x7, 4624 SYSTEM x4, 4672 x4, DistributedCOM 10016 x3, Time-Service EID 37 time.windows.com sync, Kernel-General EID 16 hive flush | no match | MISSED | Same MISSED verdict as prior runs for typing. Heavier background activity here (Windows Store first-run initialisation is running concurrently) is noise, not attribution. |
| A03 | 01:38:37 | File menu, Save As in Documents folder | AM_DELTA 01:39:35, MPSIGSTUB 01:39:35, WUAUCLTCORE 01:39:35 (Defender signature update), MSEDGE 01:38:39, SEARCHFILTERHOST 01:39:18, SEARCHPROTOCOLHOST 01:39:18 | Security 4688 x9 with parent msedge.exe, 4689 x22, 4663 x3 object access, WER 1001 crash x1, VSS EID 8224 | UsrClass BagMRU at 01:38:48: `Desktop\Documents`; UsrClass at 01:38:43: `Desktop\This PC\C:\Users`, `Desktop\This PC\C:\Temp`, `Desktop\This PC\C:\DISS_Config`, `Desktop\This PC\C:\DISS_TESTDATA`, `Desktop\This PC\C:\Program Files`, `Desktop\This PC\C:\Program Files\Notepad++` (same seven-row pattern as Runs 1 and 2) | CONFIRMED | Third consecutive confirmation of the Save-As-writes-to-ShellBags pattern with exact reproducibility across all three runs. This is the study's cleanest reproducibility evidence for the primary research finding of Scenario 7. |
| A04 | 01:39:47 | Closing Notepad++ | no match | Security 4689 x1, SecurityCenter EID 15 x1 | no match | PARTIAL | Same as prior runs. |
| A05 | 01:40:11 | Opening Documents folder using File Explorer | FILECOAUTH 01:40:18, RUNDLL32 01:40:18 (Explorer namespace); TASKHOSTW 01:40:33 | Security 4688 x5 with parent svchost.exe, 4689 x5, 4663 x3 object access | UsrClass BagMRU at 01:40:18: `Desktop\Win11 21H2`, `Desktop\This PC`, `Desktop\Desktop`, `Desktop\Downloads`, `Desktop\Documents` (identical five-row namespace refresh to Run 1) | CONFIRMED | Reproduces Run 1 A05 pattern (Run 2 lost this due to instrumentation issue). Multi-class attribution restored. |
| A06 | 01:40:45 | Viewing the file created | NOTEPAD.EXE 01:40:48 (direct hit) | Security 4688 x2 with parent svchost.exe (Windows shell-open dispatcher rather than direct explorer.exe parent this run), 4689 x4 | no match | CONFIRMED | Reproduces Runs 1 and 2 A06: notepad.exe opens the .txt file. The 4688 parent path differs from Runs 1 and 2 (svchost vs explorer.exe) suggesting Windows routed the file open via a different shell-dispatch path this run; this is a documented Win11 behaviour and does not affect attribution. |
| A07 | 01:41:06 | Closing File Explorer and applications | no match | Security 4689 x4 | no match | MISSED | Same as prior runs. |

## Coverage summary

- CONFIRMED: 4 of 7 (A01, A03, A05, A06)
- PARTIAL: 1 of 7 (A04)
- MISSED: 2 of 7 (A02, A07)
- Per-class hits: Prefetch 6 of 7, EVTX 7 of 7 (mostly generic), ShellBags 2 of 7 (A03, A05)

## Cross-run reproducibility summary (Runs 1, 2, 3)

| Action | Run 1 | Run 2 | Run 3 | Reproducibility |
|---|---|---|---|---|
| A01 launch NPP | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A02 type content | MISSED | MISSED | MISSED | 3/3 (expected) |
| A03 Save As | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A04 close NPP | PARTIAL | PARTIAL | PARTIAL | 3/3 |
| A05 open Docs | CONFIRMED | MISSED | CONFIRMED | 2/3 (Run 2 lost to short-window instrumentation) |
| A06 view file | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A07 close all | MISSED | MISSED | MISSED | 3/3 (expected) |

Overall: 6 of 7 actions reproduce their verdict exactly across all three runs. A05 shows a one-run variance driven by the GT instrumentation issue in Run 2 (accidental duplicate end row closing the window early), not by any real artefact-coverage change. The primary research finding of Scenario 7 (Save As common-dialog writes seven UsrClass rows including Documents target and Program Files\Notepad++) reproduces exactly across all three runs. This validates the reproducibility claim for Scenario 7.
