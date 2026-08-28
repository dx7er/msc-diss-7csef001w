# Scenario 3 correlation table

Scenario: nested folder navigation (appendix). Explorer navigation through five nested levels under `C:\DISS_TESTDATA\scenario3_nav\level1_a\level2_a\level3_a\level4_a\level5_a`. Artefact class in matrix: ShellBags only.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 07:20:32 | Open File Explorer | no match | Security 4688 x1 (parent svchost.exe), 4689 x1, 4663 x3 object access | no match | MISSED | Opening File Explorer when explorer.exe is already the shell does not spawn a new process or create a new ShellBag entry; there is no per-action attribution surface. Not a scenario failure, an artefact-scope limitation. |
| A02 | 07:21:32 | Navigate to C:\DISS_TESTDATA\scenario3_nav | RUNDLL32.EXE 07:21:39 (Explorer namespace expansion) | Security 4688 x1 (parent svchost.exe), 4798 x2 group enum | UsrClass BagMRU at 07:21:39: `Desktop\This PC\C:\Users`, `Desktop\This PC\C:\Temp`, `Desktop\This PC\C:\DISS_Config`, `Desktop\This PC\C:\DISS_TESTDATA`, `Desktop\This PC\C:\DISS_TESTDATA\PILOT`, `Desktop\This PC\C:\DISS_TESTDATA\scenario3_nav` | CONFIRMED | ShellBag entries directly attribute the navigation to the target folder and record the intermediate siblings that were briefly visible in the pane; RUNDLL32 Prefetch corroborates as Explorer's namespace-expansion helper. Multi-class attribution. |
| A03 | 07:22:48 | Double click level1_a | SPPSVC.EXE 07:22:58 (unrelated licensing service) | Security 4688 x2 generic, 4689 x4, SPP EID 16394 | UsrClass BagMRU at 07:22:51: `Desktop\This PC\C:\DISS_TESTDATA\scenario3_nav\level1_a` | PARTIAL | ShellBag captures the navigation with a per-folder timestamp; Prefetch and EVTX rows in the window are unrelated background noise. Single-class attribution is exactly what the matrix classifies this scenario as. |
| A04 | 07:23:20 | Double click level2_a | no match | Security 4688 x1, 4689 x3, SPP EID 16384 | UsrClass BagMRU at 07:23:23: `...\level1_a\level2_a` | PARTIAL | Same pattern as A03: ShellBag directly attributes, other classes silent. |
| A05 | 07:23:49 | Double click level3_a | AM_DELTA_PATCH background update, MPSIGSTUB, WUAUCLTCORE (all Defender-signature update noise) | Security 4688 x9 parent svchost, SecurityCenter EID 15 x3, WindowsUpdateClient EIDs 44/43/19 (background Defender update overlapping window) | UsrClass BagMRU at 07:23:52: `...\level1_a\level2_a\level3_a` | PARTIAL | ShellBag row directly attributes. Prefetch and EVTX rows within the window belong to a coincident Defender signature update, not the navigation. Discipline required to filter out. |
| A06 | 07:24:18 | Double click level4_a | SVCHOST.EXE 07:24:17 (generic) | Security 4688 x7, 4689 x7, 4624 SYSTEM logon | UsrClass BagMRU at 07:24:21: `...\level4_a` | PARTIAL | ShellBag row directly attributes. Prefetch and EVTX show only background system activity. |
| A07 | 07:24:52 | Double click level5_a | POWERSHELL.EXE 07:24:56 (background scheduled task) | Security 4688 x4 (parent CompatTelRunner.exe indicates Windows telemetry), 4689 x5 | UsrClass BagMRU at 07:24:55: five rows including root namespace refresh (`Desktop\Win11 21H2`, `This PC`, `Desktop`, `Downloads`) plus `...\level5_a` (the final target) | CONFIRMED | ShellBag records not only the deepest navigation but also a namespace refresh across the top-level shell folders (hive-flush moment for the accumulated session), giving two independent ShellBag observations. The scenario reached its five-level target. |
| A08 | 07:25:24 | Close Explorer | no match | Security 4689 x4 exit burst, SPP EID 16384 | no match | MISSED | Closing an Explorer window while explorer.exe remains the shell leaves no distinctive trace. The 4689 exit burst is too generic to attribute. |

## Coverage summary

- CONFIRMED: 2 of 8 (A02, A07)
- PARTIAL: 5 of 8 (A03, A04, A05, A06 plus A02 alt via SB and PF)
- MISSED: 2 of 8 (A01, A08 — both are Explorer window open/close, invisible to all three classes)
- Per-class hits: Prefetch 5 of 8 (all incidental, none attributable), EVTX 8 of 8 (all generic 4688/4689 without distinctive attribution), ShellBags 6 of 8 (every navigation into a new folder captured)

## Interpretive observations

1. Scenario 3 is the strongest single-artefact test in the study: five of six navigations produce a direct ShellBag BagMRU entry with a per-folder timestamp attribute (`LastInteracted`), which unambiguously proves the user opened the folder. This validates the matrix classification of Scenario 3 as ShellBag-only.
2. Prefetch and EVTX are structurally blind to shell-namespace navigation because opening a folder in a running Explorer does not spawn a new process or emit an Application-log event. Background Defender or WindowsUpdateClient activity happening to fall in the window is coincidental noise, not attribution.
3. The Explorer open (A01) and close (A08) actions bracket the scenario but are themselves invisible to all three artefact classes, which is a genuine coverage gap of the artefact-selection scope; a fourth class (Amcache, or the Windows.System.Search Explorer telemetry channel) would be required to capture them.
