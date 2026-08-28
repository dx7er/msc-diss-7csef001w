# Scenario 2: Application execution baseline

Placement: appendix. Runs: 3 iterations of the same 6 action sequence. Matrix coverage: Prefetch and Event Logs. Catalogue entry: `scenarios/catalogue.md`.

Purpose is a clean control case for application launch. Six applications preinstalled from Scenario 1 (Notepad, Windows 11 Calculator, Chrome, WinRAR, VLC, Notepad++) launched in the same order three times over. What we want to observe is whether Prefetch and Event Log evidence for a launched binary is stable across runs, and whether Windows 11's replacement of the classic Win32 calc.exe with a UWP variant surfaces cleanly in the parsed data.

## 1. Ground truth

Signed in as `dfanalyst` on a VM reverted to `scenario1_post` (so all six apps are already installed). Ran the `Log-Action` helper before and after each of the 6 actions, then repeated the whole sequence three times without reverting the snapshot in between.

Full action log at `evaluation/ground_truth.csv` (36 rows). All timestamps UTC captured by the guest.

Iteration 1:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 18:29:49.177 | 18:30:33.093 | Launch notepad.exe |
| A02 | 18:31:04.722 | 18:31:45.202 | Launch calc.exe |
| A03 | 18:32:04.403 | 18:33:09.185 | Launch chrome.exe |
| A04 | 18:34:14.620 | 18:34:56.389 | Launch winrar.exe |
| A05 | 18:35:36.595 | 18:36:48.135 | Launch vlc.exe |
| A06 | 18:37:22.944 | 18:38:29.551 | Launch notepad++.exe |

Iteration 2:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 18:39:53.810 | 18:41:17.268 | Launch notepad.exe |
| A02 | 18:42:07.462 | 18:43:32.036 | Launch calc.exe |
| A03 | 18:44:01.609 | 18:44:44.567 | Launch chrome.exe (typed as "chrrome.exe" in GT note, actual launch was chrome.exe) |
| A04 | 18:45:18.143 | 18:46:10.544 | Launch winrar.exe |
| A05 | 18:46:36.596 | 18:47:33.018 | Launch vlc.exe |
| A06 | 18:47:58.050 | 18:48:46.074 | Launch notepad++.exe |

Iteration 3:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 18:49:24.537 | 18:50:10.962 | Launch notepad.exe |
| A02 | 18:50:31.772 | 18:51:15.744 | Launch calc.exe |
| A03 | 18:51:37.061 | 18:52:23.953 | Launch chrome.exe |
| A04 | 18:52:52.092 | 18:53:48.517 | Launch winrar.exe |
| A05 | 18:54:12.928 | 18:54:58.754 | Launch vlc.exe |
| A06 | 18:55:19.067 | 18:56:16.180 | Launch notepad++.exe |

Total wall clock across three iterations: 26 minutes 27 seconds.

## 2. Artefact acquisition

Command run from the host after the VM was cleanly shut down:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 2
```

Script source: `scripts/scenarios/acquire_artefacts.ps1`.

Transcript:

```text
[Acquire] scenario2 offline acquisition starting (single-run)
[Acquire] Enabled SeBackupPrivilege, SeRestorePrivilege, SeSecurityPrivilege
[Acquire] Resolved 'scenario2_post' -> DISS-Win11-25H2-Testbed-000004.vmdk
[Acquire] Mounting DISS-Win11-25H2-Testbed-000004.vmdk via aim_cli (DiscUtils, read only, online)
[Acquire] Waiting for mount to attach and Windows to assign drive letters...
[Acquire] Mounted: AIM device 000000, NTFS at H:
[Acquire] Copying Windows\Prefetch\ (recursive)
  ok  Prefetch folder (439 files, exit 1)
[Acquire] Copying 5 event log channels
  ok    Security.evtx                                29,429,760 bytes (exit 1)
  ok    System.evtx                                   2,166,784 bytes (exit 1)
  ok    Application.evtx                              2,166,784 bytes (exit 1)
  ok    Microsoft-Windows-DriverFrameworks-UserMode%4Operational.evtx       69,632 bytes (exit 1)
  ok    Microsoft-Windows-Partition%4Diagnostic.evtx  69,632 bytes (exit 1)
