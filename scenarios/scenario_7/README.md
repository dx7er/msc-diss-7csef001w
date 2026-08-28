# Scenario 7: Save As from Notepad++ to Documents

Placement: main body. Runs: 3 repetitions. Matrix coverage: Prefetch, Event Logs, ShellBags. Catalogue entry: `scenarios/catalogue.md`.

Purpose is a normal editing plus file creation workflow that hits all three artefact classes without overlapping Scenario 1 (installation) or Scenario 4 (removable media). The primary research contribution of the scenario is the Save As common dialog behaviour: when a user opens File Save As in Notepad++, Windows writes ShellBag rows for the destination folder and for the application's install directory even though the user never directly navigated to either. Three repetitions to observe stability of that behaviour.

## 1. Ground truth

VM reverted to `scenario1_post` before each run so Notepad++ is preinstalled. Save As target for every run: `C:\Users\dfanalyst\Documents\scenario7_test_file.txt`. Executed protocol matches the current catalogue entry for S07 (`scenarios/catalogue.md` S07 Manual steps): a straight Save As into the `Documents` root followed by an Explorer verification pass. An earlier draft of the catalogue included a per-rep subfolder creation step inside the Save As dialog; that step was dropped before Run 1 and the Catalogue authority note in `scenarios/catalogue.md` records the change. Per-run `evaluation/ground_truth.csv` PRE-row notes still refer to the earlier draft and are preserved for provenance.

Seven actions per run. Full logs at `run_1/evaluation/ground_truth.csv`, `run_2/evaluation/ground_truth.csv`, `run_3/evaluation/ground_truth.csv`.

Run 1:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 00:12:41.847 | 00:13:11.346 | Launch Notepad++ from Start |
| A02 | 00:13:46.164 | 00:14:45.535 | Type Scenario 7 test content with UTC marker |
| A03 | 00:16:00.415 | 00:16:43.134 | File menu, Save As |
| A04 | 00:17:00.150 | 00:17:12.161 | Close Notepad++ |
| A05 | 00:17:51.544 | 00:18:09.206 | Open Documents folder using File Explorer |
| A06 | 00:18:29.354 | 00:18:42.814 | Viewing the file created |
| A07 | 00:19:29.197 | 00:19:44.895 | Close File Explorer and applications |

Run 2 has an accidental duplicate A05 end row (authoritative end is the later timestamp, 00:48:03.850). Run 3 is a clean 14 row log.

Run 2 timestamps range 00:44:57 to 00:48:52. Run 3 timestamps range 01:37:10 to 01:41:25. Full detail in each run's `ground_truth.csv`.

