# Reproducibility Guide

This document explains how to reproduce every part of the MSc dissertation "Correlating Windows Artifacts Evidence to Reconstruct User Activity: A Forensic Analysis of Prefetch, Event Logs and ShellBags" from a clean starting point. Read it top to bottom before attempting a run; a full reproduction of all ten scenarios takes roughly six to eight hours of hands on time spread over one or two days.

**Author:** Syed Muhammad Saqlain Abbas (W21634541)
**Supervisor:** Dr Jade James
**Institution:** School of Computer Science and Engineering, University of Westminster
**Module:** 7CSEF001W.2, MSc Cyber Security and Forensics Project
**Ethics reference:** ETH2526-2077 (Class 1, approved 11 June 2026, expires 9 September 2026)

## Table of contents

1. What you will reproduce
2. Ethics and data ownership
3. Prerequisites
4. Environment setup (host, VM, tools, baseline snapshot)
5. Study workflow at a glance
6. Common procedures (used by every scenario)
7. Per scenario reproduction steps
8. Verification and integrity checks
9. Troubleshooting
10. Tool versions used in the original study
11. Further reading

## 1. What you will reproduce

The study takes 10 controlled user activity scenarios on a Windows 11 testbed, records ground truth externally at the moment of execution, then acquires and parses three Windows forensic artefact classes (Prefetch, Windows Event Logs, ShellBags) and correlates them against the ground truth. Success looks like a per action verdict of CONFIRMED, PARTIAL or MISSED for each of the ~80 total actions across the 10 scenarios, plus a cross scenario evaluation matrix.

Expected outputs at the end of a full reproduction:

- 14 correlation tables (one per scenario or per run of a multi run scenario)
- 14 windowed artefact folders under each scenario
- 14 acquisition manifests with SHA-256 hashes for chain of custody
- One cross scenario evaluation matrix

Nothing in this study depends on Internet access other than Scenario 1 (six installer downloads) and Scenario 9 (four web navigations plus a PDF download). Every other scenario runs offline.

## 2. Ethics and data ownership

The study runs under University of Westminster Ethics reference ETH2526-2077 (Class 1, approved 11 June 2026). All data originates from a controlled virtual machine operated solely by the author. No human subjects, no personal data, no third party systems.

Raw forensic artefacts (`.pf`, `.evtx`, `NTUSER.DAT`, `UsrClass.dat`, `SYSTEM`, `SOFTWARE`, `Amcache.hve`) are property of the University of Westminster and are retained on the author's local disk for submission and viva examination only. They are excluded from the public GitHub mirror via `.gitignore`. If you clone this repository from GitHub the raw evidence will not be present; the parsed CSV outputs and the SHA-256 acquisition manifests are committed so you can inspect what was extracted and independently re verify the manifest against your own reproduction.

A reproduction produces its own new raw artefacts inside its own Windows VM. You do not need access to the author's original raw evidence to reproduce the study.

## 3. Prerequisites

Hardware:

- Host machine with at least 16 GB RAM, four cores, 200 GB free disk. The VM allocates 4 vCPU and 7 GB RAM.
- One USB stick, 4 GB or larger, formattable to NTFS. Required only for Scenario 4. Any brand works; the study happened to use a "General UDisk" stick.

Software on the host:

- Windows 10 or Windows 11
- VMware Workstation Pro 17
- Arsenal Image Mounter (for offline VMDK read only mount during acquisition; `aim_cli.exe` on PATH)
- PowerShell 5.1 or later
- Python 3.10 or later
- Eric Zimmerman's tools: PECmd, EvtxECmd, SBECmd. Get them from `https://ericzimmerman.github.io/`. Extract to `<somewhere>\ZimmermanTools\net9\` so the scripts in `scripts/analysis` can find them.
- Git (any recent version)

Software inside the VM (the Windows 11 25H2 guest):

- Baseline Windows 11 25H2 install, local account named `dfanalyst`, UTC timezone.
- Six user installed applications for Scenarios 1, 2, 7, 9: Google Chrome, WinRAR, VLC Media Player, Adobe Acrobat Reader DC, Zoom Workplace, Notepad++. These are installed by executing Scenario 1 itself; you do not preinstall them.

Repository:

- Clone this repository: `git clone https://github.com/dx7er/msc-diss-7csef001w`
- All paths in this guide are relative to the repository root.

## 4. Environment setup

### 4.1 Build the baseline VM

