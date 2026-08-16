# Scenario Playbooks

Manual execution guide for the ten scenarios defined in `scenario-catalogue.md`. Each scenario is performed by the researcher acting as a normal user inside the VM. No automation of GUI actions.

## How to use this file

For every scenario, in every repetition:

1. **Pre-run.** Revert the VM to `S00-UNIVERSAL-PRE` (working baseline, child of `B00-CANDIDATE`). Power on, sign in as `dfanalyst`, wait 60 s for background settle.
2. **Load the log helper.** In guest PowerShell, dot-source `scenarios/scripts/Log-Action.ps1` (or paste the function inline). Call `Log-Action A0N start "description"` before each action and `Log-Action A0N end` after.
3. **Execute steps** in the order given for the scenario.
4. **Post-run.** Wait 90 s for background settle. Export the action log to CSV. Shut down the guest cleanly (Start → Power → Shut down).
5. **Snapshot.** Take `SNN-RNN-POST` snapshot in VMware from the powered-off state.
6. **Acquire.** Pull raw artefacts from the powered-off VMDK per `testbed/scripts/13-validate-offline-acquisition-HOST.ps1`.
7. **File.** Raw artefacts land under `artefacts/{class}/raw/SNN-RNN/`; ground-truth CSV under `evaluation/ground-truth/SNN-RNN.csv`.

## Repetitions per scenario

| Scenario | Reps | Why |
|----------|:----:|-----|
| S01 Install applications | 1 | Deterministic install output |
| S04 USB attach + execute | 3 | PnP timing variability worth confirming |
| S07 Save-As from Notepad++ | 3 | Dialog-writes-SBags reproducibility worth confirming |
| S02, S03, S05, S06, S08, S09, S10 | 1 each | Qualitative pass/fail sufficient |

Total runs: **14**.

---

## S01 - Install 6 applications (MAIN, NAT REQUIRED, 1 rep)

Purpose: cross-artefact demonstration of software installation across a diverse app mix.

Applications installed (in order):

| # | App | URL | Approx size |
|---|-----|-----|-------------|
| 1 | Google Chrome | https://www.google.com/chrome/ | 12 MB stub |
| 2 | WinRAR | https://www.win-rar.com/download.html (English 64-bit) | 4 MB |
| 3 | VLC Media Player | https://www.videolan.org/vlc/ | 45 MB |
| 4 | Adobe Acrobat Reader DC | https://get.adobe.com/reader/ | ~200 MB via stub |
| 5 | Zoom Workplace | https://zoom.us/download | 50 MB |
| 6 | Notepad++ | https://notepad-plus-plus.org/downloads/ | 7 MB |

Manual steps (as `dfanalyst` user):

1. **A01** Open Microsoft Edge from Start.
2. **A02** In Edge, go to `https://www.google.com/chrome/`, click Download Chrome, save `ChromeSetup.exe` to `Downloads`.
3. **A03** In Edge, go to `https://www.win-rar.com/download.html`, click the English 64-bit `.exe` link, save to `Downloads`. Record exact filename.
4. **A04** In Edge, go to `https://www.videolan.org/vlc/`, click Download VLC, save `vlc-*-win64.exe` to `Downloads`. Record exact filename.
5. **A05** In Edge, go to `https://get.adobe.com/reader/`. **Untick any optional offers**. Click Download Acrobat Reader, save `readerdc*setup.exe` to `Downloads`. Record exact filename.
6. **A06** In Edge, go to `https://zoom.us/download`, click Download for Zoom Workplace, save `ZoomInstallerFull.*` to `Downloads`. Record exact filename.
7. **A07** In Edge, go to `https://notepad-plus-plus.org/downloads/`, click the current version, then the Installer 64-bit x64 link, save `npp.*.Installer.x64.exe` to `Downloads`. Record exact filename and version.
8. **A08** Close Edge.
9. **A09** Open File Explorer, navigate to `%USERPROFILE%\Downloads`. Confirm all 6 installers present.
10. **A10** Double-click `ChromeSetup.exe`. UAC → Yes. Wait for install. Close Chrome when it auto-launches (do not sign in).
11. **A11** Double-click the WinRAR installer. UAC → Yes. Click Install (accept defaults). Click OK on the setup complete dialog, then Done.
12. **A12** Double-click the VLC installer. UAC → Yes. Accept defaults through the wizard. Click Install. On completion, untick "Run VLC" and click Finish.
13. **A13** Double-click the Adobe Reader installer. UAC → Yes. Wait for the stub to download the full package and install. Close Adobe Reader if it auto-launches.
14. **A14** Double-click the Zoom installer. UAC → Yes. Wait for install. If Zoom app opens at end, close it. Do not sign in.
15. **A15** Double-click the Notepad++ installer. UAC → Yes. Defaults through wizard. **Untick "Run Notepad++"** at Finish.

