# Scenario 6: Logon, lock, unlock, logoff cycle

Placement: appendix. Runs: 1. Matrix coverage: Event Logs only. Catalogue entry: `scenarios/catalogue.md`.

Purpose is to probe session lifecycle attribution when the only artefact class in play is EVTX. Sign out, sign in, lock, unlock, sign out again, sign in again. The action list is deliberately artificial because the point is to see what Windows records about each session boundary at default audit settings.

## 1. Ground truth

Signed in as `dfanalyst` on a VM reverted to `baseline_pre_scenarios`. Signed out via Start menu (A01), signed back in (A02, session 2), pressed Win+L to lock the workstation (A03), waited more than 15 seconds while locked (A04), unlocked with password (A05), signed out again (A06), signed back in (A07, session 3). Seven actions across three shell sessions.

Retrospective GT rows: A01 end, A02 start and end, A06 end, A07 start and end were logged in a later shell session because the sign out terminated the logger's process. Exact end moments for A01 and A06 are the Security 4634 rows in the event log. Full action log at `evaluation/ground_truth.csv`.

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 16:01:16.442 | 16:03:04.588 | Sign out via Start menu (session 1) |
| A02 | 16:03:13.940 | 16:03:19.261 | Sign in as dfanalyst (session 2) |
| A03 | 16:03:58.414 | 16:04:10.497 | Press Win+L (lock) |
| A04 | 16:06:11.498 | 16:06:19.748 | Waited more than 15 s while locked (retrospective marker) |
| A05 | 16:06:25.741 | 16:06:31.255 | Unlock with password |
| A06 | 16:06:37.568 | 16:07:48.047 | Sign out again (session 2 end) |
| A07 | 16:07:53.276 | 16:07:57.337 | Sign in as dfanalyst (session 3) |

## 2. Artefact acquisition

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 6
```

Transcript summary (365 files copied, 134.68 MB): Security.evtx 26,284,032 bytes, System.evtx 2,166,784 bytes, Application.evtx 2,166,784 bytes, plus DriverFrameworks and Partition channels, plus user and system hives, plus Amcache.hve. Full transcript archived in project notes. Manifest at `artefacts/supporting/acquisition_manifest.csv` (365 SHA-256 rows).

Landing zones:

| Artefact class | Path | File count |
|---|---|---|
| Prefetch | `artefacts/prefetch/` | 365 |
| Event logs | `artefacts/event_logs/` | 5 |
| ShellBag hives | `artefacts/shellbags/` | 6 |
| System hives plus manifest | `artefacts/supporting/` | 3 plus manifest |

## 3. Artefact parsing

### 3.1 Prefetch (PECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_6_prefetch.csv `
  -q
```

Parsed outputs: `scenario_6_prefetch.csv` (360 rows) and `scenario_6_prefetch_Timeline.csv` (1,245 rows). Prefetch is out of scope per matrix, but the parsed timeline is retained because sign in and sign out both rebuild the shell process tree and Prefetch records the rebuild (USERINIT.EXE, LOGONUI.EXE, WINLOGON.EXE, CSRSS.EXE, DWM.EXE, FONTDRVHOST.EXE, SIHOST.EXE, STARTMENUEXPERIENCEHOST.EXE) which is useful as corroborating evidence.

### 3.2 Event Logs (EvtxECmd)

```powershell
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis
```

Parsed output: `20260825213252_EvtxECmd_Output.csv`, 30,723 rows.

Event ID distribution (top 8):

| EventId | Count | What it is |
|---|---|---|
| 4907 | 20,301 | Auditing settings on registry object changed |
| 4688 | 2,398 | A new process has been created |
| 4689 | 2,244 | A process has exited |
| 5379 | 716 | Credential Manager credentials were read |
| 4624 | 630 | An account was successfully logged on |
| 4672 | 597 | Special privileges assigned to new logon |
| 16 | 353 | Kernel-General hive load |
| 112 | 242 | HttpService URL reservation |

Distinctive session lifecycle events (the ones that attribute the sign outs and sign ins):

| EID | Provider | What it fires for |
|---|---|---|
| 4647 | Microsoft-Windows-Security-Auditing | "User initiated logoff" (the deliberate sign out at A01 and A06) |
| 4634 | Microsoft-Windows-Security-Auditing | An account was logged off |
| 4624 | Microsoft-Windows-Security-Auditing | An account was successfully logged on (fires for both user sign in and system service starts) |
| 7002 | Microsoft-Windows-Winlogon | Logon script terminated (per SID logoff marker) |
| 7001 | Microsoft-Windows-Winlogon | Logon script started (per SID logon marker) |
| 4800 | Microsoft-Windows-Security-Auditing | Workstation locked (only if audit subcategory 12 "Logon/Logoff other events" is enabled; it is not on this baseline) |
| 4801 | Microsoft-Windows-Security-Auditing | Workstation unlocked (same audit subcategory dependency) |

### 3.3 ShellBags (SBECmd)

Parsed outputs: `NTUSER.csv` (0 rows) and `UsrClass.csv` (11 rows). No shell navigation happened, so no new ShellBag entries appear. Out of scope per matrix.

## 4. Window filtering

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 6
```

