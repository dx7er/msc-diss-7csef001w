# Scenario Catalogue

Formal set of user activity scenarios executed against the working baseline (`S00-UNIVERSAL-PRE`, child of `B00-CANDIDATE-W11-25H2-26200.6584-20260717`) to generate ground truth artefacts for Prefetch, Windows Event Logs, and ShellBags correlation.

Designed to Jade's 2026-08-06 guidance: 10 scenarios total, 5 to 10 per artefact class, 3 headline scenarios in main body, remaining in appendix, every scenario has a row in the [evaluation matrix](../scripts/evaluation/evaluation_matrix_template.md).

## Constraints

- Anti forensic behaviour is out of scope.
- Each scenario begins from a clean revert of `S00-UNIVERSAL-PRE` and ends with a `SNN-RNN-POST` snapshot before acquisition.
- Ground truth per run is recorded by the `Log-Action` helper (see `scripts/scenarios/log_action.ps1`) and exported to `scenarios/scenario_N/run_M/evaluation/ground_truth.csv`.
- Repetition count per scenario is tiered. See "Repetitions" below.

## Repetitions

Tiered per scenario based on where reproducibility genuinely strengthens the finding vs where it just repeats deterministic behaviour:

| Scenario | Reps | Rationale |
|----------|:----:|-----------|
| S01 Install applications | 1 | Installer output is deterministic; three repetitions would just repeat known Windows install behaviour without strengthening the correlation claim. |
| S04 USB attach and execute | 3 | PnP timing and enumeration order can vary; three attaches meaningfully confirm the same VID, PID, serial reliably appears. |
| S07 Save As from Notepad++ | 3 | The Save As common dialog "writes to ShellBags" behaviour has historical Windows edge cases; three reps confirm the pattern is stable. |
| S02, S03, S05, S06, S08, S09, S10 | 1 each | Qualitative pass or fail in the evaluation matrix is sufficient for appendix scenarios. |

Total runs: 1 + 3 + 3 + 7 = 14 runs.

Evaluation matrix rows for S04 and S07 report `N/3` reproducibility; all other rows are `PASS`, `PART`, or `FAIL` qualitative only.

## Coverage matrix

Main body scenarios are all three artefact by design (correlation across `PF + EVTX + SBags` is the core research contribution). Appendix scenarios include partial coverage cases that act as negative controls or isolate single artefact evidential value.

| ID  | Scenario                                       | PF | EVTX | SBags | Placement |
|-----|------------------------------------------------|:--:|:----:|:-----:|:---------:|
| S01 | Install 6 applications                         | X  | X    | X     | Main      |
| S04 | USB attach, browse, execute from USB           | X  | X    | X     | Main      |
| S07 | Save As from Notepad++ to new subfolder        | X  | X    | X     | Main      |
| S02 | Application execution baseline                 | X  | X    |       | Appendix  |
| S03 | Nested folder navigation                       |    |      | X     | Appendix  |
| S05 | File deletion via Explorer + Recycle Bin       | X  | X    | X     | Appendix  |
| S06 | Logon, lock, unlock, logoff cycle              |    | X    |       | Appendix  |
| S08 | Command line execution (cmd, PowerShell)       | X  | X    |       | Appendix  |
| S09 | Web browsing session with download             | X  | X    | X     | Appendix  |
| S10 | System shutdown and power on                   | X  | X    |       | Appendix  |

Per artefact totals:

- Prefetch: S01, S02, S04, S05, S07, S08, S09, S10 = 8
- Event Logs: S01, S02, S04, S05, S06, S07, S08, S09, S10 = 9
- ShellBags: S01, S03, S04, S05, S07, S09 = 6

All three fall in the 5 to 10 band.

## Network policy

NAT is approved by Jade (meeting 2026-08-06). Two scenarios need internet:

- S01 (download 6 installers)
- S09 (real web browsing and download)

Other scenarios can run with NAT or host only, with no operational difference for their target artefacts.

## Repository landing zones

Per run outputs land under the numbered scenario and run folders:

```
scenarios/scenario_N/run_M/
    artefacts/prefetch/
    artefacts/event_logs/
    artefacts/shellbags/
    artefacts/supporting/          (SYSTEM, SOFTWARE, Amcache.hve, acquisition_manifest.csv)
    evaluation/                    (ground_truth.csv, per run evaluation notes)
```

Raw binary artefacts (`.pf`, `.evtx`, hive files) are not committed to git; only the SHA 256 `acquisition_manifest.csv` per run is committed for chain of custody documentation.