Expected artefacts to look for in Phase 4:

- **Prefetch:** `.pf` for each installer EXE and for the newly installed EXEs that auto-launched (Chrome, Adobe, potentially Zoom).
- **Event Logs (Application):** MsiInstaller `1033`, `1040`, `1042`, `11707`. Strongest for Adobe and Zoom (MSI-based).
- **Event Logs (System):** `7045` service install. Expected for Zoom auto-updater.
- **Event Logs (Security):** `4688` process creation with command line for every installer and its child processes.
- **ShellBags (`UsrClass.dat`):** entry for `Downloads`.

Post-run notes: record the Uninstall registry GUIDs for the six products from `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\` and `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\` for the discussion chapter.

---

## S04 - USB attach, browse, execute-from-USB (MAIN, 3 reps)

Purpose: Jade's worked example. Cross-artefact including PnP.

Precondition: a controlled USB stick prepared as follows before the run. Single NTFS partition, volume label `DISS-USB`, contents `\PORTABLE\HelloWorld.exe` (any small compiled console app). Record VID, PID, and serial from Device Manager on the host before insertion. Same physical stick across all 3 reps.

Manual steps:

1. **A01** From host, connect the USB stick to the VM (VMware → VM → Removable Devices → `<device>` → Connect).
2. **A02** In the guest, wait for the "device ready" notification. Confirm drive letter assigned.
3. **A03** Open File Explorer, navigate to the assigned drive root. Wait 5 s.
4. **A04** Navigate into `\PORTABLE\`. Wait 5 s.
5. **A05** Double-click `HelloWorld.exe`. Let it run and self-close (or close the console window).
6. **A06** Right-click the USB drive in Explorer left pane → `Eject`. Wait for the "safe to remove" notification.
7. **A07** From host, disconnect the USB device (VMware → VM → Removable Devices → `<device>` → Disconnect).

Expected artefacts:

- **Prefetch:** `HELLOWORLD.EXE-*.pf` with volume path field pointing to the removable volume.
- **Event Logs (System):** `20001` (PnP device install), USB Hub `43` where applicable, `225` (device eject) at end.
- **Event Logs (DriverFrameworks-UserMode/Operational):** `2003`, `2010`, `2100`.
- **Event Logs (Partition/Diagnostic):** `1006` with model, serial, VID, PID.
- **ShellBags:** entry for the USB volume root and `\PORTABLE\` folder in `UsrClass.dat`.

Ground-truth CSV: rows A01-A07 plus a dedicated `USB_VIDPIDSERIAL` row with device identity in `TargetPath`.

---

## S07 - Save-As from Notepad++ to new Documents subfolder (MAIN, 3 reps)

Purpose: hits all three artefact classes with a normal editing / file-creation workflow that doesn't overlap S01 (install) or S04 (USB). Uses Notepad++ installed in S01.

Precondition: Notepad++ installed (from S01). If starting from `S00-UNIVERSAL-PRE`, run S01 once first (single install rep is sufficient for the required Notepad++ presence).

Manual steps:

1. **A01** From Start, launch `notepad++.exe`. Wait for main window.
2. **A02** In the blank tab, type: `S07 test content <UTC timestamp>` (paste the current UTC as a distinctive marker per rep).
3. **A03** Menu **File → Save As...**
4. **A04** In the Save As dialog, click into the address bar and paste `%USERPROFILE%\Documents`. Press Enter.
5. **A05** Right-click empty space in the dialog file area → **New → Folder**. Name it `S07_Output_R<NN>` where `<NN>` is the repetition number. Press Enter.
6. **A06** Double-click `S07_Output_R<NN>` to enter it.
7. **A07** In the filename field, enter `s07-test-R<NN>.txt`. Click Save.
8. **A08** Close Notepad++ (X button; if prompted to save, click No, the file is already saved).

Expected artefacts:

- **Prefetch:** `NOTEPAD++.EXE-*.pf` with first / last-run time matching the launch UTC. Across the 3 reps, run count should equal 3.
- **Event Logs (Security):** `4688` process creation for `notepad++.exe` with command line populated.
- **ShellBags (`UsrClass.dat`):** entries for `Documents` and for the newly-created `S07_Output_R<NN>` subfolder per rep. The Save-As common dialog uses `IShellBrowser` and writes ShellBag entries the same way Explorer navigation does.

Ground-truth CSV: rows A01-A08; record the exact filename saved in `TargetPath` and the folder name created in `ObservedOutcome`.

---

## S02 - Application execution baseline (APPENDIX, 1 rep)

Purpose: cleanest Prefetch story (run count, first / last-run).

Precondition: apps installed via S01 (Chrome, WinRAR, VLC, Notepad++ used here; Adobe and Zoom excluded because they auto-run background services that pollute the sequence).

Manual steps (repeated internally 3 times within the single run to prove run count):

1. **A01** From Start, launch `notepad.exe`. Wait 10 s. Close it.
2. **A02** From Start, launch `calc.exe`. Wait 10 s. Close it.
3. **A03** From Start, launch `chrome.exe`. Wait 10 s. Close it.
4. **A04** From Start, launch `winrar.exe`. Wait 10 s. Close it.
5. **A05** From Start, launch `vlc.exe`. Wait 10 s. Close it.
6. **A06** From Start, launch `notepad++.exe`. Wait 10 s. Close it.

Repeat A01-A06 twice more within the same run (so a single run produces 3 launches per app, which proves Prefetch run count).

Expected artefacts:

- **Prefetch:** one `.pf` per unique EXE. Run count should equal `3` for each after this scenario. Last-run time matches the third launch UTC.
- **Event Logs (Security):** `4688` per launch, with command line populated.

Ground-truth CSV: one row per launch/close pair (18 rows total per run); note the third-launch UTC per app.

---

## S03 - Nested folder navigation (APPENDIX, 1 rep)

Purpose: cleanest ShellBags story + positive/negative control.

Precondition: create this tree in the guest before starting the run:

```
C:\DISS_TESTDATA\NAV\
    LEVEL1_A\
        LEVEL2_A\
            LEVEL3_A\
                LEVEL4_A\
                    LEVEL5_A\
    LEVEL1_B\  <-- negative control (never browse this)
