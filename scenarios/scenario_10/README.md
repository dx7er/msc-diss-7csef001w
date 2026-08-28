# Scenario 10: System shutdown and power on

Placement: appendix. Runs: 1. Matrix coverage: Prefetch and Event Logs. Catalogue entry: `scenarios/catalogue.md`.

Purpose is to reconstruct a full power cycle. Scheduled last per catalogue guidance so the shutdown and boot event windows do not overlap other scenarios' correlation.

## 1. Ground truth

Signed in as `dfanalyst` on a VM reverted to `baseline_pre_scenarios`. Issued a clean shutdown via Start menu (A01), left the VM powered off for a settle interval (A02), powered the VM back on (A03), waited 90 seconds for post boot settle (A04). Four actions.

GT records both the guest wall clock (from the in guest logger) and the host wall clock at A02 and A03 (captured manually), so the guest vs host clock skew across the power cycle can be measured after the fact.

Full action log at `evaluation/ground_truth.csv`.

| Action | Start (UTC, guest) | End (UTC, guest) | Description |
|---|---|---|---|
| PRE | 22:29:34.113 | | Baseline Pre Scenario VM, user signed in |
| A01 | 22:31:30.543 | 22:35:22.191 | VM Shutdown (Start, Power, Shut down); session terminated on shutdown |
| A02 | 22:36:06.720 | 22:36:40.471 | VM powered off; host UTC recorded as 22:31:55.297Z |
| A03 | 22:37:10.898 | 22:37:18.877 | VM powered on; host UTC recorded as 22:34:18.945Z; VM POST reached |
| A04 | 22:39:09.837 | 22:41:24.536 | Wait 90 s for post boot settle |

Guest vs host clock skew observed at A03: guest reports 22:37:10, host reports 22:34:18. Guest clock is roughly 3 minutes ahead of host across the power cycle. This has implications for windowing (see section 5 below).

## 2. Artefact acquisition

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 10
```

Transcript summary (359 files, 133.87 MB): Security.evtx 26,808,320 bytes, System.evtx 2,166,784 bytes (elevated compared to other scenarios because the shutdown and boot cycle wrote heavy Kernel-General, Kernel-Boot, Kernel-Power, Wininit, EventLog service records), Application.evtx 2,166,784 bytes, plus DriverFrameworks and Partition channels, plus user and system hives, plus Amcache.hve.

Landing zones:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch | `artefacts/prefetch/` | 344 |
| Event logs | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 plus manifest |

Manifest at `artefacts/supporting/acquisition_manifest.csv` (359 SHA-256 rows).

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_10_prefetch.csv `
  -q
```

Parsed outputs: `scenario_10_prefetch.csv` (340 rows) and `scenario_10_prefetch_Timeline.csv` (1,212 rows). Distinctive rows firing during the shutdown window (22:31:28 to 22:35:24 guest) include WLRMDR.EXE (shutdown notifier), CONSENT.EXE (UAC), VMTOOLSD.EXE, ONEDRIVE.EXE, and the SVCHOST cluster that fires as services stop. During the post boot settle window (A04) the notable entries are TIWORKER.EXE and TRUSTEDINSTALLER.EXE (Windows servicing coming back up) plus a fresh SVCHOST cluster.

### 3.2 Event Logs (EvtxECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260826225351_EvtxECmd_Output.csv`, 30,863 rows.

Event ID distribution (top 8):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed |
| 4688 | 2,415 | A new process has been created |
| 4689 | 2,189 | A process has exited |
| 5379 | 714 | Credential Manager credentials were read |
| 4624 | 669 | An account was successfully logged on |
| 4672 | 636 | Special privileges assigned to new logon |
| 16 | 351 | Kernel-General hive load |
| 112 | 258 | HttpService URL reservation |

Distinctive shutdown and boot lifecycle events fire once each during the power cycle. The full set observed in this run:

| EID | Provider | What it fires for |
|---|---|---|
| 109 | Microsoft-Windows-Kernel-Power | ShutdownActionType (shutdown initiated by user) |
| 1074 | User32 | Shutdown reason and initiating process |
| 1100 | Microsoft-Windows-Eventlog | The event logging service has shut down |
| 4647 | Microsoft-Windows-Security-Auditing | User initiated logoff |
| 7002 | Microsoft-Windows-Winlogon | Per SID logoff marker |
| 13 | Microsoft-Windows-Kernel-General | Shutdown StopTime |
| 20 | Microsoft-Windows-Kernel-Boot | LastShutdownGood flag |
| 12 | Microsoft-Windows-Kernel-General | Boot StartTime |
| 6005 | EventLog | Event log service started (boot marker) |
| 6009 | EventLog | Windows version at boot |
| 6013 | EventLog | System uptime seconds |
| 4608 | Microsoft-Windows-Security-Auditing | Windows is starting up |
| 7001 | Microsoft-Windows-Winlogon | Per SID logon marker |
| 4800 | Microsoft-Windows-Security-Auditing | Workstation locked (fires as part of the automatic lock at logon transitioning to logon screen) |
| 4801 | Microsoft-Windows-Security-Auditing | Workstation unlocked |

