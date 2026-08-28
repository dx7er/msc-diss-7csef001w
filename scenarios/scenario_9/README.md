# Scenario 9: Web browsing session with download

Placement: appendix. Runs: 1. Matrix coverage: Prefetch, Event Logs, ShellBags. Catalogue entry: `scenarios/catalogue.md`.

Purpose is to observe a realistic browse plus download session end to end. The scenario is designed to include one navigation that the browser can complete without user intervention (UoW homepage), one where the user clicks through to a subpage (BBC first headline), one scrolling read (Wikipedia article on digital forensics), and one file download that the shell will open in a separate application (a sample PDF into Adobe Reader). The interesting question is whether the three artefacts can reconstruct the "download this file, then open it" chain.

## 1. Ground truth

VM reverted to `scenario1_post` so Chrome and Adobe Reader are already installed. Signed in as `dfanalyst`. Launched Chrome from Start (A01), navigated through the four sites listed in the action table (A02, A03, A04, A05), closed Chrome (A06), opened Downloads in File Explorer to view the downloaded PDF (A07), closed File Explorer (A08). Eight actions.

Full action log at `evaluation/ground_truth.csv`.

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| PRE | 09:03:00 | | Revert to scenario1_post, sign in as dfanalyst, 60s settle, NAT enabled |
| A01 | 09:03:38.950 | 09:04:00.292 | Launch chrome from Start |
| A02 | 09:04:39.096 | 09:05:26.029 | Navigate to UoW website |
| A03 | 09:06:05.254 | 09:06:55.746 | Navigate to bbc and open first headline |
| A04 | 09:08:06.972 | 09:09:33.604 | Open digital forensics article in Wikipedia and scroll |
| A05 | 09:11:32.476 | 09:12:45.061 | Download a sample PDF from File Examples |
| A06 | 09:12:58.100 | 09:13:08.894 | Close Chrome |
| A07 | 09:13:40.062 | 09:13:58.310 | Open Downloads using File Explorer |
| A08 | 09:14:53.252 | 09:15:02.063 | Close File Explorer |

## 2. Artefact acquisition

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 9
```

Transcript summary (454 files, 141.60 MB): Security.evtx 30,183,424 bytes (larger than most scenarios because Chrome and Windows Update dominated the session), System.evtx 2,166,784 bytes, Application.evtx 2,166,784 bytes, plus DriverFrameworks and Partition channels, plus user and system hives, plus Amcache.hve.

Landing zones:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch | `artefacts/prefetch/` | 440 |
| Event logs | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 plus manifest |

Manifest at `artefacts/supporting/acquisition_manifest.csv` (454 SHA-256 rows).

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_9_prefetch.csv `
  -q
```

Parsed outputs: `scenario_9_prefetch.csv` (435 rows) and `scenario_9_prefetch_Timeline.csv` (1,461 rows).

Distinctive rows for the browse and download chain:

| RunTime (UTC) | ExecutableName |
|---|---|
| 2026-08-20 09:03:45 | CHROME.EXE (initial launch, A01) |
| 2026-08-20 09:03:46 to 09:03:58 | CHROME.EXE x10 (sandbox child spawns) |
| 2026-08-20 09:12:04 to 09:12:38 | ACROBAT.EXE x7 (Adobe Reader launched by shell to open the downloaded PDF) |
| 2026-08-20 09:12:06 to 09:12:14 | ACROCEF.EXE x3 (Acrobat's Chromium Embedded child) |
| 2026-08-20 09:12:18 | ADOBEARM.EXE (Adobe Refresh Manager fires on Acrobat launch) |
| 2026-08-20 09:13:03 | UPDATER.EXE x4 (Chrome Updater fires on Chrome exit at A06) |

The A05 to A06 chain is visible directly in Prefetch: Chrome downloads a PDF, the shell fires Adobe to open the PDF, then Chrome updater fires when Chrome exits.

### 3.2 Event Logs (EvtxECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260825213320_EvtxECmd_Output.csv`, 34,233 rows.

Event ID distribution (top 8):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed |
| 4688 | 3,728 | A new process has been created |
| 4689 | 3,494 | A process has exited |
| 5379 | 906 | Credential Manager credentials were read |
| 4624 | 738 | An account was successfully logged on |
| 4672 | 705 | Special privileges assigned to new logon |
| 16 | 397 | Kernel-General hive load |
| 112 | 258 | HttpService URL reservation |

