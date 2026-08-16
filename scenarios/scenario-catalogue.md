# Scenario Catalogue

Formal set of user-activity scenarios executed against the working baseline (`S00-UNIVERSAL-PRE`, child of `B00-CANDIDATE-W11-25H2-26200.6584-20260717`) to generate ground-truth artefacts for Prefetch, Windows Event Logs and ShellBags correlation.

Designed to Jade's 2026-08-06 guidance: **10 scenarios total**, **5-10 per artefact class**, **3 headline scenarios in main body**, remaining in appendix, every scenario has a row in the [evaluation matrix](../evaluation/evaluation-matrix-template.md).

**Constraint recap**

- Anti-forensic behaviour is out of scope.
- Each scenario begins from a clean revert of `S00-UNIVERSAL-PRE` and ends with a `SNN-RNN-POST` snapshot before acquisition.
- Ground truth per run is recorded by the `Log-Action` helper (see `scenarios/scripts/Log-Action.ps1`) and exported to `evaluation/ground-truth/SNN-RNN.csv`.
- Repetition count per scenario is tiered. See "Repetitions" below.

## Repetitions

Tiered per scenario based on where reproducibility genuinely strengthens the finding vs where it just repeats deterministic behaviour:

| Scenario | Reps | Rationale |
|----------|:----:|-----------|
| S01 Install applications | 1 | Installer output is deterministic; three repetitions would just repeat known Windows install behaviour without strengthening the correlation claim. |
| S04 USB attach + execute | 3 | PnP timing and enumeration order can vary; three attaches meaningfully confirm the same VID/PID/serial reliably appears. |
| S07 Save-As from Notepad++ | 3 | The Save-As common dialog "writes to ShellBags" behaviour has historical Windows edge cases; three reps confirm the pattern is stable. |
| S02, S03, S05, S06, S08, S09, S10 | 1 each | Qualitative pass/fail in the evaluation matrix is sufficient for appendix scenarios. |

Total runs: 1 + 3 + 3 + 7 = **14 runs**.

Evaluation matrix rows for S04 and S07 report `N/3` reproducibility; all other rows are `PASS` / `PART` / `FAIL` qualitative only.

## Coverage matrix

Main body scenarios are all-three-artefact by design (correlation across `PF + EVTX + SBags` is the core research contribution). Appendix scenarios include partial-coverage cases that act as negative controls or isolate single-artefact evidential value.

| ID  | Scenario                                       | PF | EVTX | SBags | Placement |
|-----|------------------------------------------------|:--:|:----:|:-----:|:---------:|
| S01 | Install 6 applications                         | X  | X    | X     | Main      |
| S04 | USB attach, browse, execute-from-USB           | X  | X    | X     | Main      |
| S07 | Save-As from Notepad++ to new subfolder        | X  | X    | X     | Main      |
| S02 | Application execution baseline                 | X  | X    |       | Appendix  |
| S03 | Nested folder navigation                       |    |      | X     | Appendix  |
| S05 | File deletion via Explorer + Recycle Bin       | X  | X    | X     | Appendix  |
| S06 | Logon / lock / unlock / logoff cycle           |    | X    |       | Appendix  |
| S08 | Command-line execution (cmd, PowerShell)       | X  | X    |       | Appendix  |
| S09 | Web browsing session with download             | X  | X    | X     | Appendix  |
| S10 | System shutdown and power-on                   | X  | X    |       | Appendix  |

Per-artefact totals:

- **Prefetch:** S01, S02, S04, S05, S07, S08, S09, S10 = 8
- **Event Logs:** S01, S02, S04, S05, S06, S07, S08, S09, S10 = 9
- **ShellBags:** S01, S03, S04, S05, S07, S09 = 6

All three fall in the 5-10 band.

## Network policy

NAT is approved by Jade (meeting 2026-08-06). Two scenarios need internet:

- **S01** (download 6 installers)
- **S09** (real web browsing + download)