Windowed outputs:

| File | Rows |
|---|---|
| `windows.csv` | 7 |
| `scenario_6_prefetch_Timeline_windowed.csv` | 76 |
| `events_windowed.csv` | 549 |
| `NTUSER.csv` | 0 |
| `UsrClass.csv` | 11 |
| `correlation_report.txt` | 169 lines |

Per action hit counts:

| Action | Prefetch hits | EVTX hits | ShellBag hits |
|---|---:|---:|---:|
| A01 sign out (session 1) | 41 | 295 | 0 |
| A02 sign in (session 2) | 0 | 4 | 0 |
| A03 press Win+L | 5 | 11 | 0 |
| A04 wait locked | 0 | 4 | 0 |
| A05 unlock | 0 | 0 | 0 |
| A06 sign out (session 2) | 30 | 235 | 0 |
| A07 sign in (session 3) | 0 | 0 | 0 |

The A01 and A06 rows dominate because a sign out plus the immediate follow up sign in is one continuous shell teardown and rebuild event, and Windows fires hundreds of process creation and exit events during it. A02 and A07 are almost empty because the 4624 and 4672 events that would attribute the sign in fire inside A01's and A06's window respectively.

## 5. Correlation

Full per action analysis in `evaluation/correlation_table.md`.

### 5.1 Verdict summary

- CONFIRMED: 2 of 7 (A01, A06)
- PARTIAL: 1 of 7 (A03)
- MISSED: 4 of 7 (A02, A04, A05, A07)

### 5.2 Per action verdicts

| Action | Verdict | One line reason |
|---|---|---|
| A01 sign out (session 1) | CONFIRMED | Security 4647 "User initiated logoff", Winlogon 7002 UserSID logoff, 7001 next session logon, plus USERINIT/LOGONUI/WINLOGON/CSRSS/DWM shell rebuild Prefetch cluster |
| A02 sign in (session 2) | MISSED | 4624 SYSTEM logon lands inside A01's window; A02's 10 second window catches only stragglers |
| A03 press Win+L | PARTIAL | UIEOrchestrator Prefetch fingerprint (lock screen orchestration); Security 4800 workstation locked event does not fire because audit subcategory 12 is off on baseline |
| A04 wait locked | MISSED | Retrospective marker; no user action to attribute |
| A05 unlock | MISSED | Security 4801 workstation unlocked event does not fire (same audit subcategory dependency as A03) |
| A06 sign out (session 2) | CONFIRMED | Same 4647 plus 7002 plus 7001 plus shell rebuild Prefetch as A01; reproducibility of the sign out fingerprint |
| A07 sign in (session 3) | MISSED | Same window boundary issue as A02 |

### 5.3 Full row by row correlation table

See `evaluation/correlation_table.md`.

## 6. Key findings

1. Sign out is the strongest session lifecycle signal in the study. EID 4647 "User initiated logoff" plus Winlogon 7002 UserSID plus the shell rebuild Prefetch cluster is an unambiguous forensic fingerprint that reproduces exactly across A01 and A06 in this scenario. Any suspicious session boundary in a real incident should first be checked against this pattern.

2. Workstation lock and unlock are effectively invisible on Windows 11 25H2 default audit configuration. Security EIDs 4800 (workstation locked) and 4801 (workstation unlocked) require audit subcategory 12 "Logon/Logoff other events" to be enabled explicitly. This is a research worthy finding: three artefact triangulation of lock and unlock requires an audit policy change that a default install analyst will not have.

3. Sign in that immediately follows a sign out is a methodology trap for windowed correlation. The 4624 logon of the next session fires inside the logoff window because Windows treats the whole teardown and rebuild as one continuous event burst. Correlation methodology should merge A01 plus A02 (and A06 plus A07) into a single "session transition" row whenever the boundary is under 20 seconds.

