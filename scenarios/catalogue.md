# Scenario Catalogue

Formal set of user activity scenarios executed against the working baseline (`baseline_pre_scenarios`, child of `baseline_candidate`) to generate ground truth artefacts for Prefetch, Windows Event Logs, and ShellBags correlation.

Designed to Jade's 2026-08-06 guidance: 10 scenarios total, 5 to 10 per artefact class, 3 headline scenarios in main body, remaining in appendix, every scenario has a row in the [evaluation matrix](../scripts/evaluation/evaluation_matrix.md).

## Scenario folders in numeric order

GitHub sorts the `scenarios/` tree alphabetically, so the folder listing shows `scenario_10` between `scenario_1` and `scenario_2`. The correct execution and reporting order is numeric; use this index rather than the alphabetic folder view.

| # | Scenario | Folder | Placement |
|---|----------|--------|-----------|
| 1 | Install 6 applications | [`scenarios/scenario_1/`](scenario_1/) | Main |
| 2 | Application execution baseline | [`scenarios/scenario_2/`](scenario_2/) | Appendix |
| 3 | Nested folder navigation | [`scenarios/scenario_3/`](scenario_3/) | Appendix |
| 4 | USB attach, browse, execute from USB | [`scenarios/scenario_4/`](scenario_4/) | Main |
| 5 | File deletion via Explorer and Recycle Bin | [`scenarios/scenario_5/`](scenario_5/) | Appendix |
| 6 | Logon, lock, unlock, logoff cycle | [`scenarios/scenario_6/`](scenario_6/) | Appendix |
| 7 | Save As from Notepad++ to Documents | [`scenarios/scenario_7/`](scenario_7/) | Main |
| 8 | Command line execution (cmd, PowerShell) | [`scenarios/scenario_8/`](scenario_8/) | Appendix |
| 9 | Web browsing session with download | [`scenarios/scenario_9/`](scenario_9/) | Appendix |
| 10 | System shutdown and power on | [`scenarios/scenario_10/`](scenario_10/) | Appendix |

## Catalogue authority

This catalogue describes the **executed protocol** for every scenario. Where an earlier draft of a scenario differed from what was actually run at the keyboard (S07's Save As dropped the per-rep subfolder step; S09's URL set moved from placeholders to real research-context sites), the catalogue was updated post-execution to describe the study of record. Two things follow from that:

1. The evaluation matrix (`scripts/evaluation/evaluation_matrix.md`) measures artefact evidence against **this** catalogue, not against a superseded draft. Rows that a draft-based reading would have scored FAIL because a draft step was not executed are not present in the matrix.
2. The per-run `evaluation/ground_truth.csv` files under `scenarios/scenario_N/run_M/` may carry a PRE-row note that refers to the earlier draft ("DEVIATION from catalogue: ..."). Those notes are the researcher's contemporaneous record and are preserved for provenance. They document divergence from the pre-execution draft, not from the current catalogue.

## Constraints

- Anti forensic behaviour is out of scope.
- Each scenario begins from a clean revert of `baseline_pre_scenarios` and ends with a post scenario snapshot before acquisition. Snapshot names: `scenario{N}_post` for single run scenarios; `scenario{N}_run{M}_post` for multi run scenarios (Scenarios 4 and 7 only).
- Ground truth per run is recorded by the `Log-Action` helper (see `scripts/scenarios/log_action.ps1`) and exported to `scenarios/scenario_N/evaluation/ground_truth.csv` (single run) or `scenarios/scenario_N/run_M/evaluation/ground_truth.csv` (multi run).
- Repetition count per scenario is tiered. See "Repetitions" below.

## Repetitions

Tiered per scenario based on where reproducibility genuinely strengthens the finding vs where it just repeats deterministic behaviour:

| Scenario | Reps | Rationale |
|----------|:----:|-----------|
| Scenario 1 Install applications | 1 | Installer output is deterministic; three repetitions would just repeat known Windows install behaviour without strengthening the correlation claim. |
| Scenario 4 USB attach and execute | 3 | PnP timing and enumeration order can vary; three attaches meaningfully confirm the same VID, PID, serial reliably appears. |
| Scenario 7 Save As from Notepad++ to Documents | 3 | The Save As common dialog "writes to ShellBags" behaviour has historical Windows edge cases; three reps confirm the 7-row `UsrClass` pattern is stable across runs. |
| Scenario 2, Scenario 3, Scenario 5, Scenario 6, Scenario 8, Scenario 9, Scenario 10 | 1 each | Qualitative pass or fail in the evaluation matrix is sufficient for appendix scenarios. |

Total runs: 1 + 3 + 3 + 7 = 14 runs.

Evaluation matrix rows for Scenario 4 and Scenario 7 report `N/3` reproducibility; all other rows are `PASS`, `PART`, or `FAIL` qualitative only.

## Coverage matrix

Main body scenarios are all three artefact by design (correlation across `PF + EVTX + SBags` is the core research contribution). Appendix scenarios include partial coverage cases that act as negative controls or isolate single artefact evidential value.

| ID  | Scenario                                       | PF | EVTX | SBags | Placement |
|-----|------------------------------------------------|:--:|:----:|:-----:|:---------:|
| Scenario 1 | Install 6 applications                         | X  | X    | X     | Main      |
| Scenario 4 | USB attach, browse, execute from USB           | X  | X    | X     | Main      |
| Scenario 7 | Save As from Notepad++ to Documents             | X  | X    | X     | Main      |
| Scenario 2 | Application execution baseline                 | X  | X    |       | Appendix  |
| Scenario 3 | Nested folder navigation                       |    |      | X     | Appendix  |
| Scenario 5 | File deletion via Explorer + Recycle Bin       | X  | X    | X     | Appendix  |
| Scenario 6 | Logon, lock, unlock, logoff cycle              |    | X    |       | Appendix  |
| Scenario 8 | Command line execution (cmd, PowerShell)       | X  | X    |       | Appendix  |
| Scenario 9 | Web browsing session with download             | X  | X    | X     | Appendix  |
| Scenario 10 | System shutdown and power on                   | X  | X    |       | Appendix  |

Per artefact totals:

- Prefetch: Scenario 1, Scenario 2, Scenario 4, Scenario 5, Scenario 7, Scenario 8, Scenario 9, Scenario 10 = 8
- Event Logs: Scenario 1, Scenario 2, Scenario 4, Scenario 5, Scenario 6, Scenario 7, Scenario 8, Scenario 9, Scenario 10 = 9
- ShellBags: Scenario 1, Scenario 3, Scenario 4, Scenario 5, Scenario 7, Scenario 9 = 6

All three fall in the 5 to 10 band.

## Network policy

NAT is approved by Jade (meeting 2026-08-06). Two scenarios need internet:

- Scenario 1 (download 6 installers)
- Scenario 9 (real web browsing and download)

Other scenarios can run with NAT or host only, with no operational difference for their target artefacts.

## Repository landing zones

Per run outputs land under the numbered scenario and run folders:

Single run scenarios (Scenarios 1, 2, 3, 5, 6, 8, 9, 10) land flat under the scenario folder:

```
scenarios/scenario_N/
    artefacts/prefetch/
    artefacts/event_logs/
    artefacts/shellbags/
    artefacts/supporting/          (SYSTEM, SOFTWARE, Amcache.hve, acquisition_manifest.csv)
    evaluation/                    (ground_truth.csv, per run evaluation notes)
```

Multi run scenarios (Scenarios 4 and 7) get one `run_M/` subfolder per repetition, with the same internal layout:

```
scenarios/scenario_N/run_M/
    artefacts/prefetch/
    artefacts/event_logs/
    artefacts/shellbags/
    artefacts/supporting/
    evaluation/
```

Raw binary artefacts (`.pf`, `.evtx`, hive files) are not committed to git; only the SHA 256 `acquisition_manifest.csv` per run is committed for chain of custody documentation.

## Execution order

Executed in numeric order (Scenario 1 to Scenario 10) per repetition. Each run is preceded by a revert to `baseline_pre_scenarios` (working baseline) and followed by a post scenario snapshot per `vm_testbed.md` naming.