[Acquire] Copying user hives (NTUSER.DAT and UsrClass.dat + transaction logs)
  ok    NTUSER.DAT                                    2,359,296 bytes (exit 1)
  ok    NTUSER.DAT.LOG1                                       0 bytes (exit 1)
  ok    NTUSER.DAT.LOG2                                 524,288 bytes (exit 1)
  ok    UsrClass.dat                                  2,097,152 bytes (exit 1)
  ok    UsrClass.dat.LOG1                               458,752 bytes (exit 1)
  ok    UsrClass.dat.LOG2                                     0 bytes (exit 1)
[Acquire] Copying system hives (SYSTEM, SOFTWARE) and Amcache.hve
  ok    SYSTEM                                       13,631,488 bytes (exit 1)
  ok    SOFTWARE                                     82,051,072 bytes (exit 1)
  ok    Amcache.hve                                   2,621,440 bytes (exit 1)
[Acquire] Dismounting AIM device
[Acquire] Computing SHA-256 manifest
[Acquire] scenario2 acquisition complete
  Snapshot : scenario2_post (DISS-Win11-25H2-Testbed-000004.vmdk)
  Mount    : AIM device 000000 at H: (dismounted)
  Files    : 453 (139.91 MB total)
  Manifest : D:\UOW\SEM3\msc-diss-7csef001w\scenarios\scenario_2\artefacts\supporting\acquisition_manifest.csv
```

Landing zones for raw evidence (excluded from GitHub, retained locally):

| Artefact class | Path | File count |
|---|---|---|
| Prefetch (.pf) | `artefacts/prefetch/` | 439 |
| Event logs (.evtx) | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 files plus manifest |

Total 453 files, 139.91 MB.

Chain of custody: `artefacts/supporting/acquisition_manifest.csv` (453 SHA-256 rows), committed to git even though the raw files it hashes are not.

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_2_prefetch.csv `
  -q
```

Parsed outputs:

| File | Rows |
|---|---|
| `scenario_2_prefetch.csv` | 434 (one per .pf) |
| `scenario_2_prefetch_Timeline.csv` | 1,468 (per RunTime row) |

Distinctive rows for the six launched binaries across three iterations. Notice that Windows 11's Calculator surfaces as `CALCULATORAPP.EXE` from the UWP install path, not as `calc.exe`:

| RunTime (UTC) | ExecutableName |
|---|---|
| 2026-08-17 18:31:08 | `...\WindowsApps\Microsoft.WindowsCalculator_11.2606.0.0_x64__8wekyb3d8bbwe\CALCULATORAPP.EXE` |
| 2026-08-17 18:42:11 | same path |
| 2026-08-17 18:50:35 | same path |
| 2026-08-17 18:32:07 | `\PROGRAM FILES\GOOGLE\CHROME\APPLICATION\CHROME.EXE` (iter 1) |
| 2026-08-17 18:44:06 | same path (iter 2) |
| 2026-08-17 18:51:40 | same path (iter 3) |
| 2026-08-17 18:29:53 | NOTEPAD.EXE (iter 1) |
| 2026-08-17 18:37:32 | NOTEPAD++.EXE (iter 1) |
| 2026-08-17 18:34:18 | WINRAR.EXE (iter 1) |
| 2026-08-17 18:35:40 | VLC.EXE (iter 1) |

CALCULATORAPP.EXE appearing three times at three different iteration launch seconds validates that Prefetch RunTime is stable and reproducible for the same binary across repeats.

### 3.2 Event Logs (EvtxECmd)

```powershell
mkdir .\artefacts\analysis\event_logs -Force | Out-Null
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260825213205_EvtxECmd_Output.csv`, 34,110 rows.

Event ID distribution (top 10):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed (Windows baseline chatter) |
| 4688 | 3,634 | A new process has been created |
| 4689 | 3,417 | A process has exited |
| 5379 | 958 | Credential Manager credentials were read |
| 4624 | 742 | An account was successfully logged on |
| 4672 | 709 | Special privileges assigned to new logon |
| 16 | 397 | Kernel-General hive load |
| 112 | 258 | HttpService URL reservation |
| 6 | 228 | FilterManager filter load |
| 44 | 195 | Windows Update Client search started |

4688 process creation events are the primary attribution signal for launches. The count roughly triples from Scenario 1 (2,876) because each iteration re-launches the same six applications and every launch fires a new 4688 record.

### 3.3 ShellBags (SBECmd)

```powershell
mkdir .\artefacts\analysis\shellbags -Force | Out-Null
D:\UOW\SEM3\Tools\ZimmermanTools\net9\SBECmd.exe `
  -d .\artefacts\shellbags `
  --csv .\artefacts\analysis `
  --nl
```