Follow `vm_testbed.md` in this repository step by step. That file documents the exact Windows 11 install choices, the local account creation, the timezone setting, the audit policy changes, the Windows Update disable steps, the Prefetch registry check, and the baseline snapshot.

The scripts in `scripts/testbed/` are numbered 01 through 12 and are meant to be run in the guest in order after Windows install:

| Script | Purpose |
|---|---|
| `01_install_host_parsers.ps1` | Records the Zimmerman tools versions used |
| `02_verify_install.ps1` | Verifies the guest tools install |
| `03_set_utc_and_locale.ps1` | Sets UTC timezone and en-GB locale |
| `04_capture_patch_state.ps1` | Captures Windows patch state as a snapshot fact |
| `05_encryption_and_power.ps1` | Turns off BitLocker prompts and hibernation |
| `06_audit_policy.ps1` | Applies the study's audit policy |
| `07_event_log_capacity.ps1` | Raises Security.evtx max size to keep the log from wrapping |
| `08_prefetch_readiness.ps1` | Confirms Prefetch is enabled and cleans out stale entries |
| `09_stage_test_data.ps1` | Stages the `C:\DISS_TESTDATA` folder used by several scenarios |
| `10_vmware_timesync_and_verify.ps1` | Confirms VMware Tools time sync is on and time drifts within acceptable bounds |
| `11_candidate_baseline_capture.ps1` | Snapshot pre run: this becomes `baseline_candidate` |
| `12_baseline_backup.ps1` | Cold copy of the VMDK for offline backup |

At the end of setup, take a VMware snapshot named `baseline_pre_scenarios`. Every scenario in this study reverts to that snapshot before starting. Record the snapshot in `vm_testbed.md`.

### 4.2 Verify the environment

Before running any scenario:

- Confirm the guest clock reads UTC and matches host time within 2 seconds (VMware Tools time sync should keep it in bounds).
- Confirm the guest account is `dfanalyst` and it is signed in with local administrator rights.
- Confirm `C:\DISS_TESTDATA\` exists in the guest.
- Confirm `scripts\scenarios\log_action.ps1` is available inside the guest (copy it in via the host clipboard or a shared folder if not).
- Confirm Prefetch is enabled: `Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' EnablePrefetcher` should return `3`.

## 5. Study workflow at a glance

Each scenario follows the same six phase workflow. Timing per scenario ranges from 15 minutes to 90 minutes depending on how many user actions are in it.

```
   +----------------+      +----------------+      +-------------------+
   | 1. Revert VM   | ---> | 2. Execute      | ---> | 3. Snapshot post  |
   |    to baseline |      |    scenario     |      |    scenario state |
   +----------------+      |    (in guest)   |      +-------------------+
                           +----------------+                 |
                                    |                         v
                                    v              +-------------------+
                           +----------------+     | 4. Offline acquire |
                           | Ground truth   |     |    artefacts       |
                           | logged via     |     |    (from host)     |
                           | Log-Action     |     +-------------------+
                           +----------------+                 |
                                                              v
                                                    +-------------------+
                                                    | 5. Parse with     |
                                                    |    Zimmerman tools|
                                                    +-------------------+
                                                              |
                                                              v
                                                    +-------------------+
                                                    | 6. Window filter  |
                                                    |    and correlate  |
                                                    +-------------------+
```

## 6. Common procedures

### 6.1 Ground truth logging (in guest)

Before each scenario, open PowerShell as `dfanalyst` in the guest and dot source the logger:

```powershell
. C:\DISS_TESTDATA\log_action.ps1
```

Then bracket every user action with:

```powershell
Log-Action A01 start "Human readable description of action"
# perform the user action
Log-Action A01 end
```

Action codes are `A01`, `A02`, etc. When the scenario finishes, export the log:

```powershell
Save-Log -Scenario N              # single run scenarios
Save-Log -Scenario N -Run M       # multi run scenarios (S4, S7)
```

This writes `C:\DISS_TESTDATA\scenarioN_actions.csv` (or `scenarioN_runM_actions.csv`) which becomes `evaluation/ground_truth.csv` in the scenario folder after acquisition.

### 6.2 Post scenario snapshot

Shut the VM down cleanly from Start plus Power plus Shut down. Wait for VMware to report the guest as powered off. Take a snapshot named:

- `scenarioN_post` for single run scenarios
- `scenarioN_runM_post` for multi run scenarios (S4 and S7)

### 6.3 Offline artefact acquisition (from host)