## Execution order

Executed in numeric order (S01 to S10) per repetition. Each run is preceded by a revert to `S00-UNIVERSAL-PRE` (working baseline) and followed by an `SNN-RNN-POST` snapshot per `vm_testbed.md` naming.

For every scenario, in every repetition:

1. Pre run. Revert the VM to `S00-UNIVERSAL-PRE`. Power on, sign in as `dfanalyst`, wait 60 s for background settle.
2. Load the log helper. In guest PowerShell, dot source `scripts/scenarios/log_action.ps1` (or paste the function inline). Call `Log-Action A0N start "description"` before each action and `Log-Action A0N end` after.
3. Execute steps in the order given for the scenario.
4. Post run. Wait 90 s for background settle. Export the action log to CSV. Shut down the guest cleanly (Start, Power, Shut down).
5. Snapshot. Take `SNN-RNN-POST` snapshot in VMware from the powered off state.
6. Acquire. From the host, run `scripts/scenarios/acquire_artefacts.ps1 -Scenario SNN -Run RNN`.
7. File. Raw artefacts land under `scenarios/scenario_N/run_M/artefacts/{class}/`; ground truth CSV under `scenarios/scenario_N/run_M/evaluation/ground_truth.csv`.

Cross scenario notes:

- NAT scenarios (S01, S09): NAT is approved by Jade (2026-08-06). No policy switch needed between scenarios; NAT stays on.
- USB scenario (S04): use the same physical USB stick across all 3 reps so VID, PID, serial are constant and evaluation matrix rows are comparable.
- S01 dependency for S02, S07, S09: these all depend on apps installed in S01. Simplest workflow is to run S01 first, take a `POST-S01` snapshot, and use that snapshot as the starting point for S02, S07, S09 runs instead of reverting to `S00-UNIVERSAL-PRE` and reinstalling every time.
- Ordering: run scenarios in the order S01, S07 (all reps), S04 (all reps), S02, S03, S05, S06, S08, S09, S10. S10 last because it changes shutdown and boot logs the analyst wants to reason about after other traces are captured.

## Headline scenarios (main body)

### S01. Install 6 applications (main, NAT required, 1 rep)

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

### S04. USB attach, browse, execute from USB (main, 3 reps)

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

### S07. Save As from Notepad++ to new Documents subfolder (main, 3 reps)

Rationale: hits all three artefact classes with a normal editing and file creation workflow that doesn't overlap S01 (install) or S04 (USB device). Uses Notepad++ installed in S01, no additional software or hardware required.

Precondition: Notepad++ installed (from S01). If starting from `S00-UNIVERSAL-PRE`, run S01 once first (single install rep is sufficient for the required Notepad++ presence).

Manual steps:

1. A01. From Start, launch `notepad++.exe`. Wait for main window.
2. A02. In the blank tab, type: `S07 test content <UTC timestamp>` (paste the current UTC as a distinctive marker per rep).
3. A03. Menu File, Save As.
4. A04. In the Save As dialog, click into the address bar and paste `%USERPROFILE%\Documents`. Press Enter.
5. A05. Right click empty space in the dialog file area, New, Folder. Name it `S07_Output_R<NN>` where `<NN>` is the repetition number. Press Enter.
6. A06. Double click `S07_Output_R<NN>` to enter it.
7. A07. In the filename field, enter `s07_test_R<NN>.txt`. Click Save.
8. A08. Close Notepad++ (X button; if prompted to save, click No, the file is already saved).

Ground truth: launch UTC, save UTC, close UTC, target file full path. Rows A01 to A08; record the exact filename saved in `TargetPath` and the folder name created in `ObservedOutcome`.

Expected artefacts:

- Prefetch: `NOTEPAD++.EXE-*.pf` with first and last run time matching the launch UTC. Across the 3 reps, run count should equal 3.
- Event Logs (Security): `4688` process creation for `notepad++.exe` with command line populated.
- ShellBags (`UsrClass.dat`): entries for `Documents` and for the newly created `S07_Output_R<NN>` subfolder per rep. The Save As common dialog uses `IShellBrowser` and writes ShellBag entries the same way Explorer navigation does.

Correlation problem: tie application execution (`4688` and Prefetch) to file creation location (ShellBags for the new subfolder). Answers "which running program created which file where".

## Appendix scenarios

### S02. Application execution baseline (appendix, 1 rep)

Cleanest Prefetch story. User launches the apps installed in S01 plus two Windows built ins in a controlled sequence. Isolates Prefetch run count and first and last run behaviour.