Other scenarios can run with NAT or host-only, with no operational difference for their target artefacts.

## Headline scenarios (main body)

### S01 - Install 6 applications

Rationale: application install is the richest single event for correlation. It leaves traces in **all three artefact classes at once**, plus registry uninstall keys and MSI Installer logs that support the discussion.

Applications installed (mix of installer types and categories to diversify EVTX signatures):

| # | Application               | Category            | Installer type |
|---|---------------------------|---------------------|----------------|
| 1 | Google Chrome             | Browser             | Stub + multi-process |
| 2 | WinRAR                    | Archiver            | NSIS-based (simple) |
| 3 | VLC Media Player          | Media player        | NSIS-based (simple) |
| 4 | Adobe Acrobat Reader DC   | PDF reader          | MSI-based (strong `MsiInstaller` signal) |
| 5 | Zoom Workplace            | Video conferencing  | MSI-based + service install (`7045`) |
| 6 | Notepad++                 | Text editor         | NSIS-based (simple) |

User action (in order): open Edge, download all 6 installers to `%USERPROFILE%\Downloads`, close Edge, open Downloads in File Explorer, run each installer in sequence accepting defaults.

Ground truth: URL fetched, installer filename, install start/end UTC, uninstall registry key GUID (recorded post-install for the report).

Expected artefacts:

- **Prefetch:** `.pf` for each installer EXE (e.g. `CHROMESETUP.EXE-*.pf`, `WINRAR-X64-*.exe-*.pf`) and for the newly installed EXEs launched at end of install (Chrome, Adobe, Zoom typically auto-launch).
- **Event Logs:**
  - `Application`: `MsiInstaller 1033` (product installed), `1040`/`1042` (transaction begin/end), `11707` (install success). Strongest for Adobe and Zoom.
  - `System`: `7045` (service install). Expected for Zoom auto-updater.
  - `Security 4688`: process creation of `msiexec.exe`, installer EXEs, elevated child processes.
- **ShellBags:** entry for the Downloads folder in `UsrClass.dat`.

Correlation problem: stitch download → install → first-run chain per app across three artefact classes.

### S04 - USB attach, browse, execute-from-USB

Rationale: Jade's worked example. Loads all three artefact classes in one contained workflow, including PnP events unique to removable media.

User action: attach a prepared USB stick, browse its root and one subfolder in Explorer, launch a small portable EXE staged on the USB, safely eject.

Precondition: prepared USB stick with `\PORTABLE\HelloWorld.exe` (small compiled console app). Record VID / PID / serial from Device Manager on the host before insertion.

Ground truth: device VID / PID / serial, attach UTC, folder paths browsed with UTC per click, EXE launched with UTC, eject UTC.

Expected artefacts:

- **Prefetch:** `.pf` for the EXE launched from the USB volume, with volume path field pointing to the removable volume.
- **Event Logs:**
  - `System`: PnP `20001` (device install), USB Hub `43` where applicable.
  - `Microsoft-Windows-DriverFrameworks-UserMode/Operational`: `2003`, `2010`, `2100`.
  - `Microsoft-Windows-Partition/Diagnostic`: `1006` partition arrival with model / serial / VID / PID.
- **ShellBags:** entry for the USB volume root and every folder navigated on it in `UsrClass.dat`.

Correlation problem: device-to-file provenance. Map a specific USB hardware ID to specific folders browsed on it to a specific executable run from it.

### S07 - Save-As from Notepad++ to new Documents subfolder

Rationale: hits all three artefact classes with a normal editing / file-creation workflow that doesn't overlap S01 (install) or S04 (USB device). Uses Notepad++ installed in S01, no additional software or hardware required.

User action:

1. Launch `notepad++.exe` from Start.
2. Type a short marker sentence in the blank tab (e.g. `S07 test content <timestamp>`).
3. Menu **File → Save As...**
4. In the Save As dialog, navigate to `%USERPROFILE%\Documents`.
5. Right-click empty space in the dialog → **New → Folder**. Name it `S07_Output`.
6. Double-click into `S07_Output`.
7. Enter filename `s07-test.txt`. Click Save.
8. Close Notepad++.