For every scenario, in every repetition:

1. Pre run. Revert the VM to `baseline_pre_scenarios`. Power on, sign in as `dfanalyst`, wait 60 s for background settle.
2. Load the log helper. In guest PowerShell, dot source `scripts/scenarios/log_action.ps1` (or paste the function inline). Call `Log-Action A0N start "description"` before each action and `Log-Action A0N end` after.
3. Execute steps in the order given for the scenario.
4. Post run. Wait 90 s for background settle. Export the action log to CSV via `Save-Log -Scenario N` (single run) or `Save-Log -Scenario N -Run M` (multi run). Shut down the guest cleanly (Start, Power, Shut down).
5. Snapshot. From the powered off state, take snapshot named `scenario{N}_post` (single run) or `scenario{N}_run{M}_post` (multi run).
6. Acquire. From the host, run `scripts/scenarios/acquire_artefacts.ps1 -Scenario N` (single run) or `scripts/scenarios/acquire_artefacts.ps1 -Scenario N -Run M` (multi run).
7. File. Raw artefacts land under `scenarios/scenario_N/artefacts/{class}/` (single run) or `scenarios/scenario_N/run_M/artefacts/{class}/` (multi run); ground truth CSV goes into the same run's `evaluation/ground_truth.csv`.

Cross scenario notes:

- NAT scenarios (Scenario 1, Scenario 9): NAT is approved by Jade (2026-08-06). No policy switch needed between scenarios; NAT stays on.
- USB scenario (Scenario 4): use the same physical USB stick across all 3 reps so VID, PID, serial are constant and evaluation matrix rows are comparable.
- Scenario 1 dependency for Scenarios 2, 7, 9: these all depend on apps installed in Scenario 1. Simplest workflow is to run Scenario 1 first, and use its `scenario1_post` snapshot as the starting point for Scenarios 2, 7, 9 instead of reverting to `baseline_pre_scenarios` and reinstalling every time.
- Ordering: run scenarios in the order Scenario 1, Scenario 7 (all reps), Scenario 4 (all reps), Scenario 2, Scenario 3, Scenario 5, Scenario 6, Scenario 8, Scenario 9, Scenario 10. Scenario 10 last because it changes shutdown and boot logs the analyst wants to reason about after other traces are captured.

## Headline scenarios (main body)

### Scenario 1. Install 6 applications (main, NAT required, 1 rep)

Rationale: application install is the richest single event for correlation. It leaves traces in all three artefact classes at once, plus registry uninstall keys and MSI Installer logs that support the discussion.

Applications installed (mix of installer types and categories to diversify EVTX signatures):

| # | Application               | Category            | Installer type              | URL                                    | Approx size |
|---|---------------------------|---------------------|-----------------------------|----------------------------------------|-------------|
| 1 | Google Chrome             | Browser             | Stub, multi process         | https://www.google.com/chrome/         | 12 MB stub  |
| 2 | WinRAR                    | Archiver            | NSIS based (simple)         | https://www.win-rar.com/download.html  | 4 MB        |
| 3 | VLC Media Player          | Media player        | NSIS based (simple)         | https://www.videolan.org/vlc/          | 45 MB       |
| 4 | Adobe Acrobat Reader DC   | PDF reader          | MSI based (strong signal)   | https://get.adobe.com/reader/          | ~200 MB     |
| 5 | Zoom Workplace            | Video conferencing  | MSI based + service install | https://zoom.us/download               | 50 MB       |
| 6 | Notepad++                 | Text editor         | NSIS based (simple)         | https://notepad-plus-plus.org/downloads| 7 MB        |

Manual steps (as `dfanalyst` user):