Precondition: apps installed via S01 (Chrome, WinRAR, VLC, Notepad++ used here; Adobe and Zoom excluded because they auto run background services that pollute the sequence).

Manual steps (repeated internally 3 times within the single run to prove run count):

1. A01. From Start, launch `notepad.exe`. Wait 10 s. Close it.
2. A02. From Start, launch `calc.exe`. Wait 10 s. Close it.
3. A03. From Start, launch `chrome.exe`. Wait 10 s. Close it.
4. A04. From Start, launch `winrar.exe`. Wait 10 s. Close it.
5. A05. From Start, launch `vlc.exe`. Wait 10 s. Close it.
6. A06. From Start, launch `notepad++.exe`. Wait 10 s. Close it.

Repeat A01 to A06 twice more within the same run.

Expected: one `.pf` per unique EXE with run count = 3 and last run time matching the third launch; `Security 4688` per launch with command line. Ground truth CSV: one row per launch and close pair (18 rows total per run); note the third launch UTC per app.

### S03. Nested folder navigation (appendix, 1 rep)

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

### S05. File deletion via Explorer and Recycle Bin (appendix, 1 rep)

Delete a staged file to Recycle Bin, then empty. Tests correlation across ShellBags (Recycle Bin shell folder), Prefetch (`EXPLORER.EXE` volume refs) and Event Logs.

Precondition: place a staged file at `C:\DISS_TESTDATA\DELETE\S05_target.txt` before starting the run.

Manual steps:

1. A01. Open File Explorer, navigate to `C:\DISS_TESTDATA\DELETE\`.
2. A02. Right click `S05_target.txt`, Delete (sends to Recycle Bin).
3. A03. Open Recycle Bin (double click desktop icon).
4. A04. Confirm `S05_target.txt` is listed.
5. A05. Right click Recycle Bin icon on Desktop, Empty Recycle Bin. Confirm.

Expected: `EXPLORER.EXE-*.pf` with `\$Recycle.Bin\` in referenced paths; `Security 4663` if object access auditing is enabled and the SACL applies; ShellBag entry for the source folder and Recycle Bin shell folder. Ground truth CSV: rows A01 to A05.

### S06. Logon, lock, unlock, logoff cycle (appendix, 1 rep)

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

### S08. Command line execution (cmd, PowerShell) (appendix, 1 rep)

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

### S09. Web browsing session with download (appendix, NAT required, 1 rep)

Launch Chrome, visit three URLs, download a small file, open Downloads folder in Explorer, close browser. Tests Prefetch for browser and helper processes, `Security 4688` process creation chain, and ShellBags entry for Downloads folder.

Precondition: Chrome installed (from S01).

Manual steps:

1. A01. From Start, launch `chrome.exe`.
2. A02. Navigate to `https://example.com/`. Wait 5 s.
3. A03. Navigate to `https://www.bbc.co.uk/`. Wait 5 s.
4. A04. Navigate to a small file URL (e.g. `https://files.testfile.org/PDF/10MB-TESTFILE.ORG.pdf`). Chrome will download to `Downloads`.
5. A05. Wait for download to complete.
6. A06. Close Chrome.
7. A07. Open File Explorer, navigate to `%USERPROFILE%\Downloads`.
8. A08. Confirm downloaded file present. Note filename.
9. A09. Close Explorer.

Expected: `CHROME.EXE-*.pf` (main and utility processes); `Security 4688` for `chrome.exe` and helper processes; ShellBag entry for `Downloads`. Ground truth CSV: rows A01 to A09; record URLs in `TargetPath`, download filename in a dedicated row.

### S10. System shutdown and power on (appendix, 1 rep)

Clean shutdown, power on, log back in. Tests Event Logs shutdown and boot chain and Prefetch layout regeneration.

Manual steps:

1. A01. From Start, Power, Shut down. Confirm.
2. A02. After the VM powers off (verify from host), wait 30 s.
3. A03. Power on the VM from host.
4. A04. Wait for the sign in screen.
5. A05. Sign in as `dfanalyst`.
6. A06. Once desktop loads, wait 90 s for post boot Prefetch layout regeneration before snapshotting.

Expected: `System 1074` shutdown initiated, `6006` event log stopped, `6005` event log started, `12` kernel start, `13` kernel shutdown, `27` boot mgr; `Security 4624` type 2 interactive logon at A05; `layout.ini` regeneration and startup application `.pf` files. Ground truth CSV: rows A01 to A06; note exact power off UTC (from host) and power on UTC.
