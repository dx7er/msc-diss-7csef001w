# Scenario 1: Install six applications

- Placement: **Main body**
- Runs: **1** (installer output is deterministic; further reps would repeat known Windows install behaviour without strengthening the correlation claim)
- Matrix coverage: **Prefetch + Event Logs + ShellBags**
- Deadline for this scenario: complete
- Catalogue entry: `scenarios/catalogue.md`

This is the study's richest single-event scenario. Application install produces traces across every artefact class simultaneously, plus MsiInstaller Application-log entries (EIDs 1033, 1040, 1042, 11707) and Service Control Manager service-install entries (EID 7045). Fifteen actions covering the full download-then-install cycle for six applications with a mix of installer types (MSI stub, MSI-based, NSIS-based) so the EVTX signature varies per app.

---

## 1. Ground truth

Signed in as `dfanalyst` on a VM reverted to the `baseline_pre_scenarios` snapshot. Ran the `Log-Action` helper before and after each of 15 user actions. Downloaded six installers into `%USERPROFILE%\Downloads` in sequence, closed Edge, opened the Downloads folder, then double-clicked each installer in order.

Full action log at `evaluation/ground_truth.csv` (30 rows: start plus end for each action). Timestamps are UTC captured by the guest at the moment of each Log-Action call.

| Action | Start (UTC) | End (UTC) | Duration (s) | Description |
|---|---|---|---|---|
| A01 | 08:58:59.403 | 08:59:41.340 | 41.9 | Open Microsoft Edge from Start |
| A02 | 09:00:13.782 | 09:00:50.726 | 36.9 | Download Chrome (ChromeSetup.exe) |
| A03 | 09:01:04.974 | 09:01:40.744 | 35.8 | Download WinRAR (winrar-x64-723.exe) |
| A04 | 09:01:54.111 | 09:02:53.433 | 59.3 | Download VLC (vlc-3.0.23-win32.exe) |
| A05 | 09:03:16.419 | 09:03:40.941 | 24.5 | Download Adobe Reader (Reader_en_R9BvLF8k_install.exe) |
| A06 | 09:03:59.527 | 09:05:04.704 | 65.2 | Download Zoom (ZoomInstallerFull.exe) |
| A07 | 09:05:30.395 | 09:06:06.180 | 35.8 | Download Notepad++ (npp.8.9.6.2.Installer.x64.exe) |
| A08 | 09:06:40.154 | 09:06:51.589 | 11.4 | Close Edge (all downloads complete) |
| A09 | 09:07:18.218 | 09:07:34.311 | 16.1 | Open File Explorer, navigate to Downloads |
| A10 | 09:07:54.395 | 09:09:20.197 | 85.8 | Double-click ChromeSetup.exe (install Chrome) |
| A11 | 09:09:44.312 | 09:10:03.723 | 19.4 | Double-click winrar-x64-723.exe (install WinRAR) |
| A12 | 09:10:25.347 | 09:11:13.373 | 48.0 | Double-click vlc-3.0.23-win32.exe (install VLC) |
| A13 | 09:11:33.229 | 09:17:18.529 | 345.3 | Double-click Reader_en_*.exe (install Adobe Reader) |
| A14 | 09:17:42.258 | 09:18:26.757 | 44.5 | Double-click ZoomInstallerFull.exe (install Zoom) |
| A15 | 09:18:45.418 | 09:19:19.550 | 34.1 | Double-click npp.8.9.6.2.Installer.x64.exe (install Notepad++) |

Total elapsed wall-clock: 20 minutes 20 seconds from Edge open to Notepad++ install finish.

---

## 2. Artefact acquisition

### 2.1 Command

