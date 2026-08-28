# Scenario 7 Run 2 correlation table

Scenario: Save As from Notepad++ to Documents (main body). Run 2 of 3. See `scenarios/scenario_7/run_1/evaluation/correlation_table.md` for scenario overview and interpretive observations that generalise across runs.

**Precondition:** Same as Run 1. GT documents an accidental duplicate A05 end row at 00:47:43 (authoritative end is 00:48:03). A02 UTC marker: 2026-08-23T00:45:30.7524214Z.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 00:44:57 | Launch Notepad++ from Start | NOTEPAD++.EXE 00:45:05 (direct hit); GUP.EXE 00:45:05; DLLHOST 00:45:03 | Security 4688 x3, 4689 x3 | no match | CONFIRMED | Reproduces Run 1 A01 pattern. Thinner EVTX (3 vs 14 4688 events) but attribution is unambiguous. |
| A02 | 00:45:24 | Type Scenario 7 test content with UTC marker | MPCMDRUN x2, SECURITYHEALTHHOST x2, SVCHOST, TASKHOSTW (all Defender noise) | Security 4688 x10 parent Defender platform, 4689 x12, SCM 7040 BITS state change | no match | MISSED | Typing invisible to all three artefacts (same as Run 1). Prefetch and EVTX rows in the window are Defender running a scheduled scan concurrently. |
| A03 | 00:46:28 | File menu, Save As in Documents folder | SEARCHFILTERHOST 00:46:59, SEARCHPROTOCOLHOST 00:46:59 (Windows Search indexing the saved file, same as Run 1) | Security 4688 x4 with parent SearchIndexer.exe, 4689 x1, 4663 x3 object access, 4798 group enum | UsrClass BagMRU at 00:46:40: `Desktop\Documents`; UsrClass at 00:46:34: `Desktop\This PC\C:\Users`, `Desktop\This PC\C:\Temp`, `Desktop\This PC\C:\DISS_Config`, `Desktop\This PC\C:\DISS_TESTDATA`, `Desktop\This PC\C:\Program Files`, `Desktop\This PC\C:\Program Files\Notepad++` (identical seven-row pattern to Run 1) | CONFIRMED | Reproduces Run 1 A03 pattern exactly: seven ShellBag rows including Documents (save target) and Program Files\Notepad++ (common-dialog quick-access). This is the second confirmation of the Save-As-writes-to-ShellBags finding. |
| A04 | 00:47:18 | Closing Notepad++ | MICROSOFTEDGEUPDATE.EXE 00:47:17 (Edge Updater fires; noise) | Security 4688 x1, 4689 x1 (thin) | no match | PARTIAL | Same as Run 1 A04: exit visible but weak. |
| A05 | 00:47:37 | Opening Documents folder using File Explorer | no match | Security 4689 x2 | no match | MISSED | This run's A05 window is very short (~6 s to first end marker) and no distinctive artefact fires. This differs from Run 1 where ShellBag Desktop\Documents fired at 00:17:56 inside a 20 s window. Reproducibility gap driven by short-window effect. |
| A06 | 00:48:12 | Viewing the file created | NOTEPAD.EXE 00:48:15 (direct hit); DLLHOST, SVCHOST x2, WMIPRVSE | Security 4688 x6 with parent explorer.exe, 4689 x1, 4624 SYSTEM x1, DistributedCOM 10016 x1 | no match | CONFIRMED | Reproduces Run 1 A06: notepad.exe opens the .txt file from Explorer. Multi-class attribution. |
| A07 | 00:48:41 | Closing File Explorer and applications | no match | Security 4689 x2 | no match | MISSED | Same as Run 1 A07. |

## Coverage summary

- CONFIRMED: 3 of 7 (A01, A03, A06)
- PARTIAL: 1 of 7 (A04)
- MISSED: 3 of 7 (A02, A05, A07)
- Per-class hits: Prefetch 5 of 7, EVTX 7 of 7 (mostly generic), ShellBags 1 of 7 (A03)

Cross-run divergence from Run 1: A05 dropped from CONFIRMED to MISSED because the ShellBag namespace-refresh row that fires when Explorer opens Downloads/Documents did not land in this run's short A05 window (the accidental duplicate A05 end row noted in GT closed the window early). This is a GT-instrumentation issue in Run 2 rather than a real coverage change, and Run 3 should reproduce Run 1's CONFIRMED verdict for A05.
