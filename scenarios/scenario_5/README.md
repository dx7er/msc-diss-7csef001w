# Scenario 5: File deletion via Explorer and Recycle Bin

Placement: appendix. Runs: 1. Matrix coverage: Prefetch, Event Logs, ShellBags. Catalogue entry: `scenarios/catalogue.md`.

Purpose is to probe how a very ordinary destructive user action (delete a file, then empty the Recycle Bin) is captured by the three artefact classes. The expectation going in was that at least one of them should attribute the delete cleanly. The actual result is more interesting: the delete itself leaves almost no trace in any of the three classes, and the empty leaves an indirect Defender scan signature.

## 1. Ground truth

Preparation: ran `scripts/scenarios/scenario5_prepare_file.ps1` in the guest to stage `C:\DISS_TESTDATA\scenario5_delete\scenario5_target.txt` (239 bytes, SHA-256 1C35C35716B56C77AA468AA10EA252DCB1C5922200BB7CC308E4076C43817E89). The file was written before the scenario started so that the delete would have a real, hashable target with a known provenance.

Then signed in as `dfanalyst`, opened File Explorer, navigated to the target folder, deleted the file to the Recycle Bin, opened the Recycle Bin from the desktop, and finally emptied the Recycle Bin. Four scored actions. GT has A04 empty (no action assigned) because the empty was performed as A05 to keep the code numbering consistent with an earlier draft.

Full action log at `evaluation/ground_truth.csv`.

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| PRE | 08:24:25.399 | | Staged scenario5_target.txt (239 bytes) via prepare script |
| A01 | 08:28:55.092 | 08:29:23.888 | Open Explorer, navigate to C:\DISS_TESTDATA\scenario5_delete |
| A02 | 08:29:59.235 | 08:30:21.295 | Delete scenario5_target.txt to Recycle Bin |
| A03 | 08:30:48.441 | 08:31:05.519 | Open Recycle Bin from Desktop |
| A05 | 08:32:13.259 | 08:32:30.328 | Empty Recycle Bin |

## 2. Artefact acquisition

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 5
```

Transcript:

```text
[Acquire] scenario5 offline acquisition starting (single-run)
[Acquire] Enabled SeBackupPrivilege, SeRestorePrivilege, SeSecurityPrivilege
[Acquire] Resolved 'scenario5_post' -> DISS-Win11-25H2-Testbed-000005.vmdk
[Acquire] Mounted: AIM device 000000, NTFS at H:
[Acquire] Copying Windows\Prefetch\ (recursive)
  ok  Prefetch folder (347 files, exit 1)
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
  ok    SOFTWARE                                     81,264,640 bytes (exit 1)
  ok    Amcache.hve                                   2,621,440 bytes (exit 1)
[Acquire] scenario5 acquisition complete
  Files    : 361 (133.08 MB total)
```

Landing zones:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch | `artefacts/prefetch/` | 347 |
| Event logs | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 plus manifest |

Total 361 files, 133.08 MB. Chain of custody at `artefacts/supporting/acquisition_manifest.csv` (361 SHA-256 rows).

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_5_prefetch.csv `
  -q
```

Parsed outputs: `scenario_5_prefetch.csv` (342 rows) and `scenario_5_prefetch_Timeline.csv` (1,194 rows). No new user launched binary in this scenario, so the timeline is dominated by baseline Windows activity plus the Defender scan cluster that fires during A05.

### 3.2 Event Logs (EvtxECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260825213238_EvtxECmd_Output.csv`, 30,278 rows.

Event ID distribution (top 8):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed |
| 4688 | 2,218 | A new process has been created |
| 4689 | 2,055 | A process has exited |
| 5379 | 707 | Credential Manager credentials were read |
| 4624 | 614 | An account was successfully logged on |
| 4672 | 586 | Special privileges assigned to new logon |
| 16 | 359 | Kernel-General hive load |
| 112 | 242 | HttpService URL reservation |