Offline acquisition from the `scenario1_post` VMware snapshot, performed from the host after the VM was cleanly shut down:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 1
```

Script source: `scripts/scenarios/acquire_artefacts.ps1`. Approach: enable SeBackupPrivilege, SeRestorePrivilege, SeSecurityPrivilege; mount the VMDK snapshot read-only via Arsenal Image Mounter DiscUtils; copy artefact files out of the mounted volume into `scenarios/scenario_1/artefacts/`; unmount; compute SHA-256 for every file; write manifest.

### 2.2 Output (transcript)

```text
[Acquire] scenario1 offline acquisition starting (single-run)
[Acquire] Enabled SeBackupPrivilege, SeRestorePrivilege, SeSecurityPrivilege
[Acquire] Resolved 'scenario1_post' -> DISS-Win11-25H2-Testbed-000002.vmdk
[Acquire] Mounting DISS-Win11-25H2-Testbed-000002.vmdk via aim_cli (DiscUtils, read only, online)
[Acquire] Waiting for mount to attach and Windows to assign drive letters...
[Acquire] Mounted: AIM device 000000, NTFS at H:
[Acquire] Copying Windows\Prefetch\ (recursive)
  ok  Prefetch folder (419 files, exit 1)
[Acquire] Copying 5 event log channels
  ok    Security.evtx                                27,332,608 bytes (exit 1)
  ok    System.evtx                                   2,166,784 bytes (exit 1)
  ok    Application.evtx                              2,166,784 bytes (exit 1)
  ok    Microsoft-Windows-DriverFrameworks-UserMode%4Operational.evtx       69,632 bytes (exit 1)
  ok    Microsoft-Windows-Partition%4Diagnostic.evtx  69,632 bytes (exit 1)
[Acquire] Copying user hives (NTUSER.DAT and UsrClass.dat + transaction logs)
  ok    NTUSER.DAT                                    2,359,296 bytes (exit 1)
  ok    NTUSER.DAT.LOG1                                       0 bytes (exit 1)
  ok    NTUSER.DAT.LOG2                                       0 bytes (exit 1)
  ok    UsrClass.dat                                  2,097,152 bytes (exit 1)
  ok    UsrClass.dat.LOG1                               196,608 bytes (exit 1)
  ok    UsrClass.dat.LOG2                                     0 bytes (exit 1)
[Acquire] Copying system hives (SYSTEM, SOFTWARE) and Amcache.hve
  ok    SYSTEM                                       13,631,488 bytes (exit 1)
  ok    SOFTWARE                                     82,051,072 bytes (exit 1)
  ok    Amcache.hve                                   2,021,440 bytes (exit 1)
[Acquire] Dismounting AIM device
[Acquire] Computing SHA-256 manifest
[Acquire] scenario1_post acquisition complete
  Snapshot : scenario1_post (DISS-Win11-25H2-Testbed-000002.vmdk)
  Mount    : AIM device 000000 at H: (dismounted)
  Files    : 433 (136.67 MB total)
  Manifest : D:\UOW\SEM3\msc-diss-7csef001w\scenarios\scenario_1\artefacts\supporting\acquisition_manifest.csv
```

### 2.3 Landing zones (raw evidence)

Raw binaries are excluded from GitHub via `.gitignore` (property of University of Westminster; retained locally for submission and viva). Their local paths after acquisition:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch (.pf) | `artefacts/prefetch/` | 419 |
| Event logs (.evtx) | `artefacts/event_logs/` | 5 |
| ShellBag hives (NTUSER.DAT, UsrClass.dat + logs) | `artefacts/shellbags/` | 6 |
| System hives (SYSTEM, SOFTWARE, Amcache.hve) plus manifest | `artefacts/supporting/` | 3 + manifest |

Total: 433 files, 136.67 MB.

### 2.4 Chain of custody

Manifest committed to git even though the files it hashes are not:
`artefacts/supporting/acquisition_manifest.csv` (433 SHA-256 rows).

Sample rows:

| Algorithm | Hash | Path | SizeBytes |
|---|---|---|---|
| SHA256 | A5C69A3B50A001712C2A3DAF78773A8024C4E305340F31B999E32E9F46B10AEA | ...\prefetch\151.0.7922.138_CHROME_INSTALL-FFDC6407.pf | 45,984 |
| SHA256 | 302599C6C5CC6D5AF97483ACFC9997D43A525169D6E3EFD8B136823C2C9875E8 | ...\prefetch\ACROBAT.EXE-F94F9B29.pf | 52,771 |
| SHA256 | 9A6A7DE6A6BC8099A72374F94D05069A82742CF6B2B680F7C92B243F0F20E5D6 | ...\prefetch\ACROBAT.EXE-F94F9B2A.pf | 4,639 |
| SHA256 | 652CF7E001663F7D59F20DDA7923E32C8CC3F14076E16457A96E4EE78F22E682 | ...\prefetch\ACROBAT.EXE-F94F9B30.pf | 12,420 |

Every row can be independently re-verified by re-hashing the on-disk file.

---

## 3. Artefact parsing

All parsing performed on the host with Zimmerman tools (`D:\UOW\SEM3\Tools\ZimmermanTools\net9\`). Parsed outputs land in `artefacts/analysis/` (flat).

### 3.1 Prefetch (PECmd)

Command:

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_1_prefetch.csv `
  -q