### 3.3 ShellBags (SBECmd)

Parsed outputs: `NTUSER.csv` (0 rows) and `UsrClass.csv` (11 rows). No shell navigation in this scenario, so no new bags. Out of scope per matrix.

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 10
```

Windowed outputs:

| File | Rows |
|---|---|
| `windows.csv` | 4 |
| `scenario_10_prefetch_Timeline_windowed.csv` | 67 |
| `events_windowed.csv` | 881 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 11 |
| `correlation_report.txt` | 169 lines |

Per action hit counts:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 VM Shutdown | 43 | 746 | 0 |
| A02 VM powered off | 0 | 0 | 0 |
| A03 VM powered on | 0 | 1 | 0 |
| A04 Post boot settle | 24 | 134 | 0 |

A01 dominates because Windows records both the shutdown lifecycle and, due to the clock skew described in section 5.2, the subsequent boot lifecycle inside the same guest timestamped window.

## 5. Correlation

Full per action analysis in `evaluation/correlation_table.md`.

### 5.1 Verdict summary

- CONFIRMED: 2 of 4 (A01, A04)
- PARTIAL: 0
- MISSED: 2 of 4 (A02 by design, A03 by clock skew windowing artefact)

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 VM Shutdown | CONFIRMED | Kernel-Power EID 109 (shutdown initiated) plus User32 EID 1074 (shutdown reason) plus EventLog EID 1100 (log service shut down) plus Security 4647 plus Winlogon 7002 for the shutdown side; then Kernel-Boot 20/153/247/238 plus EventLog 6005/6009/6013 plus Wininit sequence plus Security 4608 plus Winlogon 7001 for the boot side that landed in this window due to clock skew; plus Prefetch cluster (WLRMDR, CONSENT, VMTOOLSD, ONEDRIVE, SVCHOST) at the shutdown second |
| A02 VM powered off | MISSED | Expected. The VM is not running during A02, so no artefact of any kind can be produced. Row retained in GT for timeline completeness |
| A03 VM powered on | MISSED | The boot side EVTX events that would attribute A03 (Kernel-Boot 20, EventLog 6005, Security 4608, Winlogon 7001) all fire on the guest clock at 22:32:44, roughly 5 minutes before A03's guest recorded start time. They therefore land inside A01's window. If the boot events are re attributed to A03 by applying the roughly 3 minute clock skew, this row upgrades to CONFIRMED |
| A04 Wait 90 s for post boot settle | CONFIRMED | Prefetch of TIWORKER and TRUSTEDINSTALLER (Windows servicing coming online) plus SVCHOST cluster plus Security 4688 x47 with parent svchost (post boot service starts) plus 4624 x12 SYSTEM logons for each freshly started service |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. Shutdown and boot together produce the study's richest single artefact fingerprint in EVTX. On the shutdown side: Kernel-Power 109 plus User32 1074 plus EventLog 1100 plus Security 4647 plus Winlogon 7002. On the boot side: Kernel-Boot 20 plus EventLog 6005 plus 6009 plus 6013 plus Wininit sequence plus Security 4608 plus Winlogon 7001. These are the canonical evidence any forensic analyst would use to reconstruct a system power cycle, and all of them reproduce here.

2. Guest vs host clock skew across a shutdown and boot cycle is a real methodological finding. This VM's guest clock ran roughly 3 minutes ahead of host wall clock across the power cycle. Any correlation study using guest recorded ground truth against guest generated EVTX must either re sync the guest clock via VMware Tools before recording GT, or apply a per scenario clock offset at correlation time. Without one of those, boot lifecycle events land inside the shutdown window instead of the power on window, which is why A03 scores MISSED under strict windowing in this run.

3. Prefetch does not fire during A02 (VM powered off, which is not a Windows state) and only lightly during A03 (VM powered on, but the prefetcher itself is part of the boot sequence and has not initialised yet). The meaningful post boot Prefetch activity lands during A04, which is where the "system coming up to steady state" signature is captured.