Ground truth: launch UTC, save UTC, close UTC, target file full path.

Expected artefacts:

- **Prefetch:** `NOTEPAD++.EXE-*.pf` with first / last-run time matching the launch UTC.
- **Event Logs:** `Security 4688` process creation for `notepad++.exe` with command line.
- **ShellBags:** entries for `Documents` and the newly-created `S07_Output` subfolder. The Save-As common dialog uses `IShellBrowser`, so it writes ShellBag entries in `NTUSER.DAT` / `UsrClass.dat` the same way Explorer navigation does.

Correlation problem: tie application execution (`4688` + Prefetch) to file creation location (ShellBags for the new subfolder). Answers "which running program created which file where".

## Appendix scenarios

### S02 - Application execution baseline

Cleanest Prefetch story. User launches the apps installed in S01 plus two Windows built-ins in a controlled sequence. Isolates Prefetch run-count and first / last-run behaviour.

User action: from Start, launch each of `notepad.exe`, `calc.exe`, `chrome.exe`, `winrar.exe`, `vlc.exe`, `notepad++.exe` in sequence, wait 10 s between each, close each after 10 s. Repeat the sequence twice more within the same run (so R01 alone produces 3 launches per app, which proves Prefetch run count).

Expected: one `.pf` per unique EXE with run count = 3 and last-run time matching the third launch; `Security 4688` per launch with command line.

### S03 - Nested folder navigation

Cleanest ShellBags story. User opens Explorer and clicks down a five-level nested path (`C:\DISS_TESTDATA\NAV\LEVEL1_A\LEVEL2_A\...\LEVEL5_A`) with no execution. Provides the "browsed vs not-browsed" positive/negative control by leaving sibling folder `LEVEL1_B` untouched.

Expected: one ShellBags entry per folder in `UsrClass.dat`; `LEVEL1_B` absent; `EXPLORER.EXE-*.pf` volume references only.

### S05 - File deletion via Explorer + Recycle Bin

Delete a staged file to Recycle Bin, then empty. Tests correlation across ShellBags (Recycle Bin shell folder), Prefetch (`EXPLORER.EXE` volume refs) and Event Logs (`Security 4663` where object access auditing catches it).

### S06 - Logon / lock / unlock / logoff cycle

Sign out, sign in, lock (`Win+L`), unlock, sign out. Pure Event Logs scenario: no Prefetch, no ShellBags. Negative control for PF / SBags; tests `Security 4624`, `4634`, `4800`, `4801` including logon type.

### S08 - Command-line execution (cmd, PowerShell)

Open `cmd.exe`, run `whoami` and `dir`; open `powershell.exe`, run `Get-Process`. Tests Prefetch for shell hosts and `Security 4688` with command-line arguments (`ProcessCreationIncludeCmdLine_Enabled = 1` per testbed Step 6).

### S09 - Web browsing session with download

Launch Chrome, visit three URLs (e.g. `example.com`, `bbc.co.uk`, a small file host), download a small file, open Downloads folder in Explorer, close browser. Tests Prefetch for browser + helper processes, `Security 4688` process creation chain, and ShellBags entry for Downloads folder.

### S10 - System shutdown and power-on

Clean shutdown (`shutdown /s /t 0`), power on, log back in. Tests Event Logs shutdown / boot chain (`System 1074`, `6006`, `6005`, `12`, `13`) and Prefetch layout regeneration.

## Execution order

Executed in numeric order (S01 → S10) per repetition. Each run is preceded by a revert to `S00-UNIVERSAL-PRE` (working baseline) and followed by an `SNN-RNN-POST` snapshot per `testbed/snapshots.md` naming. Per-scenario execution steps live in `scenarios/playbooks.md`.