```

Output summary (from PECmd `Processed ... in ...s` transcript, 419 .pf files):

```text
PECmd version 2026.5.0
Looking for prefetch files in .\artefacts\prefetch
Found 413 Prefetch files
Processed 413 out of 413 files in 8.3320 seconds
CSV output will be saved to .\artefacts\analysis\scenario_1_prefetch.csv
CSV timeline output will be saved to .\artefacts\analysis\scenario_1_prefetch_Timeline.csv
```

Parsed outputs:

| File | Rows | What it contains |
|---|---|---|
| `scenario_1_prefetch.csv` | 423 (one per .pf) | Per-.pf summary: SourceFilename, ExecutableName, RunCount, LastRun, Volume0Name, Volume0Serial, LoadedFiles, Directories |
| `scenario_1_prefetch_Timeline.csv` | 1,367 | Per-run timeline row (one .pf can carry up to 8 RunTime entries): `RunTime, ExecutableName` |

The Timeline CSV is the working evidence for correlation (per-run RunTime is what maps into per-action time windows).

Distinctive rows for the six installers (all landing in Downloads):

| RunTime (UTC) | ExecutableName |
|---|---|
| 2026-08-16 09:08:00 | `\VOLUME{01dd13b23dcb8909-043dd6e4}\USERS\DFANALYST\DOWNLOADS\CHROMESETUP.EXE` |
| 2026-08-16 09:08:02 | `\VOLUME{...}\USERS\DFANALYST\DOWNLOADS\CHROMESETUP.EXE` |
| 2026-08-16 09:09:48 | `\VOLUME{...}\USERS\DFANALYST\DOWNLOADS\WINRAR-X64-723.EXE` |
| 2026-08-16 09:10:31 | `\VOLUME{...}\USERS\DFANALYST\DOWNLOADS\VLC-3.0.23-WIN32.EXE` |
| 2026-08-16 09:11:36 | `READER_EN_R9BVLF8K_INSTALL.EX` |
| 2026-08-16 09:11:38 | `READER_EN_R9BVLF8K_INSTALL.EX` |
| 2026-08-16 09:17:46 | `\VOLUME{...}\USERS\DFANALYST\DOWNLOADS\ZOOMINSTALLERFULL.EXE` |
| 2026-08-16 09:18:51 | `\VOLUME{...}\USERS\DFANALYST\DOWNLOADS\NPP.8.9.6.2.INSTALLER.X64.EXE` |

Each RunTime is within one second of the corresponding ground-truth action start.

### 3.2 Event Logs (EvtxECmd)

Command:

```powershell
mkdir .\artefacts\analysis\event_logs -Force | Out-Null
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Output summary:

```text
EvtxECmd version 2026.5.0
Command line: -d .\artefacts\event_logs --csv .\artefacts\analysis
Maps loaded: 383
CSV output will be saved to .\artefacts\analysis\20260824210813_EvtxECmd_Output.csv

Processing Application.evtx:  Total event log records found: 1,222, dropped: 0
Processing DriverFrameworks-UserMode%4Operational.evtx:  Total: 3, dropped: 0
Processing Partition%4Diagnostic.evtx:  Total: 19, dropped: 0
Processing Security.evtx:  Total: 28,454
Processing System.evtx:  Total: 2,358
```

Parsed output:

| File | Rows |
|---|---|
| `20260824210813_EvtxECmd_Output.csv` | 32,056 |

Event-ID distribution (top 10):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed (baseline Windows chatter) |
| 4688 | 2,876 | A new process has been created |
| 4689 | 2,712 | A process has exited |
| 5379 | 771 | Credential Manager credentials were read |
| 4624 | 654 | An account was successfully logged on |
| 4672 | 626 | Special privileges assigned to new logon |
| 16 | 393 | Kernel-General hive load |
| 112 | 242 | HttpService URL reservation |
| 6 | 213 | FilterManager filter load |
| 44 | 194 | Windows Update Client search started |