## 2. Artefact acquisition (per run)

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 7 -Run 1
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 7 -Run 2
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 7 -Run 3
```

Per run file counts and sizes (post scenario snapshots `scenario7_run1_post`, `scenario7_run2_post`, `scenario7_run3_post`):

| Run | Prefetch files | Total files | Total size |
|---|---:|---:|---|
| Run 1 | 435 | 449 | 138.24 MB |
| Run 2 | 435 | 449 | 138.24 MB |
| Run 3 | 431 | 445 | 138.10 MB |

Per run manifests:

- `run_1/artefacts/supporting/acquisition_manifest.csv` (449 SHA-256 rows)
- `run_2/artefacts/supporting/acquisition_manifest.csv` (449 SHA-256 rows)
- `run_3/artefacts/supporting/acquisition_manifest.csv` (445 SHA-256 rows)

## 3. Artefact parsing (per run)

Per run parsed row counts:

| File | Run 1 | Run 2 | Run 3 |
|---|---:|---:|---:|
| PECmd summary | 430 | 430 | 426 |
| PECmd timeline | 1,429 | 1,428 | 1,415 |
| EvtxECmd output | 33,514 | 33,504 | 33,331 |
| SBECmd NTUSER | 0 | 0 | 0 |
| SBECmd UsrClass | 15 | 15 | 15 |

Distinctive Notepad++ launch entries (Prefetch) across three runs:

| Run | RunTime (UTC) | ExecutableName |
|---|---|---|
| Run 1 | 2026-08-23 00:12:49 | NOTEPAD++.EXE (from `\Program Files\Notepad++\notepad++.exe`) |
| Run 1 | 2026-08-23 00:12:49 | GUP.EXE (Notepad++ bundled updater) |
| Run 2 | 2026-08-23 00:45:05 | NOTEPAD++.EXE |
| Run 2 | 2026-08-23 00:45:05 | GUP.EXE |
| Run 3 | 2026-08-23 01:37:15 | NOTEPAD++.EXE |
| Run 3 | 2026-08-23 01:37:16 | GUP.EXE |

Notepad++ launch fires notepad++.exe plus GUP.exe in the same second every time, which is the Notepad++ specific launch fingerprint.

## 4. Window filtering (per run)

Per run windowed row counts:

| File | Run 1 | Run 2 | Run 3 |
|---|---:|---:|---:|
| `windows.csv` | 7 | 7 | 7 |
| `*_prefetch_Timeline_windowed.csv` | 19 | 17 | 27 |
| `events_windowed.csv` | 111 | 55 | 180 |
| `NTUSER.csv` | 0 | 0 | 0 |
| `UsrClass.csv` | 15 | 15 | 15 |

Per action ShellBag hits across three runs (this is the key evidence for the Save As finding):

| Action | Run 1 SB | Run 2 SB | Run 3 SB |
|---|---:|---:|---:|
| A03 File Save As | 7 | 7 | 7 |
| A05 Open Documents | 5 | 0 | 5 |

The A03 count of exactly seven UsrClass rows in every run is the primary research contribution. The rows are:

1. `Desktop\Documents` (the save target, written when the Save As dialog opens)
2. `Desktop\This PC\C:\Users` (dialog left pane enumeration)
3. `Desktop\This PC\C:\Temp` (dialog quick access enumeration)
4. `Desktop\This PC\C:\DISS_Config` (dialog quick access enumeration)
5. `Desktop\This PC\C:\DISS_TESTDATA` (dialog quick access enumeration)
6. `Desktop\This PC\C:\Program Files` (Notepad++'s parent directory)
7. `Desktop\This PC\C:\Program Files\Notepad++` (the application's install directory)

The last two rows are especially interesting because the user never navigated to Program Files or Program Files\Notepad++ manually; the Save As dialog enumerated them via its recent locations mechanism and Windows persisted the bags anyway.

## 5. Correlation (per run)

Per action analyses in `run_1/evaluation/correlation_table.md`, `run_2/evaluation/correlation_table.md`, `run_3/evaluation/correlation_table.md`.

### 5.1 Per action verdicts across three runs

| Action | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| A01 Launch Notepad++ | CONFIRMED | CONFIRMED | CONFIRMED |
| A02 Type content | MISSED | MISSED | MISSED |
| A03 File Save As | CONFIRMED | CONFIRMED | CONFIRMED |
| A04 Close Notepad++ | PARTIAL | PARTIAL | PARTIAL |
| A05 Open Documents in Explorer | CONFIRMED | MISSED | CONFIRMED |
| A06 View file (opens in Notepad) | CONFIRMED | CONFIRMED | CONFIRMED |
| A07 Close all | MISSED | MISSED | MISSED |

Six of seven actions reproduce their verdict exactly across all three runs. A05 shows a one run variance in Run 2 driven by the accidental duplicate end row closing the window early (documented in the GT header). The primary Save As finding (A03) reproduces exactly three times.

### 5.2 Summary of evidence per action

| Action | Attributes it |
|---|---|
| A01 Launch Notepad++ | NOTEPAD++.EXE prefetch plus GUP.EXE prefetch at the launch second plus Security 4688 with parent svchost.exe |
| A02 Type content | Nothing. Typing into a running process leaves no trace in any of the three artefacts |
| A03 File Save As | Seven UsrClass BagMRU rows written by the Save As dialog, including the save target (Documents) and the application install directory (Program Files\Notepad++); Windows Search indexing the saved file fires SEARCHFILTERHOST and SEARCHPROTOCOLHOST prefetch entries; Security 4663 object access on the FS resource |
| A04 Close Notepad++ | Security 4689 exit for notepad++.exe (single class, weak) |
| A05 Open Documents in Explorer | UsrClass namespace refresh with Desktop\Documents row (in Runs 1 and 3); Security 4663 object access; FILECOAUTH prefetch |
| A06 View file created | NOTEPAD.EXE prefetch (Windows opened the .txt file in default Notepad because Notepad++ was not registered as default .txt handler on this baseline); Security 4688 with parent explorer.exe (user double click origin) |
| A07 Close all | Security 4689 exit only; generic |

### 5.3 Full row by row correlation tables

See `run_1/evaluation/correlation_table.md`, `run_2/evaluation/correlation_table.md`, `run_3/evaluation/correlation_table.md`.

## 6. Key findings

1. Save As common dialog writes seven UsrClass BagMRU rows including the save target (Documents) and the application install directory (Program Files\Notepad++), and this pattern reproduces exactly across all three runs. This is the primary research contribution of the scenario. Its forensic value is that ShellBags carry evidence of folders the user was shown even briefly in a dialog dropdown, not just folders the user explicitly navigated into. An analyst looking at a UsrClass hive for evidence of "did the user see the Notepad++ install folder" can rely on this even if the user never opened Program Files themselves.

2. Notepad++ launch fingerprint is notepad++.exe plus GUP.exe (the bundled updater) firing in the same Prefetch second, reproducibly across three runs. Any Notepad++ launch in a real incident should carry this pair; if only one of the two fires, that is suspicious.

3. The saved .txt file opens in Notepad (not Notepad++) at A06 in every run. Notepad++ does not register as default .txt handler on Windows 11 25H2 by default, so the shell double click routes to notepad.exe. This does not affect attribution correctness for A06 (Prefetch of NOTEPAD.EXE and Security 4688 with parent explorer.exe still confirm the file was opened), but the analyst must know Windows' default file association rules to interpret the "which editor opened the file" question correctly.

4. Typing content into a running process (A02) is invisible to all three project artefacts. The UTC marker embedded in the file body (2026-08-23T00:13:50.928Z in Run 1) is only recoverable by post hoc file content inspection, which is outside the three artefact triangulation model.