1. A01. Open Microsoft Edge from Start.
2. A02. In Edge, go to `https://www.google.com/chrome/`, click Download Chrome, save `ChromeSetup.exe` to `Downloads`.
3. A03. In Edge, go to `https://www.win-rar.com/download.html`, click the English 64 bit `.exe` link, save to `Downloads`. Record exact filename.
4. A04. In Edge, go to `https://www.videolan.org/vlc/`, click Download VLC, save `vlc-*-win64.exe` to `Downloads`. Record exact filename.
5. A05. In Edge, go to `https://get.adobe.com/reader/`. Untick any optional offers. Click Download Acrobat Reader, save `readerdc*setup.exe` to `Downloads`. Record exact filename.
6. A06. In Edge, go to `https://zoom.us/download`, click Download for Zoom Workplace, save `ZoomInstallerFull.*` to `Downloads`. Record exact filename.
7. A07. In Edge, go to `https://notepad-plus-plus.org/downloads/`, click the current version, then the Installer 64 bit x64 link, save `npp.*.Installer.x64.exe` to `Downloads`. Record exact filename and version.
8. A08. Close Edge.
9. A09. Open File Explorer, navigate to `%USERPROFILE%\Downloads`. Confirm all 6 installers present.
10. A10. Double click `ChromeSetup.exe`. UAC, Yes. Wait for install. Close Chrome when it auto launches (do not sign in).
11. A11. Double click the WinRAR installer. UAC, Yes. Click Install (accept defaults). Click OK on the setup complete dialog, then Done.
12. A12. Double click the VLC installer. UAC, Yes. Accept defaults through the wizard. Click Install. On completion, untick "Run VLC" and click Finish.
13. A13. Double click the Adobe Reader installer. UAC, Yes. Wait for the stub to download the full package and install. Close Adobe Reader if it auto launches.
14. A14. Double click the Zoom installer. UAC, Yes. Wait for install. If Zoom app opens at end, close it. Do not sign in.
15. A15. Double click the Notepad++ installer. UAC, Yes. Defaults through wizard. Untick "Run Notepad++" at Finish.

Expected artefacts:

- Prefetch: `.pf` for each installer EXE (e.g. `CHROMESETUP.EXE-*.pf`, `WINRAR-X64-*.exe-*.pf`) and for the newly installed EXEs launched at end of install (Chrome, Adobe, Zoom typically auto launch).
- Event Logs (Application): `MsiInstaller 1033` (product installed), `1040` and `1042` (transaction begin and end), `11707` (install success). Strongest for Adobe and Zoom.
- Event Logs (System): `7045` (service install). Expected for Zoom auto updater.
- Event Logs (Security): `4688` process creation of `msiexec.exe`, installer EXEs, elevated child processes.
- ShellBags (`UsrClass.dat`): entry for the Downloads folder.

Ground truth: URL fetched, installer filename, install start and end UTC, uninstall registry key GUID (recorded post install for the report).