Close VMware Workstation first (Arsenal Image Mounter needs the VMDK not to be locked). From the host, in PowerShell:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario N
# or, for multi run scenarios:
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario N -Run M
```

What the script does:

1. Enables `SeBackupPrivilege`, `SeRestorePrivilege`, `SeSecurityPrivilege` on the current shell.
2. Resolves the snapshot name to the corresponding VMDK file.
3. Mounts the VMDK read only via `aim_cli` (DiscUtils, online mode).
4. Waits for Windows to assign a drive letter to the mounted volume.
5. Copies the Prefetch folder recursively into `scenarios/scenario_N/artefacts/prefetch/` (or the `run_M` variant).
6. Copies five event log channels into `scenarios/scenario_N/artefacts/event_logs/`: Security, System, Application, Microsoft-Windows-DriverFrameworks-UserMode%4Operational, Microsoft-Windows-Partition%4Diagnostic.
7. Copies user hives and their transaction logs into `scenarios/scenario_N/artefacts/shellbags/`: NTUSER.DAT plus LOG1 plus LOG2, UsrClass.dat plus LOG1 plus LOG2.
8. Copies system hives into `scenarios/scenario_N/artefacts/supporting/`: SYSTEM, SOFTWARE, Amcache.hve.
9. Dismounts the AIM device.
10. Computes SHA-256 for every copied file and writes `artefacts/supporting/acquisition_manifest.csv`.

Expected transcript ends with a summary line naming the file count and total size (typically 350 to 450 files, 130 to 140 MB).

### 6.4 Parsing with Zimmerman tools

From the host, inside the scenario folder:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scenarios\scenario_N>

# Prefetch
D:\UOW\SEM3\Tools\ZimmermanTools\net9\PECmd.exe `
  -d .\artefacts\prefetch `
  --csv .\artefacts\analysis `
  --csvf scenario_N_prefetch.csv `
  -q

# Event Logs
D:\UOW\SEM3\Tools\ZimmermanTools\net9\EvtxECmd\EvtxECmd.exe `
  -d .\artefacts\event_logs `
  --csv .\artefacts\analysis

# ShellBags
D:\UOW\SEM3\Tools\ZimmermanTools\net9\SBECmd.exe `
  -d .\artefacts\shellbags `
  --csv .\artefacts\analysis `
  --nl
```

Parsed CSVs land flat in `artefacts/analysis/`.

### 6.5 Window filtering

From the host:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario N
# or with run
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario N -Run M
```

What the script does:

1. Reads `evaluation/ground_truth.csv`.
2. Builds per action `[Start minus 2s, End plus 2s]` windows into `artefacts/analysis/windowed/windows.csv`.
3. Filters each parsed CSV to only rows whose timestamp lies inside at least one window.
4. Writes windowed CSVs flat under `artefacts/analysis/windowed/`.

### 6.6 Correlation

From the host:

```powershell
D:\UOW\SEM3\msc-diss-7csef001w> python scripts\analysis\correlate_scenario.py scenarios\scenario_N
# or
D:\UOW\SEM3\msc-diss-7csef001w> python scripts\analysis\correlate_scenario.py scenarios\scenario_N\run_M
```

This produces `artefacts/analysis/windowed/correlation_report.txt`, a per action evidence dump showing which prefetch rows, EVTX rows (grouped by Channel/Provider/EID), and shellbag rows fell in each action window.

The correlation dump is machine generated. The actual correlation table (`evaluation/correlation_table.md`) is written by hand from the dump, one row per ground truth action, with the analyst notes column carrying the "what does this show" interpretation. Verdict rules:

- CONFIRMED: two or more artefact classes yield a plausibly attributing hit
- PARTIAL: exactly one class attributes
- MISSED: none

See any existing `scenarios/scenario_N/evaluation/correlation_table.md` for the format.

## 7. Per scenario reproduction steps

Every scenario starts from a fresh revert to `baseline_pre_scenarios` (except Scenarios 2, 7 and 9, which start from `scenario1_post` because they need the applications from Scenario 1 to be preinstalled).

### 7.1 Scenario 1: Install six applications (1 run, NAT required)