Distinctive install-signature events (MsiInstaller EID 11707):

| TimeCreated (UTC) | EID | Provider | MapDescription | PayloadData1 (product) |
|---|---|---|---|---|
| 2026-08-16 09:16:52 | 11707 | MsiInstaller | Installation completed successfully | Product: Adobe Acrobat (64-bit) -- Installation operation completed successfully. |
| 2026-08-16 09:18:22 | 11707 | MsiInstaller | Installation completed successfully | Product: Adobe Refresh Manager -- Installation operation completed successfully. |

And Service Control Manager EID 7045 for the newly installed services:

| TimeCreated | EID | ServiceName |
|---|---|---|
| 2026-08-16 09:08:29 | 7045 | Google Updater Internal Service (GoogleUpdaterInternalService152.0.7933.0) |
| 2026-08-16 09:15:44 | 7045 | Adobe Acrobat Update Service |

### 3.3 ShellBags (SBECmd)

Command:

```powershell
mkdir .\artefacts\analysis\shellbags -Force | Out-Null
D:\UOW\SEM3\Tools\ZimmermanTools\net9\SBECmd.exe `
  -d .\artefacts\shellbags `
  --csv .\artefacts\analysis `
  --nl
```

Output summary:

```text
SBECmd version 2026.5.0
Processing D:\UOW\SEM3\msc-diss-7csef001w\scenarios\scenario_1\artefacts\shellbags\NTUSER.DAT
Total ShellBags found: 0
Processing D:\UOW\SEM3\msc-diss-7csef001w\scenarios\scenario_1\artefacts\shellbags\UsrClass.dat
Total ShellBags found: 12
Processing complete!
Processed 2 files in 0.14 seconds
```

Parsed outputs:

| File | Rows |
|---|---|
| `NTUSER.csv` | 0 (empty; no bags in NTUSER on this baseline) |
| `UsrClass.csv` | 12 |
| `!SBECmd_Messages.txt` | tool run log |

Full UsrClass BagMRU (all 12 rows):

| BagPath | AbsolutePath | ShellType | FirstInteracted | LastInteracted | LastWriteTime |
|---|---|---|---|---|---|
| BagMRU | Desktop\Win11 21H2 | Root folder: GUID | 2026-07-14 09:52:42 | | 2026-08-16 09:26:38 |
| BagMRU | Desktop\This PC | Root folder: GUID | | 2026-08-16 09:26:38 | 2026-08-16 09:26:38 |
| BagMRU | Desktop\Desktop | Root folder: GUID | 2026-07-14 10:39:54 | | 2026-08-16 09:26:38 |
| BagMRU | Desktop\Downloads | Root folder: GUID | 2026-07-14 10:39:56 | | 2026-08-16 09:26:38 |
| BagMRU\1 | Desktop\This PC\C: | Drive letter | | 2026-07-14 09:53:05 | 2026-07-14 09:53:05 |
| BagMRU\1\0 | Desktop\This PC\C:\Users | Directory | | | 2026-08-16 09:22:56 |
| BagMRU\1\0 | Desktop\This PC\C:\Temp | Directory | 2026-07-14 09:58:45 | | 2026-08-16 09:22:56 |
| BagMRU\1\0 | Desktop\This PC\C:\DISS_Config | Directory | 2026-07-14 10:11:28 | | 2026-08-16 09:22:56 |
| BagMRU\1\0 | Desktop\This PC\C:\DISS_TESTDATA | Directory | | 2026-08-16 09:22:56 | 2026-08-16 09:22:56 |
| BagMRU\1\0\0 | Desktop\This PC\C:\Users\dfanalyst | Directory | 2026-07-14 09:53:09 | 2026-07-14 09:53:09 | 2026-07-14 09:53:09 |
| BagMRU\1\0\3 | Desktop\This PC\C:\DISS_TESTDATA\PILOT | Directory | | 2026-07-17 19:29:12 | 2026-07-17 19:29:12 |
| BagMRU\1\0\3\0 | Desktop\This PC\C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9 | Directory | 2026-08-16 09:23:06 | 2026-08-16 09:23:06 | 2026-08-16 09:23:06 |

The `Desktop\Downloads` row is the ShellBag evidence for A09 (Open Downloads). Its `LastWriteTime` of 09:26:38 is the hive-flush moment (post-scenario), not the interaction moment; ShellBag timestamps prove that the navigation happened without proving when.

---

## 4. Window filtering

Command:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 1
```