Post run notes: record the Uninstall registry GUIDs for the six products from `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\` and `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\` for the discussion chapter.

Correlation problem: stitch download to install to first run chain per app across three artefact classes.

### Scenario 4. USB attach, browse, execute from USB (main, 3 reps)

Rationale: Jade's worked example. Loads all three artefact classes in one contained workflow, including PnP events unique to removable media.

Precondition: a controlled USB stick prepared as follows before the run. Single NTFS partition, volume label `DISS-USB`, contents `\PORTABLE\HelloWorld.exe` (any small compiled console app). Record VID, PID, and serial from Device Manager on the host before insertion. Same physical stick across all 3 reps.

Manual steps:

1. A01. From host, connect the USB stick to the VM (VMware, VM, Removable Devices, `<device>`, Connect).
2. A02. In the guest, wait for the "device ready" notification. Confirm drive letter assigned.
3. A03. Open File Explorer, navigate to the assigned drive root. Wait 5 s.
4. A04. Navigate into `\PORTABLE\`. Wait 5 s.
5. A05. Double click `HelloWorld.exe`. Let it run and self close (or close the console window).
6. A06. Right click the USB drive in Explorer left pane, `Eject`. Wait for the "safe to remove" notification.
7. A07. From host, disconnect the USB device (VMware, VM, Removable Devices, `<device>`, Disconnect).

Ground truth: device VID, PID, serial; attach UTC; folder paths browsed with UTC per click; EXE launched with UTC; eject UTC. Rows A01 to A07 plus a dedicated `USB_VIDPIDSERIAL` row with device identity in `TargetPath`.

Expected artefacts:

- Prefetch: `HELLOWORLD.EXE-*.pf` with volume path field pointing to the removable volume.
- Event Logs (System): `20001` (PnP device install), USB Hub `43` where applicable, `225` (device eject) at end.
- Event Logs (DriverFrameworks UserMode Operational): `2003`, `2010`, `2100`.
- Event Logs (Partition Diagnostic): `1006` with model, serial, VID, PID.
- ShellBags: entry for the USB volume root and `\PORTABLE\` folder in `UsrClass.dat`.

Correlation problem: device to file provenance. Map a specific USB hardware ID to specific folders browsed on it to a specific executable run from it.

### Scenario 7. Save As from Notepad++ to Documents (main, 3 reps)

Rationale: hits all three artefact classes with a normal editing and file creation workflow that doesn't overlap Scenario 1 (install) or Scenario 4 (USB device). Uses Notepad++ installed in Scenario 1, no additional software or hardware required.

Precondition: Notepad++ installed (from Scenario 1). If starting from `baseline_pre_scenarios`, run Scenario 1 once first (single install rep is sufficient for the required Notepad++ presence).

Manual steps (7 actions per run, executed identically across Runs 1, 2 and 3):

1. A01. From Start, launch `notepad++.exe`. Wait for main window.
2. A02. In the blank tab, type: `Scenario 7 test content <UTC timestamp>` (paste the current UTC as a distinctive marker per rep).
3. A03. Menu File, Save As. In the Save As dialog, navigate to `%USERPROFILE%\Documents` (address bar paste and Enter) and save as `scenario7_test_file.txt` (Notepad++ default filter appends `.txt`). File is written to the `Documents` root; no per-rep subfolder is created.
4. A04. Close Notepad++ (X button; the file is already saved so no prompt appears).
5. A05. Open File Explorer and navigate to `%USERPROFILE%\Documents` to verify the saved file.
6. A06. View the file in the Explorer window (single click to select; open only if needed).
7. A07. Close File Explorer and any remaining Notepad++ windows.

Ground truth: launch UTC, save UTC, close UTC, target file full path. Rows PRE, A01 to A07; record the exact filename saved in `TargetPath` and the UTC marker string pasted into the file body in `Note` on A02.

Expected artefacts:

- Prefetch: `NOTEPAD++.EXE-*.pf` with first and last run time matching the launch UTC. Across the 3 reps, run count should equal 3. `NOTEPAD.EXE-*.pf` also appears in A05 to A07 as an Explorer preview side effect for `.txt` files.
- Event Logs (Security): `4688` process creation for `notepad++.exe` with command line populated; `4663` object write on the saved file path.
- ShellBags (`UsrClass.dat`): the Save As common dialog uses `IShellBrowser` and writes ShellBag entries for `Documents` and the Notepad++ program folder the same way Explorer navigation does. Executed protocol produces a stable 7-row `UsrClass` pattern including `Documents` and `Program Files\Notepad++` in every run.

Correlation problem: tie application execution (`4688` and Prefetch) to file creation location (ShellBags for the Save As navigation target, plus 4663 object write on the saved file path). Answers "which running program created which file where".

Note on protocol. An earlier draft of this scenario included a per-rep subfolder creation step inside the Save As dialog and a save into that subfolder. That step was dropped before Run 1 (the Save As dialog's folder-creation control was fiddly and reduced reproducibility across runs without adding a new artefact class beyond what the plain Save As already produces). All three runs were executed with the 7-action protocol described above. The per-run `evaluation/ground_truth.csv` files carry a PRE-row note referring to that earlier draft; those notes are historical and refer to the pre-execution draft, not to a mid-study protocol change.

## Appendix scenarios

### Scenario 2. Application execution baseline (appendix, 1 rep)

Cleanest Prefetch story. User launches the apps installed in Scenario 1 plus two Windows built ins in a controlled sequence. Isolates Prefetch run count and first and last run behaviour.

Precondition: apps installed via Scenario 1 (Chrome, WinRAR, VLC, Notepad++ used here; Adobe and Zoom excluded because they auto run background services that pollute the sequence).

Manual steps (repeated internally 3 times within the single run to prove run count):

1. A01. From Start, launch `notepad.exe`. Wait 10 s. Close it.
2. A02. From Start, launch `calc.exe`. Wait 10 s. Close it.
3. A03. From Start, launch `chrome.exe`. Wait 10 s. Close it.
4. A04. From Start, launch `winrar.exe`. Wait 10 s. Close it.
5. A05. From Start, launch `vlc.exe`. Wait 10 s. Close it.
6. A06. From Start, launch `notepad++.exe`. Wait 10 s. Close it.

Repeat A01 to A06 twice more within the same run.

Expected: one `.pf` per unique EXE with run count = 3 and last run time matching the third launch; `Security 4688` per launch with command line. Ground truth CSV: one row per launch and close pair (18 rows total per run); note the third launch UTC per app.

### Scenario 3. Nested folder navigation (appendix, 1 rep)

Cleanest ShellBags story. User opens Explorer and clicks down a five level nested path with no execution. Provides the "browsed vs not browsed" positive and negative control by leaving sibling folder untouched.

Precondition: create this tree in the guest before starting the run:

```
C:\DISS_TESTDATA\NAV\
    LEVEL1_A\
        LEVEL2_A\
            LEVEL3_A\
                LEVEL4_A\
                    LEVEL5_A\
    LEVEL1_B\   (negative control, never browse this)
