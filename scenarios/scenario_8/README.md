# Scenario 8: Command line execution (cmd and PowerShell)

Placement: appendix. Runs: 1. Matrix coverage: Prefetch and Event Logs. Catalogue entry: `scenarios/catalogue.md`.

Purpose is to see how console hosted commands are attributed. The distinction that matters is between commands that spawn a new binary (like `whoami`, which is `whoami.exe` on disk) and commands that are built into the shell process itself (like `dir` inside cmd.exe, or `Get-Process` inside powershell.exe). The first should attribute cleanly; the second should be effectively invisible on default audit settings.

## 1. Ground truth

Signed in as `dfanalyst`. Launched cmd.exe from Start (A01), ran `whoami` (A02), ran `dir C:\Windows` (A03), closed cmd (A04), launched powershell (A05), ran `Get-Process` (A06), closed powershell (A07). Seven actions.

Full action log at `evaluation/ground_truth.csv`.

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 20:18:10.821 | 20:18:29.142 | Launch cmd.exe from Start |
| A02 | 20:18:49.070 | 20:18:58.324 | cmd: whoami |
| A03 | 20:19:26.373 | 20:20:00.890 | cmd: dir C:\Windows |
| A04 | 20:20:14.293 | 20:20:25.205 | Close cmd |
| A05 | 20:20:48.444 | 20:21:19.857 | Launch powershell |
| A06 | 20:21:44.994 | 20:22:32.922 | PS: Get-Process |
| A07 | 20:22:49.771 | 20:23:00.024 | Close powershell |

## 2. Artefact acquisition

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 8
```

Transcript summary (364 files, 134.02 MB): Security.evtx 26,284,032 bytes, System.evtx 2,166,784 bytes, Application.evtx 2,166,784 bytes, plus the DriverFrameworks and Partition channels, plus user and system hives, plus Amcache.hve.

Landing zones:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch | `artefacts/prefetch/` | 350 |
| Event logs | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 plus manifest |

Manifest at `artefacts/supporting/acquisition_manifest.csv` (364 SHA-256 rows).

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_8_prefetch.csv `
  -q
```

Parsed outputs: `scenario_8_prefetch.csv` (345 rows) and `scenario_8_prefetch_Timeline.csv` (1,209 rows).

Distinctive console launch entries (Windows 11 hosts consoles inside Windows Terminal by default, so both the shell binary and the Terminal harness appear in Prefetch):

| RunTime (UTC) | ExecutableName |
|---|---|
| 2026-08-18 20:18:19 | CMD.EXE |
| 2026-08-18 20:18:19 | CONHOST.EXE |
| 2026-08-18 20:18:19 | OPENCONSOLE.EXE |
| 2026-08-18 20:18:19 | WINDOWSTERMINAL.EXE |
| 2026-08-18 20:18:51 | WHOAMI.EXE |
| 2026-08-18 20:20:53 | OPENCONSOLE.EXE (second time, for PowerShell tab) |
| 2026-08-18 20:20:53 | WINDOWSTERMINAL.EXE (second time) |

Notice there is no PREFETCH entry named `POWERSHELL.EXE-*.pf` in the timeline for A05. Windows Terminal reuses the already resident PowerShell prefetch entry from the baseline; only OPENCONSOLE and WINDOWSTERMINAL show fresh RunTimes for the second launch.

### 3.2 Event Logs (EvtxECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260825213304_EvtxECmd_Output.csv`, 30,275 rows.

Event ID distribution (top 8):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed |
| 4688 | 2,225 | A new process has been created |
| 4689 | 2,071 | A process has exited |
| 5379 | 695 | Credential Manager credentials were read |
| 4624 | 613 | An account was successfully logged on |
| 4672 | 585 | Special privileges assigned to new logon |
| 16 | 353 | Kernel-General hive load |
| 112 | 242 | HttpService URL reservation |

