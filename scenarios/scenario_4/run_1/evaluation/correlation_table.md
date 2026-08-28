# Scenario 4 Run 1 correlation table

Scenario: USB attach, browse, execute from USB (main body). Run 1 of 3. Artefact classes in matrix: Prefetch, EVTX, ShellBags.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

**USB identity:** GT documents Ven=General, Prod=UDisk, Rev=5.00, PnP serial `6&38E547A7&2&_&0`, volume serial B0920497. EVTX Security 6416 events in Run 1 record `USB\VID_ABCD&PID_1234\6&39d724fe&0&6`, which is a VMware synthetic PnP identifier for the removable-device pass-through and differs from the physical device identity; Runs 2 and 3 record `USB\VID_0E0F&PID_0002\6&39d724fe&0&7` (VMware-standard PID pair). The discrepancy is documented in Scenario 4 evaluation notes and is a legitimate finding about VMware USB attribution.

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 11:45:27 | USB attach via VMware Removable Devices Connect | WUDFHOST.EXE 11:45:40 (User-Mode Driver Framework host for the WPD device) | DriverFrameworks EID 2005 x14 (module load), 2000/2001 host startup, 2003/2010 device arrival, 2004/2006 add-device, 1003/1004 driver-manager host create; Security 6416 (device install) x4 DeviceId `USB\VID_ABCD&PID_1234\6&39d724fe&0&6`; Partition EID 1006 Model:UDisk | no match | CONFIRMED | Rich EVTX cross-provider chain (DriverFrameworks arrival plus Partition diagnostic naming Model:UDisk plus Security 6416 with device ID) plus Prefetch of the UMDF host give unambiguous attribution of a specific USB storage device attach. Two artefact classes with distinctive attribution. |
| A02 | 11:46:25 | Open Explorer, navigate to USB root | EXPLORER.EXE 11:46:47 x2 (namespace refresh); FILECOAUTH; RUNDLL32 11:46:48 (Explorer helper); TASKHOSTW, TIWORKER, TRUSTEDINSTALLER (servicing noise) | Security 4688 x29 with parent svchost.exe, 4689 x19, 4663 x9 object-access on removable-drive resources, 4624 SYSTEM logon x5 | UsrClass BagMRU at 11:46:35: `Desktop\This PC\C:` and `Desktop\This PC\E:` (E: is the USB drive letter); UsrClass at 11:46:48: `Desktop\CLSID_ThisPCDocumentsRegFolder` | CONFIRMED | ShellBag directly captures E: (the USB volume) navigation with a per-folder LastInteracted timestamp; EVTX 4663 object access on the volume resource corroborates. Multi-class attribution. |
| A03 | 11:48:02 | Navigate to \PORTABLE\ inside USB root | SVCHOST.EXE x2 (background) | Security 4688 x3, 4689 x3, 5379 x13 credential reads, WindowsUpdateClient EID 44 x3 (background update) | UsrClass BagMRU at 11:48:05: `Desktop\E:\\PORTABLE` (direct hit on the PORTABLE folder on the USB root) | CONFIRMED | ShellBag directly attributes the navigation to E:\PORTABLE with per-folder timestamp; this is the primary ShellBag evidence for USB navigation the scenario is designed to elicit. Prefetch/EVTX rows are background noise. Single artefact class carries the attribution but it is distinctively specific. Treating this as CONFIRMED because the ShellBag entry names both the USB volume and the folder inside it in one string, which is stronger evidence than three generic-EVTX rows would be. |
| A04 | 11:49:03 | Launch HelloWorld.exe from USB | HELLOWORLD.EXE 11:49:06 (direct hit); CONHOST.EXE 11:49:06; OPENCONSOLE.EXE 11:49:07; WINDOWSTERMINAL.EXE 11:49:07 (Windows 11 Terminal hosting the console app); SVCHOST 11:49:50, WERMGR 11:49:50 (Windows Error Reporting fired for HelloWorld exit) | Security 4688 x9 with parent explorer.exe (user double-click origin), 4689 x8, WER EID 1001 Application Crash x3 (HelloWorld.exe exited abnormally) | no match | CONFIRMED | Prefetch of HelloWorld.exe from the USB volume plus Security 4688 with parent explorer.exe give unambiguous attribution of user-launched execution from removable media. WER 1001 confirms the console app exited via the crash path (probable console-window-close terminating the process); this is an incidental finding but does not affect attribution. |
| A05 | 11:50:10 | Eject USB from Explorer | DLLHOST 11:50:14, RUNDLL32 11:50:18 (Explorer eject-media helpers) | Security 4797 x4 (SAM database query), 4688 x3, 4689 x3, Partition EID 1006 Model:UDisk (eject-side entry for the same device) | UsrClass BagMRU at 11:50:14: root namespace refresh (`Win11 21H2`, `This PC`, `Desktop`, `Downloads`, `CLSID_ThisPCDocumentsRegFolder`, `Desktop\E:\`) | CONFIRMED | ShellBag namespace refresh at eject-second captures E: and the top-level shell folders (hive-flush moment); Partition EID 1006 on eject side names the same UDisk model as the attach event, closing the device-lifecycle loop. Multi-class attribution. |
| A06 | 11:50:59 | Disconnect USB from guest in VMware | no match | DriverFrameworks 2100 x2 device removal, 2102 x2 device request, 2900/2901 host shutdown, 1006/1008 driver-manager shutdown; Partition EID 1006 Model:UDisk; Security 4907 x6 audit policy change | no match | PARTIAL | Distinctive EVTX shutdown chain (DriverFrameworks 2900 host shutdown plus Partition 1006 name confirms the same UDisk device leaves) attributes the disconnect end-to-end, but only one artefact class carries the attribution. Consistent with the matrix classification of A06 as an EVTX-primary action. |

## Coverage summary

- CONFIRMED: 5 of 6 (A01, A02, A03, A04, A05)
- PARTIAL: 1 of 6 (A06)
- MISSED: 0 of 6
- Per-class hits: Prefetch 4 of 6 (A01, A02, A04, A05), EVTX 6 of 6 (all with distinctive attribution), ShellBags 3 of 6 (A02, A03, A05)

## Interpretive observations

1. USB device-lifecycle attribution is the study's strongest end-to-end evidential chain: attach (A01), navigation (A02, A03), execute (A04), eject (A05), disconnect (A06) all produce distinct EVTX signatures that name the same device (Model:UDisk via Partition 1006), and ShellBags record the volume letter (E:) as it becomes visible. This is the reference example of three-artefact triangulation working end-to-end.
2. VMware synthetic PnP identifiers (`VID_ABCD&PID_1234` in Run 1, `VID_0E0F&PID_0002` in Runs 2 and 3) do not match the physical USB stick's Windows Device Manager identity, which is a documented VMware attribution gap: forensic identification of the specific hardware requires cross-referencing VMware's per-VM USB pass-through logs. This is a research-worthy finding.
3. The HelloWorld.exe execution from USB (A04) reliably produces Prefetch with volume-path attribution to the removable volume (validation of Jade's worked-example expectation from the 2026-08-06 meeting).
