# Scenario 7 Run 1 correlation table

Scenario: Save As from Notepad++ to new Documents subfolder (main body). Run 1 of 3. Artefact classes in matrix: Prefetch, EVTX, ShellBags.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

**Precondition:** VM reverted to `scenario1_post` (Notepad++ preinstalled from Scenario 1). Save As target: `C:\Users\dfanalyst\Documents\scenario7_test_file.txt`. GT documents a deviation from the catalogue (no per-rep subfolder created; file saved to Documents root); A02 UTC marker pasted into file: 2026-08-23T00:13:50.9282394Z.

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 00:12:41 | Launch Notepad++ from Start | NOTEPAD++.EXE 00:12:49 (direct hit); GUP.EXE 00:12:49 (Notepad++ bundled updater fires on launch); UPDATER.EXE x4 at 00:13:03 (Chrome Updater firing at scheduled interval, noise); AM_DELTA.EXE, MPSIGSTUB.EXE, WMIADAP.EXE (background) | Security 4688 x14 (parent svchost.exe), 4689 x16, SecurityCenter EID 15 (Defender state), WindowsUpdateClient EIDs 43/19 (noise) | no match | CONFIRMED | Prefetch names notepad++.exe and its GUP.exe updater at the launch second; EVTX 4688 chain corroborates. Two artefact classes with distinctive attribution. |
| A02 | 00:13:46 | Type Scenario 7 test content with UTC marker | no match | Security 4688 x2, 4689 x5 | no match | MISSED | Typing into a running process leaves no trace in any of the three artefacts. The UTC marker pasted into the file body is only discoverable by parsing the saved file's contents at A03, which is outside the artefact-parser scope. Expected result. |
| A03 | 00:16:00 | File menu, Save As | MICROSOFTEDGEUPDATE.EXE 00:16:35, MICROSOFTEDGEUPDATESETUP_X86 00:16:34, SEARCHFILTERHOST.EXE 00:16:32, SEARCHPROTOCOLHOST.EXE 00:16:32, SPPSVC.EXE 00:16:21 (mix of Edge-update noise plus Windows Search reindexing the saved file) | Security 4688 x13, 4689 x18, 4663 x3 object access (file write), SPP EIDs 16384/16394 licensing noise | UsrClass BagMRU at 00:16:11: `Desktop\Documents` (Save As dialog navigated user's Documents folder); UsrClass at 00:16:06: `Desktop\This PC\C:\Users`, `Desktop\This PC\C:\Temp`, `Desktop\This PC\C:\DISS_Config`, `Desktop\This PC\C:\DISS_TESTDATA`, `Desktop\This PC\C:\Program Files`, `Desktop\This PC\C:\Program Files\Notepad++` (dialog's common-dialog quick-access enumeration) | CONFIRMED | This is the study's cleanest demonstration that Notepad++ Save As common-dialog writes to ShellBags. Seven ShellBag rows fire in the window, including Desktop\Documents (the save target) and Program Files\Notepad++ (the app's install directory, which the common dialog enumerates via the recent-locations mechanism). Windows Search indexing the file post-save gives corroborating EVTX and Prefetch. Multi-class attribution with the ShellBag pattern being the primary evidential contribution. |
| A04 | 00:17:00 | Closing Notepad++ | no match | Security 4689 x6 exit burst, 5379 x7 credential reads | no match | PARTIAL | Notepad++ exit visible in 4689 burst but generic. Single-class weak attribution. |
| A05 | 00:17:51 | Open Documents folder using File Explorer | BACKGROUNDTASKHOST 00:17:53; FILECOAUTH 00:17:56 (Office file-collab helper); RUNDLL32 00:17:56 (Explorer namespace) | Security 4688 x3 with parent svchost.exe, 4689 x3, 4663 x3 object access | UsrClass BagMRU at 00:17:56: `Desktop\Win11 21H2`, `Desktop\This PC`, `Desktop\Desktop`, `Desktop\Downloads`, `Desktop\Documents` (namespace refresh including Documents target) | CONFIRMED | ShellBag directly attributes the Documents-folder navigation with per-folder timestamp; EVTX 4663 object access corroborates. Two artefact classes concur. |
| A06 | 00:18:29 | Viewing the file created | NOTEPAD.EXE 00:18:31 (direct hit; Windows opened the .txt file in default Notepad because Notepad++ was not registered as default handler) | Security 4688 x1 with parent explorer.exe (user double-click on the saved file), 4689 x4 | no match | CONFIRMED | Prefetch of notepad.exe firing two seconds after A06 start, with EVTX 4688 parent explorer.exe, is direct evidence that the user double-clicked the .txt file to open it. Two artefact classes attribute. Notepad (not Notepad++) opening the file is an incidental finding about the baseline's default-handler configuration. |
| A07 | 00:19:29 | Closing File Explorer and applications | no match | Security 4689 x3 exit | no match | MISSED | Same pattern as other Explorer-close actions in the study: no distinctive trace. |

## Coverage summary

- CONFIRMED: 4 of 7 (A01, A03, A05, A06)
- PARTIAL: 1 of 7 (A04)
- MISSED: 2 of 7 (A02, A07)
- Per-class hits: Prefetch 5 of 7, EVTX 7 of 7 (mostly generic), ShellBags 2 of 7 (A03, A05)

## Interpretive observations

1. The Save As common-dialog ShellBag pattern (A03) is the primary research contribution of Scenario 7: seven UsrClass rows fire in a single dialog interaction, including the save target (Documents) and Program Files\Notepad++ (the app's install directory). This is a documented Windows behaviour (common-dialog enumerates quick-access and recent locations) but its forensic value is that it leaves an evidence trail even when the user only "briefly saw" the folder in a dialog dropdown.
2. Notepad (not Notepad++) opens the saved .txt file at A06, which is a baseline-configuration finding: Notepad++ does not register as default .txt handler on Windows 11 by default, so double-click routing goes to notepad.exe. This does not affect attribution correctness; it does affect what a report would say about "which editor opened the file".
3. Typing content (A02) is invisible to all three artefacts by design; the UTC marker in the file body is only recoverable by post-hoc file-content inspection, which sits outside the artefact-parser triangulation model.
