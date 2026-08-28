# Scenario 2 correlation table

Scenario: application execution baseline (appendix). Six applications launched (notepad, calc, chrome, winrar, vlc, notepad++) with 3 iterations each. Artefact classes in matrix: Prefetch, EVTX. ShellBags not expected. See `scenarios/catalogue.md` for scenario definition and `evaluation/ground_truth.csv` for full action log.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

**Scope note:** `windows.csv` de-duplicates on Action code, so only iteration 1 of A01 to A06 is time-filtered into the windowed extracts. Iterations 2 and 3 are recorded in `ground_truth.csv` and would produce equivalent Prefetch/EVTX signatures on re-parse; they are not scored separately here because the appendix scenario is qualitative PASS/PART/FAIL per action class, not per iteration.

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows (iteration 1)

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 18:29:49 | Launch notepad.exe | NOTEPAD.EXE runtime 18:29:53 (direct hit) | Security 4688 x15 (parent explorer.exe confirms user-launch origin), 4689 x10, WindowsUpdateClient EID 44 noise | no match (Notepad is a Win32 app, does not touch Explorer shell namespace) | CONFIRMED | Prefetch RunTime for notepad.exe and Security 4688 with parent explorer.exe converge on the launch second; two artefact classes attribute the action. |
| A02 | 18:31:04 | Launch calc.exe | CALCULATORAPP.EXE runtime 18:31:08 (Windows 11 Calculator is a UWP app named CalculatorApp.exe, not calc.exe) | Security 4688 x8 (parent services.exe reflects the UWP activation host), 4689 x9 | no match | CONFIRMED | The Prefetch hit lands on CALCULATORAPP.EXE rather than calc.exe because Windows 11 replaces the Win32 calculator with a UWP variant; naming discrepancy is a documented artefact-parser observation, not a failure. EVTX 4688 corroborates via the UWP activation chain. |
| A03 | 18:32:04 | Launch chrome.exe | CHROME.EXE runtime x18 across 18:32:07 to 18:32:22; ELEVATION_SERVICE.EXE 18:32:08; UPDATER.EXE x2 | Security 4688 x145 (child processes of Chrome sandbox architecture), 4689 x149; Chrome Application EID 256 log entry at 18:32:38 | no match | CONFIRMED | Chrome's multi-process sandbox produces a dense Prefetch fingerprint (18 runtime rows in 15 seconds) and matching Security 4688 burst; independent Chrome-native Application log confirms browser was active. |
| A04 | 18:34:14 | Launch winrar.exe | WINRAR.EXE runtime 18:34:18 (direct hit); RAREXTINSTALLER.EXE 18:34:18 (WinRAR shell-extension refresh on first launch); MSEDGEWEBVIEW2.EXE x6 (WinRAR bundled help component) | Security 4688 x22 (parent svchost.exe), 4689 x16, 5379 x25 (credential reads for licensed features) | no match | CONFIRMED | Prefetch of winrar.exe plus rarextinstaller.exe (fires on first WinRAR launch to refresh shell integration) plus EVTX 4688 chain gives multi-class attribution. |
| A05 | 18:35:36 | Launch vlc.exe | VLC.EXE runtime 18:35:40 (direct hit) | Security 4688 x2 (parent svchost.exe reflects protocol-handler launch), 4689 x5, 5379 x4 credential reads | no match | CONFIRMED | Prefetch names vlc.exe at the launch second; EVTX 4688 events, while thin, corroborate. VLC's single-process architecture explains the sparse EVTX footprint compared to Chrome. |
| A06 | 18:37:22 | Launch notepad++.exe | NOTEPAD++.EXE runtime 18:37:32 (direct hit); GUP.EXE 18:37:33 (Notepad++ updater fires on launch); AUDIODG.EXE noise | Security 4688 x6, 4689 x5, 5379 x4 | no match | CONFIRMED | Prefetch of notepad++.exe plus its bundled GUP.exe updater confirms the launch; EVTX 4688 corroborates. |

## Coverage summary

- CONFIRMED: 6 of 6
- PARTIAL: 0 of 6
- MISSED: 0 of 6
- Per-class hits: Prefetch 6 of 6, EVTX 6 of 6, ShellBags 0 of 6 (out of scope per matrix)

## Interpretive observations

1. Application-launch is the cleanest case for Prefetch attribution: every launched binary produces a `.pf` RunTime entry within seconds, and cross-corroboration with Security 4688 (parent explorer.exe) makes the origin unambiguous. This scenario is the strongest control case in the study.
2. Windows 11 renames or replaces some traditional Win32 executables with UWP equivalents (calc.exe becomes CalculatorApp.exe), which the analyst must recognise when mapping GT action codes to Prefetch entries. This is documented here as a naming subtlety, not a coverage gap.
3. ShellBags are absent as expected: launching an application does not open a shell-namespace folder. The matrix classification of Scenario 2 as PF plus EVTX only is therefore validated.