```

Manual steps:

1. **A01** Open File Explorer.
2. **A02** Navigate to `C:\DISS_TESTDATA\NAV\`. Wait 3 s.
3. **A03** Double-click `LEVEL1_A`. Wait 3 s.
4. **A04** Double-click `LEVEL2_A`. Wait 3 s.
5. **A05** Double-click `LEVEL3_A`. Wait 3 s.
6. **A06** Double-click `LEVEL4_A`. Wait 3 s.
7. **A07** Double-click `LEVEL5_A`. Wait 3 s.
8. **A08** Close Explorer.

Do **not** open `LEVEL1_B` at any point.

Expected artefacts:

- **ShellBags (`UsrClass.dat`):** one entry per folder A02-A07. `LEVEL1_B` absent, which acts as the negative control that anchors the ShellBags evidential-value discussion.
- **Prefetch:** `EXPLORER.EXE-*.pf` volume references only.
- **Event Logs:** none unique to this scenario.

Ground-truth CSV: rows A01-A08.

---

## S05 - File deletion via Explorer + Recycle Bin (APPENDIX, 1 rep)

Purpose: correlate an Explorer-mediated action across all three classes.

Precondition: place a staged file at `C:\DISS_TESTDATA\DELETE\S05_target.txt` before starting the run.

Manual steps:

1. **A01** Open File Explorer, navigate to `C:\DISS_TESTDATA\DELETE\`.
2. **A02** Right-click `S05_target.txt` → Delete (sends to Recycle Bin).
3. **A03** Open Recycle Bin (double-click desktop icon).
4. **A04** Confirm `S05_target.txt` is listed.
5. **A05** Right-click Recycle Bin icon on Desktop → Empty Recycle Bin. Confirm.

Expected artefacts:

- **Prefetch:** `EXPLORER.EXE-*.pf` with `\$Recycle.Bin\` in referenced paths.
- **Event Logs (Security):** `4663` if object access auditing is enabled and the SACL applies; otherwise no event unique to the delete.
- **ShellBags (`UsrClass.dat`):** entry for the source folder and Recycle Bin shell folder.

Ground-truth CSV: rows A01-A05.

---

## S06 - Logon / lock / unlock / logoff cycle (APPENDIX, 1 rep)

Purpose: negative control for PF/SBags; isolates Event Logs.

Manual steps:

1. **A01** Sign out of `dfanalyst` (Start → user icon → Sign out).
2. **A02** At the lock screen, sign back in with password.
3. **A03** Press `Win+L` to lock the workstation.
4. **A04** Wait 15 s.
5. **A05** Unlock with password.
6. **A06** Sign out again.
7. **A07** Sign back in.

Expected artefacts:

- **Event Logs (Security):** `4624` logon (type 2 for interactive), `4634` logoff, `4800` workstation locked, `4801` workstation unlocked. Logon type is critical evidence.
- **Prefetch:** none unique.
- **ShellBags:** none unique.

Ground-truth CSV: rows A01-A07.

---

## S08 - Command-line execution (cmd, PowerShell) (APPENDIX, 1 rep)

Purpose: Prefetch for shell hosts + `4688` with command-line arguments.

Manual steps:

1. **A01** From Start, launch `cmd.exe`.
2. **A02** In cmd, type `whoami` and press Enter.
3. **A03** In cmd, type `dir C:\Windows` and press Enter.
4. **A04** Close cmd.
5. **A05** From Start, launch `powershell.exe`.
6. **A06** In PowerShell, type `Get-Process` and press Enter.
7. **A07** Close PowerShell.

Expected artefacts:

- **Prefetch:** `CMD.EXE-*.pf`, `POWERSHELL.EXE-*.pf`, `CONHOST.EXE-*.pf`.
- **Event Logs (Security):** `4688` process creation with `ProcessCommandLine` populated for cmd, powershell.

Ground-truth CSV: rows A01-A07; record exact command strings in `TargetPath`.

---

## S09 - Web browsing session with download (APPENDIX, NAT REQUIRED, 1 rep)

Purpose: modern real-user workflow across all three artefact classes.

Precondition: Chrome installed (from S01).

Manual steps:

1. **A01** From Start, launch `chrome.exe`.
2. **A02** Navigate to `https://example.com/`. Wait 5 s.
3. **A03** Navigate to `https://www.bbc.co.uk/`. Wait 5 s.
4. **A04** Navigate to a small file URL (e.g. `https://files.testfile.org/PDF/10MB-TESTFILE.ORG.pdf`). Chrome will download to `Downloads`.
5. **A05** Wait for download to complete.
6. **A06** Close Chrome.
7. **A07** Open File Explorer, navigate to `%USERPROFILE%\Downloads`.
8. **A08** Confirm downloaded file present. Note filename.
9. **A09** Close Explorer.

