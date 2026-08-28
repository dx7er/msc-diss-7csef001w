# Scenario 3: Nested folder navigation

Placement: appendix. Runs: 1. Matrix coverage: ShellBags only. Catalogue entry: `scenarios/catalogue.md`.

Purpose is the opposite of Scenario 2. Scenario 2 shows what launching a program looks like in three artefact classes; this scenario shows what walking through a folder tree looks like when the only artefact that records navigation is ShellBags. Prefetch and Event Logs are effectively silent for shell navigation, so this run acts as a negative control for them and a positive control for ShellBags.

## 1. Ground truth

Signed in as `dfanalyst`. Ran `scripts/scenarios/scenario3_prepare_tree.ps1` to create a five level nested folder tree under `C:\DISS_TESTDATA\scenario3_nav\level1_a\level2_a\level3_a\level4_a\level5_a` (plus a `level1_b` sibling). Opened File Explorer, navigated into the top folder, then double clicked into each level in sequence until reaching `level5_a`, then closed Explorer. Eight actions total.

Full action log at `evaluation/ground_truth.csv` (16 rows). All timestamps UTC captured by the guest.

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 07:20:32.249 | 07:20:52.826 | Open File Explorer |
| A02 | 07:21:32.466 | 07:21:48.279 | Navigate to C:\DISS_TESTDATA\scenario3_nav |
| A03 | 07:22:48.821 | 07:23:01.426 | Double click level1_a |
| A04 | 07:23:20.493 | 07:23:33.609 | Double click level2_a |
| A05 | 07:23:49.202 | 07:24:04.141 | Double click level3_a |
| A06 | 07:24:18.761 | 07:24:37.275 | Double click level4_a |
| A07 | 07:24:52.957 | 07:25:09.916 | Double click level5_a |
| A08 | 07:25:24.841 | 07:25:37.805 | Close Explorer |

## 2. Artefact acquisition

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 3
```

Transcript:

```text
[Acquire] scenario3 offline acquisition starting (single-run)
[Acquire] Enabled SeBackupPrivilege, SeRestorePrivilege, SeSecurityPrivilege
[Acquire] Resolved 'scenario3_post' -> DISS-Win11-25H2-Testbed-000003.vmdk
[Acquire] Mounting DISS-Win11-25H2-Testbed-000003.vmdk via aim_cli (DiscUtils, read only, online)
[Acquire] Mounted: AIM device 000000, NTFS at H:
[Acquire] Copying Windows\Prefetch\ (recursive)
  ok  Prefetch folder (362 files, exit 1)
[Acquire] Copying 5 event log channels
  ok    Security.evtx                                26,284,032 bytes (exit 1)
  ok    System.evtx                                   2,166,784 bytes (exit 1)
  ok    Application.evtx                              2,166,784 bytes (exit 1)
  ok    Microsoft-Windows-DriverFrameworks-UserMode%4Operational.evtx       69,632 bytes (exit 1)
  ok    Microsoft-Windows-Partition%4Diagnostic.evtx  69,632 bytes (exit 1)
[Acquire] Copying user hives (NTUSER.DAT and UsrClass.dat + transaction logs)
  ok    NTUSER.DAT                                    2,359,296 bytes (exit 1)
  ok    UsrClass.dat                                  2,097,152 bytes (exit 1)
[Acquire] Copying system hives (SYSTEM, SOFTWARE) and Amcache.hve
  ok    SYSTEM                                       13,369,344 bytes (exit 1)
  ok    SOFTWARE                                     82,051,072 bytes (exit 1)
  ok    Amcache.hve                                   2,621,440 bytes (exit 1)
[Acquire] scenario3 acquisition complete
  Files    : 376 (135.43 MB total)
  Manifest : D:\UOW\SEM3\msc-diss-7csef001w\scenarios\scenario_3\artefacts\supporting\acquisition_manifest.csv
```

Landing zones:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch | `artefacts/prefetch/` | 362 |
| Event logs | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 plus manifest |

Total 376 files, 135.43 MB. Chain of custody at `artefacts/supporting/acquisition_manifest.csv` (376 SHA-256 rows).

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_3_prefetch.csv `
  -q
```

Parsed outputs: `scenario_3_prefetch.csv` (356 rows) and `scenario_3_prefetch_Timeline.csv` (1,230 rows). Because Explorer is already running as the shell when navigation happens, no new executable fires and Prefetch has nothing distinctive to record for A01 through A08. The 1,230 timeline rows are Windows background activity (Defender, servicing, telemetry) unrelated to the user actions.

### 3.2 Event Logs (EvtxECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260825213224_EvtxECmd_Output.csv`, 31,107 rows.

Event ID distribution (top 8):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed (baseline chatter) |
| 4688 | 2,515 | A new process has been created |
| 4689 | 2,354 | A process has exited |
| 5379 | 743 | Credential Manager credentials were read |
| 4624 | 630 | An account was successfully logged on |
| 4672 | 602 | Special privileges assigned to new logon |
| 16 | 391 | Kernel-General hive load |
| 112 | 242 | HttpService URL reservation |

None of these EIDs directly attribute a folder navigation. Any 4688 event in an action window is background OS activity (Defender scanning, WindowsUpdate polling, telemetry).

