# Scenario 4 Run 3 correlation table

Scenario: USB attach, browse, execute from USB (main body). Run 3 of 3. See `scenarios/scenario_4/run_1/evaluation/correlation_table.md` for scenario overview, USB-identity note, and interpretive observations.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 21:00:15 | USB attach via VMware Removable Devices Connect | 10 rows including BDEUISRV, DRVINST, SHELLEXPERIENCEHOST, WUDFHOST, DLLHOST x2, SVCHOST x3, RUNTIMEBROKER (same install fingerprint as Run 2) | DriverFrameworks 2005 x14, arrival/host/add-device chain identical to Run 2, Security 6416 x6 DeviceId `USB\VID_0E0F&PID_0002\6&39d724fe&0&7` (matches Run 2), Partition 1006 Model:UDisk, WPDClassInstaller 24576/24577/24579, DriverFrameworks 10000/10001/10100, SCM 7045 "WPD File System driver", UserPnp 20003 ServiceName:WUDFWpdFs | no match | CONFIRMED | Reproduces Run 2 A01 exactly: same VID/PID, same PnP serial, same WPD driver install chain. This is the study's cleanest cross-run reproducibility of a device-attach signature. |
| A02 | 21:01:07 | Open Explorer, navigate to USB root | WMIADAP.EXE 21:01:07 (thin) | Security 4663 x13 object access (much heavier than Runs 1 and 2), 4688 x4, 4689 x7 | no match | PARTIAL | EVTX 4663 object-access burst is heavier here than in prior runs (13 vs 9 and 3), suggesting the Explorer namespace expansion touched more filesystem resources. No ShellBag E: row in this window. Same PARTIAL score as Run 2. |
| A03 | 21:01:51 | Navigate to \PORTABLE\ | RUNDLL32.EXE 21:01:54 | Security 4688 x6, 4689 x9 | UsrClass BagMRU at 21:01:54: `Desktop\E:\\PORTABLE` (direct hit, same as Runs 1 and 2) | CONFIRMED | Third consecutive run with the same E:\PORTABLE ShellBag direct hit. Reproducibility confirmed. |
| A04 | 21:02:40 | Launch HelloWorld.exe | HELLOWORLD.EXE 21:02:44 (direct hit); CONHOST 21:02:44; OPENCONSOLE 21:02:44; WINDOWSTERMINAL 21:02:44 (identical clustering to Run 2) | Security 4688 x4 with parent explorer.exe, 4689 x1 | no match | CONFIRMED | Reproduces Run 2 A04 exactly. |
| A05 | 21:03:10 | Eject USB from Explorer | DLLHOST 21:03:13, RUNDLL32 x2 (thinner than prior runs) | Security 4797 x4 SAM query, 4688 x3, 4689 x3, Partition EID 1006 Model:UDisk, 4663 x1 | UsrClass BagMRU at 21:03:13: root namespace refresh including `Desktop\E:\` (identical to Runs 1 and 2) | CONFIRMED | Same three-class attribution as prior runs. Reproducibility confirmed. |
| A06 | 21:03:39 | Disconnect USB from guest in VMware | MICROSOFTEDGEUPDATE.EXE 21:03:39 (background noise) | DriverFrameworks 2100 x2, 2102 x2, 2900/2901 host shutdown, 1006/1008 driver-manager shutdown, Partition EID 1006 Model:UDisk | no match | PARTIAL | Identical shutdown chain to Runs 1 and 2. Reproducibility confirmed. |

## Coverage summary

- CONFIRMED: 4 of 6 (A01, A03, A04, A05)
- PARTIAL: 2 of 6 (A02, A06)
- MISSED: 0 of 6
- Per-class hits: Prefetch 5 of 6, EVTX 6 of 6, ShellBags 2 of 6 (A03, A05)

## Cross-run reproducibility summary (Runs 1, 2, 3)

| Action | Run 1 | Run 2 | Run 3 | Reproducibility |
|---|---|---|---|---|
| A01 attach | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A02 nav USB root | CONFIRMED | PARTIAL | PARTIAL | 1/3 CONFIRMED, 3/3 attribute at some level |
| A03 nav PORTABLE | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A04 exec HelloWorld | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A05 eject | CONFIRMED | CONFIRMED | CONFIRMED | 3/3 |
| A06 disconnect | PARTIAL | PARTIAL | PARTIAL | 3/3 (consistent single-class) |

Overall: 5 of 6 actions reproduce their verdict exactly across all three runs; A02 shows a one-run variance driven by when the UsrClass hive flush lands relative to the short A02 window. This validates the reproducibility claim for Scenario 4 with the caveat that ShellBag timing has ~30-second variance across runs.