1. Revert to `baseline_pre_scenarios`. Sign in as `dfanalyst`. Load the logger.
2. Open Microsoft Edge from Start (`Log-Action A01 start "Open Edge"` then click, then `Log-Action A01 end`).
3. Download six installers to Downloads, one at a time, each bracketed by Log-Action (A02 Chrome, A03 WinRAR, A04 VLC, A05 Adobe Reader, A06 Zoom, A07 Notepad++). URLs in `scenarios/catalogue.md`.
4. Close Edge (A08). Open File Explorer, navigate to Downloads (A09). Double click each installer in order (A10 Chrome, A11 WinRAR, A12 VLC, A13 Adobe, A14 Zoom, A15 Notepad++). Accept installer defaults; close each app if it auto launches.
5. `Save-Log -Scenario 1`. Shut down. Snapshot `scenario1_post`. Acquire.
6. See `scenarios/scenario_1/README.md` for expected verdict distribution.

### 7.2 Scenario 2: Application execution baseline (3 iterations)

1. Revert to `scenario1_post`. Sign in. Load the logger.
2. Launch six applications in sequence: notepad.exe (A01), calc.exe (A02, which is `CalculatorApp` on Windows 11 25H2), chrome.exe (A03), winrar.exe (A04), vlc.exe (A05), notepad++.exe (A06). Close each after use.
3. Repeat the six action sequence three times back to back without reverting.
4. `Save-Log -Scenario 2`. Shut down. Snapshot `scenario2_post`. Acquire.

### 7.3 Scenario 3: Nested folder navigation (1 run)

1. Revert to `baseline_pre_scenarios`. Sign in. Load the logger.
2. Run `scripts/scenarios/scenario3_prepare_tree.ps1` in the guest to stage the five level folder tree under `C:\DISS_TESTDATA\scenario3_nav\`.
3. Open File Explorer (A01), navigate to `C:\DISS_TESTDATA\scenario3_nav` (A02), double click into each level in sequence (A03 through A07), close Explorer (A08).
4. `Save-Log -Scenario 3`. Shut down. Snapshot `scenario3_post`. Acquire.

### 7.4 Scenario 4: USB attach, browse, execute from USB (3 runs, physical USB)

Before Run 1:

1. Prepare the USB stick with `scripts/scenarios/scenario4_prepare_usb.ps1` on the host. This wipes and reformats the stick to NTFS with volume label `DISS-USB`, then stages `\PORTABLE\HelloWorld.exe`. The script writes the identity manifest to `scenarios/scenario_4/evaluation/usb_identity.txt`.
2. Safely eject the stick from the host.

For each of the three runs (Run 1, Run 2, Run 3):

1. Revert to `baseline_pre_scenarios`. Sign in. Load the logger.
2. In VMware, VM plus Removable Devices plus <the DISS-USB device> plus Connect (A01).
3. In the guest, wait for the drive letter. Open File Explorer, navigate to the USB root (A02). Navigate into `\PORTABLE\` (A03). Double click `HelloWorld.exe` (A04); let the console self close.
4. Right click the USB drive in Explorer, Eject (A05). Wait for the "safe to remove" notification.
5. In VMware, VM plus Removable Devices plus <the DISS-USB device> plus Disconnect (A06).
6. `Save-Log -Scenario 4 -Run <M>`. Shut down. Snapshot `scenario4_runM_post`. Acquire (per run).

Use the same physical USB stick across all three runs so VID, PID and serial are constant.

### 7.5 Scenario 5: File deletion via Explorer plus Recycle Bin (1 run)

1. Revert to `baseline_pre_scenarios`. Sign in.
2. In PowerShell inside the guest, run `scripts/scenarios/scenario5_prepare_file.ps1`. This stages `C:\DISS_TESTDATA\scenario5_delete\scenario5_target.txt` (239 bytes) with a known SHA-256. Note the SHA-256 for the ground truth PRE row.
3. Load the logger.
4. Open Explorer, navigate to `C:\DISS_TESTDATA\scenario5_delete` (A01). Delete `scenario5_target.txt` to Recycle Bin (A02). Open Recycle Bin from desktop (A03). Empty Recycle Bin (A05; A04 is intentionally unassigned).
5. `Save-Log -Scenario 5`. Shut down. Snapshot `scenario5_post`. Acquire.

### 7.6 Scenario 6: Logon, lock, unlock, logoff cycle (1 run, three shell sessions)

This scenario spans three shell sessions because the logger process dies at each sign out. Retrospective logging is required.

1. Revert to `baseline_pre_scenarios`. Sign in (this is session 1). Load the logger.
2. `Log-Action A01 start "sign out via Start menu"`. Sign out via Start (this ends the logger process).
3. Sign in again as `dfanalyst` (session 2). Load the logger again. Retrospectively log A01 end at the last user action moment before sign out, then log A02 start and end for the sign in that just happened.
4. `Log-Action A03 start "press Win+L"`. Press Win+L. `Log-Action A03 end` after workstation locks.
5. Wait more than 15 seconds while locked (A04, retrospective marker). Unlock with password (A05, retrospective log after unlock).
6. `Log-Action A06 start "sign out again"`. Sign out again.
7. Sign in a third time (session 3). Load the logger. Retrospectively log A06 end, A07 start, A07 end.
8. `Save-Log -Scenario 6`. Shut down. Snapshot `scenario6_post`. Acquire.

### 7.7 Scenario 7: Save As from Notepad++ (3 runs)

For each of the three runs (Run 1, Run 2, Run 3):

1. Revert to `scenario1_post` (Notepad++ preinstalled). Sign in. Load the logger.
2. Launch Notepad++ from Start (A01).
3. Type a distinctive test string including a UTC marker into the blank tab (A02). Record the UTC marker in the GT note.
4. File plus Save As (A03). Save the file as `C:\Users\dfanalyst\Documents\scenario7_test_file.txt`.
5. Close Notepad++ (A04). Open Documents folder in File Explorer (A05). View the file created (A06, double click). Close File Explorer and applications (A07).
6. `Save-Log -Scenario 7 -Run <M>`. Shut down. Snapshot `scenario7_runM_post`. Acquire (per run).

Do not change the save target between runs; the seven UsrClass BagMRU row pattern depends on the same Documents path.

### 7.8 Scenario 8: Command line execution (1 run)

1. Revert to `baseline_pre_scenarios`. Sign in. Load the logger.
2. Launch cmd.exe from Start (A01). At the cmd prompt: `whoami` (A02); `dir C:\Windows` (A03). Close cmd (A04).
3. Launch PowerShell from Start (A05). At the PS prompt: `Get-Process` (A06). Close PowerShell (A07).
4. `Save-Log -Scenario 8`. Shut down. Snapshot `scenario8_post`. Acquire.

### 7.9 Scenario 9: Web browsing session with download (1 run, NAT required)

1. Revert to `scenario1_post` (Chrome and Adobe Reader preinstalled). Sign in. Load the logger.
2. Launch Chrome from Start (A01). Navigate to `https://www.westminster.ac.uk` (A02). Navigate to `https://www.bbc.co.uk` and click the first headline (A03). Open `https://en.wikipedia.org/wiki/Digital_forensics` and scroll (A04). Navigate to `https://file-examples.com/` and download any small PDF (A05); when Chrome prompts, save to Downloads.
3. Close Chrome (A06). Open File Explorer to Downloads (A07). Close File Explorer (A08).
4. `Save-Log -Scenario 9`. Shut down. Snapshot `scenario9_post`. Acquire.