Distinctive Security 4798 and 4799 events (identity and group enumeration) fire when whoami runs, because whoami's entire purpose is to enumerate the current identity. This is the primary EVTX attribution for A02.

### 3.3 ShellBags (SBECmd)

Parsed outputs: `NTUSER.csv` (0 rows) and `UsrClass.csv` (11 rows). No new shell navigation, so no new bags. Out of scope per matrix.

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 8
```

Windowed outputs:

| File | Rows |
|---|---|
| `windows.csv` | 7 |
| `scenario_8_prefetch_Timeline_windowed.csv` | 29 |
| `events_windowed.csv` | 133 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 11 |
| `correlation_report.txt` | 93 lines |

Per action hit counts:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 Launch cmd.exe | 6 | 7 | 0 |
| A02 cmd: whoami | 4 | 29 | 0 |
| A03 cmd: dir C:\Windows | 6 | 26 | 0 |
| A04 Close cmd | 6 | 27 | 0 |
| A05 Launch powershell | 7 | 33 | 0 |
| A06 PS: Get-Process | 0 | 7 | 0 |
| A07 Close powershell | 0 | 4 | 0 |

## 5. Correlation

Full per action analysis in `evaluation/correlation_table.md`.

### 5.1 Verdict summary

- CONFIRMED: 2 of 7 (A01, A02)
- PARTIAL: 2 of 7 (A04, A05)
- MISSED: 3 of 7 (A03, A06, A07)

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 Launch cmd.exe from Start | CONFIRMED | CMD.EXE plus CONHOST.EXE plus OPENCONSOLE.EXE plus WINDOWSTERMINAL.EXE Prefetch cluster at 20:18:19 plus Security 4688 with parent svchost.exe (Terminal activation chain) |
| A02 cmd: whoami | CONFIRMED | WHOAMI.EXE Prefetch at 20:18:51 plus Security 4688 x7 plus 4798 x5 and 4799 x3 (whoami's identity and group enumeration syscalls) |
| A03 cmd: dir C:\Windows | MISSED | `dir` is a cmd.exe built in, not a separate binary; no Prefetch, no distinctive 4688; the Defender activity in the window is background noise |
| A04 Close cmd | PARTIAL | 4689 process exit for cmd.exe and its child conhost.exe, but generic |
| A05 Launch powershell | PARTIAL | OPENCONSOLE and WINDOWSTERMINAL Prefetch confirm a console app launched; no powershell.exe Prefetch this window because Terminal reused the baseline entry |
| A06 PS: Get-Process | MISSED | Get-Process is a PowerShell cmdlet inside powershell.exe; no new binary starts, no Prefetch, no distinctive EVTX |
| A07 Close powershell | MISSED | powershell.exe exit is captured in a 4689 record but is generic |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. Launching a console application on Windows 11 25H2 creates a four entry Prefetch cluster (WINDOWSTERMINAL plus OPENCONSOLE plus CONHOST plus the shell binary) that reliably attributes the launch. This is a stronger fingerprint than the pre Terminal Windows 10 baseline (which would show only CMD.EXE plus CONHOST.EXE), because Windows 11 encapsulates traditional consoles inside Windows Terminal by default.

2. whoami is the study's cleanest single command attribution. Because it is a standalone binary on disk, Prefetch captures it directly, and its Security log signature (4798 group enumeration plus 4799 privileged group enumeration) is uniquely tied to the identity lookup syscall pattern it uses. Any incident response wanting to prove that whoami ran can rely on this cross artefact convergence.

3. Built in shell commands are invisible to all three project artefacts because they execute inside the shell's own process. Attribution of a `dir` inside cmd or a `Get-Process` inside PowerShell at the invocation level requires either Security 4688 with the `CommandLine` field enabled (audit subcategory "Detailed Tracking, Process Creation, Include command line") or PowerShell Module Logging plus Script Block Logging. The baseline does not enable these, so this study cannot attribute those commands. This is a documented scope limitation, not a tool failure.

