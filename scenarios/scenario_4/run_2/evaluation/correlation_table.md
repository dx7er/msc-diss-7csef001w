# Scenario 4 Run 2 correlation table

Scenario: USB attach, browse, execute from USB (main body). Run 2 of 3. See `scenarios/scenario_4/run_1/evaluation/correlation_table.md` for scenario overview, USB-identity note, and interpretive observations that generalise across runs.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 20:33:34 | USB attach via VMware Removable Devices Connect | BDEUISRV.EXE, DRVINST.EXE 20:33:49, SHELLEXPERIENCEHOST, WUDFHOST, DLLHOST, SVCHOST x3 (fuller install chain than Run 1) | DriverFrameworks 2005 x14, 2000/2001/2003/2010/2004/2006, Security 6416 x6 DeviceId `USB\VID_0E0F&PID_0002\6&39d724fe&0&7`, Partition 1006 Model:UDisk, WPDClassInstaller 24576/24577/24579, DriverFrameworks 10000/10001/10100, Service Control Manager 7045 "WPD File System driver", UserPnp 20003 ServiceName:WUDFWpdFs | no match | CONFIRMED | Richer device-install chain than Run 1 (WPDClassInstaller sequence plus 7045 WPD-FileSystem-driver install) suggests the first-time driver registration in this VM state occurred here rather than in Run 1; this is a reproducibility observation. Multi-class attribution via DriverFrameworks plus Partition plus Security 6416. |
| A02 | 20:34:34 | Open Explorer, navigate to USB root | BACKGROUNDTASKHOST 20:34:35 (thin) | Security 4688 x3, 4689 x7, 4663 x3 object access | no match | PARTIAL | Neither ShellBag row for E: nor a distinctive Prefetch fires in this run's window. EVTX 4663 object access is the only weak attribution. The A02 windows are short (20 s here vs 66 s in Run 1) which explains part of the difference. Single-class weak. |
| A03 | 20:35:20 | Navigate to \PORTABLE\ | RUNDLL32.EXE 20:35:24, MICROSOFTEDGEUPDATE (background) | Security 4688 x2, 4689 x2 | UsrClass BagMRU at 20:35:24: `Desktop\E:\\PORTABLE` (direct hit, same as Run 1) | CONFIRMED | ShellBag directly attributes E:\PORTABLE navigation identically to Run 1; RUNDLL32 Prefetch (Explorer helper) provides supporting evidence. Reproduces Run 1 pattern. |
| A04 | 20:35:43 | Launch HelloWorld.exe | HELLOWORLD.EXE 20:35:47 (direct hit); CONHOST 20:35:47; OPENCONSOLE 20:35:47; WINDOWSTERMINAL 20:35:47 (all four seconds identical, cleaner alignment than Run 1) | Security 4688 x4 with parent explorer.exe (user double-click), 4689 x1 | no match | CONFIRMED | Reproduces Run 1 A04 pattern with cleaner clustering (all four Prefetch entries at same second). No WER 1001 crash this run, which is a small run-to-run variance. Multi-class attribution. |
| A05 | 20:36:14 | Eject USB from Explorer | 15 rows including DLLHOST x2, RUNDLL32 x2, MOUSOCOREWORKER, RUNTIMEBROKER, SOFTLANDINGTASK, SVCHOST x6, TIWORKER, TRUSTEDINSTALLER (fuller servicing chain than Run 1) | Security 4688 x33, 4689 x24, 4624 SYSTEM x7, 4672 privilege assignment x7, 5379 x7, 4797 x4, WER EID 1001 crash x1, Partition EID 1006 Model:UDisk | UsrClass BagMRU at 20:36:21: root namespace refresh (`Win11 21H2`, `This PC`, `Desktop`, `Downloads`, `Desktop\E:\`) | CONFIRMED | Same three-class attribution pattern as Run 1 A05. Partition 1006 closes the device-lifecycle loop by naming the same UDisk model. Reproducibility confirmed. |
| A06 | 20:36:47 | Disconnect USB from guest in VMware | no match | DriverFrameworks 2100 x2 removal, 2102 x2, 2900/2901 host shutdown, 1006/1008 driver-manager shutdown; Partition EID 1006 Model:UDisk | no match | PARTIAL | Identical shutdown chain to Run 1 A06. Single-class strong attribution. |

## Coverage summary

- CONFIRMED: 4 of 6 (A01, A03, A04, A05)
- PARTIAL: 2 of 6 (A02, A06)
- MISSED: 0 of 6
- Per-class hits: Prefetch 5 of 6, EVTX 6 of 6, ShellBags 2 of 6 (A03, A05)

## Cross-run notes

Compared to Run 1: A02 dropped from CONFIRMED to PARTIAL because the ShellBag E: row did not fire in the short A02 window (ShellBags for E: DID fire in the A05 window instead, indicating the hive-flush moved). All other rows reproduce Run 1's verdict. This is a genuine reproducibility observation: three of three runs attribute A01, A03, A04, A05, and A06 the same way; A02 shows across-run variance driven by when the hive flush lands relative to the action window.