### 7.10 Scenario 10: System shutdown and power on (1 run)

Scenario 10 is scheduled last so its shutdown and boot logs do not overlap other scenarios.

1. Revert to `baseline_pre_scenarios`. Sign in. Load the logger.
2. `Log-Action A01 start "VM Shutdown"`. Shut down via Start plus Power plus Shut down. Wait until VMware reports the guest powered off.
3. Log A02 start at guest power off, capture host wall clock in the note. After a short settle interval, log A02 end.
4. Power the VM back on. Log A03 start at power on with host wall clock noted; log A03 end when the guest reaches POST.
5. Sign in again. Load the logger. Retrospectively log A01 end, A02, A03 from your notes. Then `Log-Action A04 start "Wait 90s for post boot"`, wait 90 seconds, `Log-Action A04 end`.
6. `Save-Log -Scenario 10`. Shut down cleanly. Snapshot `scenario10_post`. Acquire.

Capture host wall clock manually at A02 start and A03 start so the guest vs host skew can be quantified afterwards.

## 8. Verification and integrity checks

After acquiring each scenario:

1. Confirm the acquisition_manifest.csv row count matches the reported file count in the acquire transcript.
2. Sample re verify: for any row in the manifest, run `Get-FileHash <path> -Algorithm SHA256` and confirm the hash matches.
3. Confirm the parsed CSV row counts are in the expected range. Rough guidance from the original study:

| Artefact | Typical row count per scenario |
|---|---|
| PECmd summary | 340 to 435 |
| PECmd Timeline | 1,190 to 1,470 |
| EvtxECmd output | 30,000 to 34,200 |
| SBECmd UsrClass | 11 to 18 |
| Windowed prefetch | 10 to 150 |
| Windowed EVTX | 60 to 900 |

4. Confirm the correlation_report.txt lists every ground truth action, in order, with counts per artefact class per action.
5. Confirm the correlation_table.md has one row per ground truth action, a verdict on each, and non empty analyst notes.

## 9. Troubleshooting

**VMware time sync drift**: if the guest clock drifts more than a few seconds from host UTC during a run, VMware Tools time sync is off or interfering. Confirm VMware Tools is running and its time sync is on. Scenario 10 will show a several minute skew across shutdown and boot; this is documented as a real finding, not a fault.

**Arsenal Image Mounter mount fails**: close VMware Workstation completely; AIM cannot open a VMDK that VMware still has locked. If mount still fails, run PowerShell as administrator so AIM inherits the required privileges.

**Zimmerman tool version mismatch**: if a tool version different from the original (2026.5.0) produces different row counts or slightly different CSV headers, note the version used in the acquisition_manifest.csv comments and be aware that per action hit counts may differ from the reference numbers in section 8.

**ShellBag entry does not appear in the expected action window**: ShellBag hive writes are asynchronous. The BagMRU entry exists in the parsed CSV but its LastWriteTime is a hive flush moment that may be 30 seconds to several minutes later than the interaction. This is not a failed acquisition; it is a Windows platform behaviour that the correlation methodology accounts for in the analyst notes.

**Windows 11 25H2 renames a Win32 executable to a UWP variant**: Scenario 2 demonstrates this for calc.exe becoming `CALCULATORAPP.EXE`. If a launched binary is missing from Prefetch by its expected name, search for its UWP variant under `\Program Files\WindowsApps\`.

**A duplicate Log-Action end row appears in ground_truth.csv**: this happened in Scenario 7 Run 2 during the original study. If it happens, the later end timestamp is authoritative; the correlate script uses the end field from the last matching row per action code.

**Chromium history is not one of the three project artefacts**: pure browser download actions (Scenario 1 A02 through A07) will always score MISSED or PARTIAL under this study's scope. This is by design; the study documents the gap and cites Chromium history as the fourth class that would be needed to fill it.

## 10. Tool versions used in the original study

Recorded here for exact reproducibility. If your reproduction uses different versions, note the versions you used.

| Tool | Version |
|---|---|
| VMware Workstation Pro | 17 |
| Windows guest | Windows 11 Pro 25H2, build 26200.6584 |
| Arsenal Image Mounter | released 2025.06 |
| PECmd | 2026.5.0 |
| EvtxECmd | 2026.5.0 |
| SBECmd | 2026.5.0 |
| Timeline Explorer | 2026.5.0 (optional, for merged timeline review) |
| Python | 3.10 or later |

Installed applications used across Scenarios 1, 2, 7, 9 (versions as installed during the original Scenario 1 run):

| Application | Version |
|---|---|
| Google Chrome | 151.0.7922.138 |
| WinRAR | 7.23 (winrar-x64-723.exe) |
| VLC Media Player | 3.0.23 |
| Adobe Acrobat Reader DC | 26.001.21771 |
| Zoom Workplace | latest at 16 Aug 2026 |
| Notepad++ | 8.9.6.2 x64 |

## 11. Further reading

- `README.md`: repository overview, scope, licence, citation
- `vm_testbed.md`: full VM baseline configuration and setup detail
- `scenarios/catalogue.md`: matrix of all 10 scenarios and their artefact coverage
- `scenarios/scenario_N/README.md`: per scenario overview with commands, outputs, sample rows, correlation summary
- `scenarios/scenario_N/evaluation/correlation_table.md`: per action verdict with evidence citations
- `scripts/evaluation/evaluation_matrix.md`: cross-scenario roll-up matrix with per-artefact completeness, correlation lift, reproducibility mean, and per-scenario coverage; CSV mirror at `evaluation_matrix.csv`
- `scripts/`: all reproducibility scripts (testbed setup, scenario prep, acquisition, analysis)
- `docs/practical_execution_log.pdf`: 158-page working log of the interactive execution (PowerShell transcripts, sanity-check output, tool screenshots)

For methodology references, see the Key references section of the root `README.md` (Breitinger et al., Vanini et al., Hargreaves and Patterson, Zhu et al., Case et al.).