Distinctive CAPI2 EID 4097 entries fire when the browser's TLS chain is validated against a root CA store; these are the only per destination attribution signal available in EVTX for browser navigation, and they name the issuer of the destination's certificate (for example CN=GlobalSign for the UoW website).

### 3.3 ShellBags (SBECmd)

Parsed outputs: `NTUSER.csv` (0 rows) and `UsrClass.csv` (12 rows). One new UsrClass row for `Desktop\Downloads` written at 09:13:47 (attribution for A07 open Downloads).

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 9
```

Windowed outputs:

| File | Rows |
|---|---|
| `windows.csv` | 8 |
| `scenario_9_prefetch_Timeline_windowed.csv` | 63 |
| `events_windowed.csv` | 654 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 12 |
| `correlation_report.txt` | 149 lines |

Per action hit counts:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 Launch chrome | 14 | 102 | 0 |
| A02 Navigate to UoW | 6 | 155 | 0 |
| A03 Navigate to bbc | 1 | 107 | 0 |
| A04 Wikipedia article | 13 | 146 | 0 |
| A05 Download PDF | 20 | 95 | 0 |
| A06 Close Chrome | 4 | 34 | 0 |
| A07 Open Downloads | 5 | 14 | 4 |
| A08 Close File Explorer | 0 | 0 | 0 |

## 5. Correlation

Full per action analysis in `evaluation/correlation_table.md`.

### 5.1 Verdict summary

- CONFIRMED: 5 of 8 (A01, A02, A05, A06, A07)
- PARTIAL: 2 of 8 (A03, A04)
- MISSED: 1 of 8 (A08)

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 Launch chrome | CONFIRMED | CHROME.EXE prefetch x11 at 09:03:45 to 09:03:58 plus Security 4688 x51 sandbox child spawns plus VSS EID 8224 |
| A02 Navigate to UoW | CONFIRMED | CAPI2 EID 4097 naming CN=GlobalSign Root CA (UoW's issuer) plus Chrome helper spawn Prefetch entries |
| A03 Navigate to bbc | PARTIAL | Chrome helper process churn confirms browser activity but does not identify bbc; no CAPI2 event this window (TLS chain was cached from earlier) |
| A04 Wikipedia article | PARTIAL | Chrome parented 4688 events attribute browser activity in the window; WER EID 1001 crash of a Chrome helper is incidental |
| A05 Download PDF | CONFIRMED | ACROBAT.EXE Prefetch x7 plus ACROCEF.EXE x3 plus ADOBEARM.EXE firing seconds after the download second (shell launched Reader to open the downloaded PDF) plus Chrome parented Security 4688 x41 for the download itself |
| A06 Close Chrome | CONFIRMED | Security 4689 x27 exit burst (Chrome multi process teardown) plus UPDATER.EXE Prefetch x4 (Chrome Updater fires on exit) |
| A07 Open Downloads using File Explorer | CONFIRMED | UsrClass BagMRU row for Desktop\Downloads at 09:13:47 plus Security 4663 object access on Downloads folder plus FILECOAUTH Prefetch (Explorer helper) |
| A08 Close File Explorer | MISSED | Same limitation as Scenario 3 A08; Explorer window close leaves no distinctive trace |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. A05 (download PDF) is the study's strongest cross artefact demonstration of a "browse plus download plus open" chain. Chrome parented Security 4688 events attribute the download itself, the Acrobat plus AcroCEF plus AdobeARM Prefetch cluster firing seconds after the download second attributes the shell opening the PDF in Reader, and together they let the analyst reconstruct the full chain from user click to file executed. This is the appendix candidate for a hero figure in the correlation chapter.

2. CAPI2 EID 4097 is the only per destination attribution signal for browser navigation in EVTX, and only for the first TLS handshake to a host. Subsequent visits reuse cached chains and produce no CAPI2 event, which is why A03 (BBC) has no per destination attribution while A02 (UoW, first visit) does. This limits CAPI2's usefulness for reconstructing a browsing timeline.

3. Chrome shutdown produces a distinctive 27 process exit burst plus the Chrome Updater firing on exit. This is the same class of signature observed in Scenario 1 A08 (Edge close, 17 process exit burst plus SmartScreen), and generalises as a reliable browser close fingerprint across Chrome and Edge. Any browser process cluster dying together in under 15 seconds should be treated as a shutdown, not as an anomaly.