Expected artefacts:

- **Prefetch:** `CHROME.EXE-*.pf` (main and utility processes each get their own `.pf` depending on Chrome version).
- **Event Logs (Security):** `4688` for `chrome.exe` and helper processes.
- **ShellBags:** entry for `Downloads`.

Ground-truth CSV: rows A01-A09; record URLs in `TargetPath`, download filename in a dedicated row.

---

## S10 - System shutdown and power-on (APPENDIX, 1 rep)

Purpose: shutdown/boot Event Log chain + Prefetch layout side-effect.

Manual steps:

1. **A01** From Start → Power → Shut down. Confirm.
2. **A02** After the VM powers off (verify from host), wait 30 s.
3. **A03** Power on the VM from host.
4. **A04** Wait for the sign-in screen.
5. **A05** Sign in as `dfanalyst`.
6. **A06** Once desktop loads, wait 90 s for post-boot Prefetch layout regeneration before snapshotting.

Expected artefacts:

- **Event Logs (System):** `1074` shutdown initiated, `6006` event log stopped, `6005` event log started, `12` kernel start, `13` kernel shutdown, `27` boot mgr.
- **Event Logs (Security):** `4624` type 2 interactive logon at A05.
- **Prefetch:** `layout.ini` regeneration and startup application `.pf` files.

Ground-truth CSV: rows A01-A06; note exact power-off UTC (from host) and power-on UTC.

---

## Cross-scenario notes

- **NAT scenarios (S01, S09):** NAT is approved by Jade (meeting 2026-08-06). No policy switch needed between scenarios; NAT stays on.
- **USB scenario (S04):** use the same physical USB stick across all 3 reps so VID/PID/serial are constant and the evaluation matrix rows are comparable.
- **S01 → S02, S07, S09 dependency:** S02, S07, and S09 all depend on apps installed in S01. Simplest workflow is to run S01 first, take a `POST-S01` snapshot, and use that snapshot as the starting point for S02/S07/S09 runs (instead of reverting to `S00-UNIVERSAL-PRE` and re-installing every time).
- **Ordering:** run scenarios in the order S01 → S07 (all reps) → S04 (all reps) → S02 → S03 → S05 → S06 → S08 → S09 → S10. S10 last because it changes shutdown/boot logs the analyst wants to reason about after other traces are captured.