```

Manual steps:

1. A01. Open File Explorer.
2. A02. Navigate to `C:\DISS_TESTDATA\NAV\`. Wait 3 s.
3. A03. Double click `LEVEL1_A`. Wait 3 s.
4. A04. Double click `LEVEL2_A`. Wait 3 s.
5. A05. Double click `LEVEL3_A`. Wait 3 s.
6. A06. Double click `LEVEL4_A`. Wait 3 s.
7. A07. Double click `LEVEL5_A`. Wait 3 s.
8. A08. Close Explorer.

Do not open `LEVEL1_B` at any point.

Expected: one ShellBags entry per folder in `UsrClass.dat`; `LEVEL1_B` absent; `EXPLORER.EXE-*.pf` volume references only. Ground truth CSV: rows A01 to A08.

### Scenario 5. File deletion via Explorer and Recycle Bin (appendix, 1 rep)

Delete a staged file to Recycle Bin, then empty. Tests correlation across ShellBags (Recycle Bin shell folder), Prefetch (`EXPLORER.EXE` volume refs) and Event Logs.

Precondition: place a staged file at `C:\DISS_TESTDATA\DELETE\scenario5_target.txt` before starting the run.

Manual steps:

1. A01. Open File Explorer, navigate to `C:\DISS_TESTDATA\DELETE\`.
2. A02. Right click `scenario5_target.txt`, Delete (sends to Recycle Bin).
3. A03. Open Recycle Bin (double click desktop icon).
4. A04. Confirm `scenario5_target.txt` is listed.
5. A05. Right click Recycle Bin icon on Desktop, Empty Recycle Bin. Confirm.

Expected: `EXPLORER.EXE-*.pf` with `\$Recycle.Bin\` in referenced paths; `Security 4663` if object access auditing is enabled and the SACL applies; ShellBag entry for the source folder and Recycle Bin shell folder. Ground truth CSV: rows A01 to A05.

### Scenario 6. Logon, lock, unlock, logoff cycle (appendix, 1 rep)

Sign out, sign in, lock (`Win+L`), unlock, sign out. Pure Event Logs scenario: no Prefetch, no ShellBags. Negative control for PF and SBags; tests `Security 4624`, `4634`, `4800`, `4801` including logon type.

Manual steps:

1. A01. Sign out of `dfanalyst` (Start, user icon, Sign out).
2. A02. At the lock screen, sign back in with password.
3. A03. Press `Win+L` to lock the workstation.
4. A04. Wait 15 s.
5. A05. Unlock with password.
6. A06. Sign out again.
7. A07. Sign back in.

Expected: `4624` logon (type 2 for interactive), `4634` logoff, `4800` workstation locked, `4801` workstation unlocked. Logon type is critical evidence. Ground truth CSV: rows A01 to A07.

### Scenario 8. Command line execution (cmd, PowerShell) (appendix, 1 rep)

Open `cmd.exe`, run `whoami` and `dir`; open `powershell.exe`, run `Get-Process`. Tests Prefetch for shell hosts and `Security 4688` with command line arguments.

Manual steps:

1. A01. From Start, launch `cmd.exe`.
2. A02. In cmd, type `whoami` and press Enter.
3. A03. In cmd, type `dir C:\Windows` and press Enter.
4. A04. Close cmd.
5. A05. From Start, launch `powershell.exe`.
6. A06. In PowerShell, type `Get-Process` and press Enter.
7. A07. Close PowerShell.

Expected: `CMD.EXE-*.pf`, `POWERSHELL.EXE-*.pf`, `CONHOST.EXE-*.pf`; `Security 4688` process creation with `ProcessCommandLine` populated. Ground truth CSV: rows A01 to A07; record exact command strings in `TargetPath`.

### Scenario 9. Web browsing session with download (appendix, NAT required, 1 rep)

Launch Chrome, visit three real websites of increasing TLS and content complexity, download a sample file, open Downloads folder in Explorer, close browser. Tests Prefetch for browser and helper processes, `Security 4688` process creation chain, TLS chain validation events, and ShellBags entry for the `Downloads` folder.

Precondition: Chrome installed (from Scenario 1). NAT enabled (Jade approved 2026-08-06).

Manual steps (8 actions):

1. A01. From Start, launch `chrome.exe`.
2. A02. Navigate to `https://www.westminster.ac.uk/` (University of Westminster). Wait 5 s. Chosen as a distinctive TLS chain and a page the researcher can attribute unambiguously.
3. A03. Navigate to `https://www.bbc.co.uk/` and open the first headline. Wait 5 s.
4. A04. Navigate to `https://en.wikipedia.org/wiki/Digital_forensics` and scroll. Wait 5 s. Chosen for cached TLS chain behaviour (chrome helper churn without a new CAPI2 record).
5. A05. Navigate to File Examples (`https://file-examples.com/`) and download a small sample PDF. Wait for the download to complete.
6. A06. Close Chrome.
7. A07. Open File Explorer, navigate to `%USERPROFILE%\Downloads` and confirm the downloaded file is present. Note the filename.
8. A08. Close File Explorer.