Parsed outputs: `NTUSER.csv` (0 rows), `UsrClass.csv` (12 rows). No shell namespace navigation was performed in this scenario, so nothing new landed in ShellBags. The 12 UsrClass rows are the baseline entries carried in from `scenario1_post`. ShellBags are out of scope per the matrix.

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 2
```

Windowed outputs land in `artefacts/analysis/windowed/`:

| File | Rows |
|---|---|
| `windows.csv` | 6 |
| `scenario_2_prefetch_Timeline_windowed.csv` | 64 |
| `events_windowed.csv` | 462 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 12 |
| `correlation_report.txt` | 131 lines |

Scope note. `windows.csv` deduplicates on Action code, so only iteration 1 of A01 through A06 lands in the windowed extracts. Iterations 2 and 3 remain in `ground_truth.csv` and their Prefetch RunTime entries and 4688 process events are visible in the parsed CSVs above but are not window filtered. This is acceptable because the appendix scenario is scored qualitatively per action class, not per iteration.

Per action hit counts (iteration 1) from `correlation_report.txt`:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 launch notepad.exe | 12 | 30 | 0 |
| A02 launch calc.exe | 8 | 32 | 0 |
| A03 launch chrome.exe | 22 | 303 | 0 |
| A04 launch winrar.exe | 18 | 71 | 0 |
| A05 launch vlc.exe | 1 | 11 | 0 |
| A06 launch notepad++.exe | 3 | 15 | 0 |

Chrome dominates because its multi process sandbox spawns ten or more child processes on first launch, each of which fires its own Prefetch entry and 4688 record.

## 5. Correlation

Per action analysis with evidence citations lives in `evaluation/correlation_table.md`. Verdict rules from `scripts/evaluation/evaluation_matrix.md`: CONFIRMED means two or more artefact classes attribute the action, PARTIAL means one class, MISSED means none.

### 5.1 Verdict summary

- CONFIRMED: 6 of 6 (all iteration 1 actions)
- PARTIAL: 0
- MISSED: 0

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 launch notepad.exe | CONFIRMED | NOTEPAD.EXE prefetch at 18:29:53 plus Security 4688 x15 with parent explorer.exe |
| A02 launch calc.exe | CONFIRMED | CALCULATORAPP.EXE prefetch at 18:31:08 (Windows 11 UWP variant, not calc.exe) plus Security 4688 x8 |
| A03 launch chrome.exe | CONFIRMED | CHROME.EXE prefetch x18 across 18:32:07 to 18:32:22 plus Security 4688 x145 sandbox child spawns plus Chrome native Application EID 256 |
| A04 launch winrar.exe | CONFIRMED | WINRAR.EXE prefetch at 18:34:18 plus rarextinstaller.exe (WinRAR shell integration refresh on first launch) plus Security 4688 x22 |
| A05 launch vlc.exe | CONFIRMED | VLC.EXE prefetch at 18:35:40 plus Security 4688 x2 |
| A06 launch notepad++.exe | CONFIRMED | NOTEPAD++.EXE prefetch at 18:37:32 plus GUP.EXE (Notepad++ bundled updater) plus Security 4688 x6 |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. Application launch is the cleanest attribution case in the study. Every launched binary produces a Prefetch RunTime within seconds and matching Security 4688 process creation events with parent `explorer.exe`, giving unambiguous multi class attribution. Scenario 2 is the reference control; any artefact failure in a more complex scenario can be cross checked against it.

2. Windows 11 replaces the classic Win32 calc.exe with a UWP variant. The Prefetch RunTime lands on `CALCULATORAPP.EXE` under the WindowsApps store path, not `calc.exe`. An analyst mapping user actions (which usually say "launch calculator") to Prefetch evidence must know this renaming, or the calc.exe search will come back empty and the launch will look like it was missed. This is a documented Windows 11 behaviour, not a parser failure.

3. Chrome's multi process sandbox produces the densest launch signature of any single application in the study (18 Prefetch entries plus 145 Security 4688 events in a 15 second window). Any launch signature this dense should not be mistaken for suspicious activity in an incident response context; it is the normal architecture of the browser.