### 3.3 ShellBags (SBECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\SBECmd.exe `
  -d .\artefacts\shellbags `
  --csv .\artefacts\analysis `
  --nl
```

Parsed outputs: `NTUSER.csv` (0 rows) and `UsrClass.csv` (17 rows). This is the primary evidence for the scenario. Six new rows appeared in UsrClass that were not in the Scenario 1 baseline (12 rows), one for each navigation into a new folder:

| AbsolutePath | ShellType | FirstInteracted | LastInteracted |
|---|---|---|---|
| Desktop\This PC\C:\DISS_TESTDATA\scenario3_nav | Directory | | 2026-08-18 07:21:39 |
| Desktop\This PC\C:\DISS_TESTDATA\scenario3_nav\level1_a | Directory | | 2026-08-18 07:22:51 |
| ...\level1_a\level2_a | Directory | | 2026-08-18 07:23:23 |
| ...\level1_a\level2_a\level3_a | Directory | | 2026-08-18 07:23:52 |
| ...\level1_a\level2_a\level3_a\level4_a | Directory | | 2026-08-18 07:24:21 |
| ...\level1_a\level2_a\level3_a\level4_a\level5_a | Directory | | 2026-08-18 07:24:55 |

Every one of the six navigations landed in ShellBags with a per folder LastInteracted timestamp that falls inside the ground truth window for that action. This is the strongest single artefact attribution in the whole study.

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 3
```

Windowed outputs:

| File | Rows |
|---|---|
| `windows.csv` | 8 |
| `scenario_3_prefetch_Timeline_windowed.csv` | 9 |
| `events_windowed.csv` | 82 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 17 |
| `correlation_report.txt` | 96 lines |

Per action hit counts:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 Open Explorer | 0 | 5 | 0 |
| A02 Navigate to scenario3_nav | 1 | 4 | 6 |
| A03 Double click level1_a | 1 | 7 | 1 |
| A04 Double click level2_a | 0 | 5 | 1 |
| A05 Double click level3_a | 5 | 31 | 1 |
| A06 Double click level4_a | 1 | 16 | 1 |
| A07 Double click level5_a | 1 | 9 | 5 |
| A08 Close Explorer | 0 | 5 | 0 |

The A02 row is interesting: six ShellBag entries fire in one window because opening `scenario3_nav` also reveals its sibling folders (`Users`, `Temp`, `DISS_Config`, `DISS_TESTDATA`, `PILOT`) in the tree pane, and Windows writes bags for each. The A07 row shows five ShellBag entries because at the deepest navigation Windows flushes the top level namespace entries alongside the target folder.

## 5. Correlation

Full per action analysis with evidence citations in `evaluation/correlation_table.md`.

### 5.1 Verdict summary

- CONFIRMED: 2 of 8 (A02, A07)
- PARTIAL: 4 of 8 (A03, A04, A05, A06)
- MISSED: 2 of 8 (A01, A08)

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 Open Explorer | MISSED | Explorer is already the running shell; no new process, no ShellBag write, no distinctive Event Log entry |
| A02 Navigate to scenario3_nav | CONFIRMED | UsrClass BagMRU rows for scenario3_nav plus five siblings written at 07:21:39, RUNDLL32 Prefetch (Explorer namespace helper) at 07:21:39, plus Security 4798 group enumeration |
| A03 Double click level1_a | PARTIAL | UsrClass BagMRU row for level1_a written at 07:22:51 (direct hit, single class) |
| A04 Double click level2_a | PARTIAL | UsrClass BagMRU row for level2_a written at 07:23:23 |
| A05 Double click level3_a | PARTIAL | UsrClass BagMRU row for level3_a written at 07:23:52 (Prefetch and EVTX activity in window is Defender signature update, unrelated) |
| A06 Double click level4_a | PARTIAL | UsrClass BagMRU row for level4_a written at 07:24:21 |
| A07 Double click level5_a | CONFIRMED | UsrClass BagMRU row for level5_a written at 07:24:55 plus namespace refresh writes for four top level shell folders in the same window |
| A08 Close Explorer | MISSED | Same limitation as A01: explorer.exe stays resident, no distinctive trace |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. ShellBags carry navigation evidence that Prefetch and Event Logs are structurally blind to. Five of six user folder navigations in this scenario produced a direct UsrClass BagMRU entry with a per folder timestamp inside the ground truth window. This validates the catalogue matrix classification of Scenario 3 as ShellBag only.

2. Prefetch and Event Logs did not simply fail to record folder navigation; they had nothing to record. Opening a folder in an already running `explorer.exe` does not spawn a new process, does not emit an Application log event, and does not touch any of the channels the acquisition script collected. When either class shows a row in an action window here it is coincident background activity, not evidence of the action.

3. Opening and closing an Explorer window (A01, A08) is a coverage gap for all three project artefacts. If future work needs to attribute Explorer window lifecycle, a fourth class such as Amcache or the Windows Explorer telemetry channels would need to be added to the acquisition set.

4. The Save As dialog behaviour observed in Scenario 7 (dialog writes ShellBag rows for the target folder and for the app's install directory) generalises with this scenario's result: any Windows shell interaction that presents a folder to the user tends to leave a UsrClass BagMRU entry, whether that presentation came from a File Explorer double click or a common dialog dropdown.