Expected: `CHROME.EXE-*.pf` (main and helper processes); `Security 4688` for `chrome.exe` and helper processes; CAPI2 `4097` on the first TLS chain of the run and silence thereafter for cached chains; `Acrobat` Prefetch cluster if the downloaded PDF is opened as a side effect; ShellBag entry for `Downloads`. Ground truth CSV: rows PRE, A01 to A08; record URLs in `Note`, download filename in a dedicated row.

Note on protocol. An earlier draft named `example.com`, `bbc.co.uk` and a `testfile.org` PDF as placeholder URLs. The executed protocol replaced the placeholder set with real research-context URLs (`westminster.ac.uk`, a live BBC headline, and a Wikipedia article) plus a File Examples PDF for the download; three URLs and a download are still visited, so the intent of the scenario is unchanged.

### Scenario 10. System shutdown and power on (appendix, 1 rep)

Clean shutdown, power on, log back in. Tests Event Logs shutdown and boot chain and Prefetch layout regeneration.

Manual steps:

1. A01. From Start, Power, Shut down. Confirm.
2. A02. After the VM powers off (verify from host), wait 30 s.
3. A03. Power on the VM from host.
4. A04. Wait for the sign in screen.
5. A05. Sign in as `dfanalyst`.
6. A06. Once desktop loads, wait 90 s for post boot Prefetch layout regeneration before snapshotting.

Expected: `System 1074` shutdown initiated, `6006` event log stopped, `6005` event log started, `12` kernel start, `13` kernel shutdown, `27` boot mgr; `Security 4624` type 2 interactive logon at A05; `layout.ini` regeneration and startup application `.pf` files. Ground truth CSV: rows A01 to A06; note exact power off UTC (from host) and power on UTC.