No EID exists in this dump that directly says "user deleted a file to the Recycle Bin" or "user emptied the Recycle Bin". The Windows object access auditing subcategory that would fire Security 4663 for the delete is not enabled on the baseline, and even if it were, deletes routed through the Recycle Bin are shell moves rather than filesystem deletes.

### 3.3 ShellBags (SBECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\SBECmd.exe `
  -d .\artefacts\shellbags `
  --csv .\artefacts\analysis `
  --nl
```

Parsed outputs: `NTUSER.csv` (0 rows) and `UsrClass.csv` (12 rows). One new UsrClass row landed for the navigation to `Desktop\This PC\C:\DISS_TESTDATA\scenario5_delete` (attribution for A01). Nothing new for A02 (delete), A03 (open Recycle Bin), or A05 (empty), because none of those are shell namespace navigations into new filesystem paths.

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 5
```

Windowed outputs:

| File | Rows |
|---|---|
| `windows.csv` | 4 |
| `scenario_5_prefetch_Timeline_windowed.csv` | 15 |
| `events_windowed.csv` | 58 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 12 |
| `correlation_report.txt` | 62 lines |

Per action hit counts:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 Open Explorer, nav to scenario5_delete | 2 | 21 | 10 |
| A02 Delete to Recycle Bin | 0 | 2 | 0 |
| A03 Open Recycle Bin | 0 | 0 | 0 |
| A05 Empty Recycle Bin | 13 | 35 | 0 |

The A02 row is remarkable: two Security events fired in the window and neither of them attributes the delete. The A03 window is completely empty across all three classes. The A05 window fills up but the content is Windows Defender's MPCMDRUN cluster reacting to the bulk file removal, not a direct empty signature.

## 5. Correlation

Full per action analysis in `evaluation/correlation_table.md`.

### 5.1 Verdict summary

- CONFIRMED: 1 of 4 (A01)
- PARTIAL: 1 of 4 (A05)
- MISSED: 2 of 4 (A02, A03)

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 Open Explorer, nav to scenario5_delete | CONFIRMED | UsrClass BagMRU row for scenario5_delete written at 08:29:01 plus Security 4663 object access on FS resource plus RUNDLL32 Prefetch (Explorer namespace) |
| A02 Delete to Recycle Bin | MISSED | Delete is a shell move to `C:\$Recycle.Bin\<SID>\` with `$I` metadata files; none of Prefetch, EVTX, or ShellBags record it. Attribution would require parsing the `$I`/`$R` pair, which is outside the three artefact scope |
| A03 Open Recycle Bin from Desktop | MISSED | Zero rows in any windowed artefact; Recycle Bin is a virtual shell folder inside the running explorer.exe |
| A05 Empty Recycle Bin | PARTIAL | Windows Defender scan cluster (MPCMDRUN Prefetch x4 at 08:32:18 plus 17 Security 4688 events with Defender parent path) is consistent attribution but indirect; single class |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. Delete to Recycle Bin is a genuine coverage gap in three artefact triangulation. This is the study's clearest example of an action a user would consider destructive and observable, that the three chosen artefact classes fail to attribute directly. Attribution requires a fourth artefact class: parsing the `$I` and `$R` metadata files under `C:\$Recycle.Bin\<SID>\`. This deserves explicit discussion in the evaluation chapter and should be flagged in the cross scenario matrix.

2. Emptying the Recycle Bin fires Windows Defender because Windows sees a burst of file removals and dispatches a scan to check nothing malicious is in the removed set. That Defender cluster (MPCMDRUN plus 4688 events with Defender parent) is a reproducible pattern and can be treated as circumstantial evidence for a Recycle Bin empty, but a cautious analyst would flag it as inference rather than direct attribution.

3. Opening the Recycle Bin (A03) produces zero rows in any windowed artefact. If a forensic report needs to state that the user viewed the Recycle Bin at a given time, none of the three project artefacts can support that statement. This is a bigger structural gap than the delete itself, because at least the delete leaves the `$I` file on disk.