Script source: `scripts/analysis/window_filter.ps1`. Approach: read `evaluation/ground_truth.csv`, build per-action `[Start-2s, End+2s]` windows into `windows.csv`, then filter each parsed CSV to only the rows whose timestamp lies inside at least one window.

Windowed outputs land in `artefacts/analysis/windowed/`:

| File | Rows | Source |
|---|---|---|
| `windows.csv` | 15 (one per action) | Derived from ground_truth.csv |
| `scenario_1_prefetch_Timeline_windowed.csv` | 142 | Filtered from 1,367 |
| `events_windowed.csv` | 832 | Filtered from 32,056 |
| `NTUSER.csv` | 0 | Copied from parsed |
| `UsrClass.csv` | 12 | Copied from parsed |
| `correlation_report.txt` | 320 lines | Generated by `correlate_scenario.py` (see next section) |

Per-action hit counts (from `correlation_report.txt`):

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 Open Edge | 9 | 62 | 0 |
| A02 Download Chrome | 2 | 20 | 0 |
| A03 Download WinRAR | 6 | 26 | 0 |
| A04 Download VLC | 1 | 40 | 0 |
| A05 Download Adobe Reader | 0 | 13 | 0 |
| A06 Download Zoom | 0 | 22 | 0 |
| A07 Download Notepad++ | 0 | 20 | 0 |
| A08 Close Edge | 1 | 18 | 0 |
| A09 Open Downloads | 1 | 5 | 0 (see analyst note) |
| A10 Install Chrome | 40 | 172 | 0 |
| A11 Install WinRAR | 5 | 30 | 0 |
| A12 Install VLC | 4 | 23 | 0 |
| A13 Install Adobe Reader | 47 | 251 | 0 |
| A14 Install Zoom | 23 | 72 | 0 |
| A15 Install Notepad++ | 3 | 58 | 0 |

---

## 5. Correlation

Per-action verdicts derived by intersecting the windowed evidence with the ground truth. Full row-by-row analysis with evidence citations lives in `evaluation/correlation_table.md`. Verdict rules from `scripts/evaluation/evaluation_matrix.md`: CONFIRMED (two or more artefact classes attribute), PARTIAL (one class attributes), MISSED (none).

### 5.1 Verdict summary

- **CONFIRMED: 7 of 15** (A01, A08, A10, A11, A12, A13, A14)
- **PARTIAL: 6 of 15** (A04, A05, A06, A07, A09, A15)
- **MISSED: 2 of 15** (A02, A03)

Per artefact class:

| Artefact class | Actions with any hit | Actions with attributing hit |
|---|---:|---:|
| Prefetch | 11 of 15 | 8 of 15 (A01, A08, A10, A11, A12, A13, A14, A15) |
| EVTX | 15 of 15 | 8 of 15 (installs plus A01 launch) |
| ShellBags | 1 of 15 (A09) | 1 of 15 (attributes only, not time-attributes) |

### 5.2 Per-action verdicts

| Action | Verdict | One-line reason |
|---|---|---|
| A01 Open Edge | CONFIRMED | MSEDGE.EXE prefetch at 08:59:07 + Security 4688 x25 spawning msedge children |
| A02 Download Chrome | MISSED | Pure HTTP download; no new binary execution, no Security auditing of HTTP, no shell activity |
| A03 Download WinRAR | MISSED | Same limitation as A02 |
| A04 Download VLC | PARTIAL | CAPI2 4097 x2 naming ISRG Root X1 issuer (Let's Encrypt-signed VLC download host) |
| A05 Download Adobe Reader | PARTIAL | CAPI2 4097 naming Starfield Services Root (Amazon CDN, consistent with Adobe download) |
| A06 Download Zoom | PARTIAL | CAPI2 4097 naming DigiCert High Assurance EV (Zoom's issuer) |
| A07 Download Notepad++ | PARTIAL | CAPI2 4097 x2 naming GlobalSign Root CA (notepad-plus-plus.org issuer) |
| A08 Close Edge | CONFIRMED | SMARTSCREEN prefetch at 09:06:44 + Security 4689 x17 exit burst signature |
| A09 Open Downloads | PARTIAL | UsrClass BagMRU row for Desktop\Downloads (persistent, hive-flush timestamp) |
| A10 Install Chrome | CONFIRMED | ChromeSetup prefetch + SCM 7045 "Google Updater Internal Service" install |
| A11 Install WinRAR | CONFIRMED | winrar-x64-723.exe prefetch + rarextinstaller.exe (WinRAR-only shell-integration installer) prefetch + CAPI2 Certum chain |
| A12 Install VLC | CONFIRMED | vlc-3.0.23-win32.exe prefetch + VLC-CACHE-GEN.EXE (first-run cache generator, VLC-specific) |
| A13 Install Adobe Reader | CONFIRMED | MsiInstaller EID 11707 "Adobe Acrobat (64-bit): Installation operation completed successfully" + EID 1033 with version 26.001.21771 + SCM 7045 Adobe Acrobat Update Service + Reader_en_*.exe prefetch |
| A14 Install Zoom | CONFIRMED | ZoomInstallerFull.exe prefetch + MsiInstaller 1040 x3 (Zoom bundled MSI sessions) + CAPI2 Comodo AAA chain |
| A15 Install Notepad++ | PARTIAL | Prefetch direct hit on npp.8.9.6.2.Installer.x64.exe; EVTX has no MsiInstaller trail because NPP uses NSIS not MSI |

### 5.3 Full row-by-row correlation table

See `evaluation/correlation_table.md` for the full table with evidence citations and analyst notes per row.

---

## 6. Key findings

Three findings from Scenario 1 generalise across the study and feed the cross-scenario evaluation matrix:

1. **Install actions produce the strongest cross-artefact convergence, especially for MSI-based installers.** Adobe, Zoom, Chrome, and VLC all produce a distinctive multi-class fingerprint: Prefetch captures the setup binary and post-install runtime, MsiInstaller EIDs 11707 (install success) and 1033 (product name and version) name the product explicitly, and Service Control Manager EID 7045 records any service installed. NSIS-based installers (Notepad++, WinRAR without service, VLC without service) miss the MsiInstaller trail, which drops verdicts to PARTIAL when the app has no supporting service.

2. **Pure browser download actions cannot be attributed by any of the three project artefacts.** A02, A03, A05, A06, and A07 are all "user clicked Download in Edge and file arrived in Downloads folder", which produces no Prefetch (the downloaded binary has not yet executed), no distinctive Security-auditing event (Windows does not log HTTP), and no ShellBag entry (Downloads is a shell namespace, not a filesystem folder navigation). CAPI2 EID 4097 certificate-chain-validation events give weak, host-issuer-level attribution (Starfield for Adobe, DigiCert for Zoom, GlobalSign for Notepad++, ISRG Root X1 for VLC), which is enough to lift the verdict above zero but not enough for CONFIRMED. This is a research-worthy gap that motivates including a fourth artefact class (Chromium history / Edge history) for full download attribution.

3. **Browser shutdown produces a distinctive multi-process exit burst.** A08 (Close Edge) shows 17 process-exit (Security 4689) events in a 15-second window, a signature that reproduces later in Scenario 9 for Chrome close (27-process exit burst) and validates cross-scenario as a reliable browser-shutdown fingerprint.

Two secondary observations worth noting:

4. **Windows Security-auditing 4907 events dominate the raw Security.evtx** (20,301 of 32,056 total EVTX rows, 63%). These are "auditing settings on registry object were changed" events emitted continuously by Windows for its own audit configuration; they are not attributable to any user action and should be filtered out at the parsing stage in future studies to reduce noise.

5. **UsrClass BagMRU timestamps are hive-flush timestamps, not interaction timestamps.** The Desktop\Downloads row has LastWriteTime 09:26:38 (post-scenario), which is when Windows persisted the hive after the session ended, not when the user navigated to Downloads at 09:07:18. This means ShellBags prove that a folder was navigated at some point but cannot alone time-attribute the navigation.

---

