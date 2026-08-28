# Scenario 4: USB attach, browse, execute from USB

Placement: main body. Runs: 3 repetitions (same physical USB stick each time). Matrix coverage: Prefetch, Event Logs, ShellBags. Catalogue entry: `scenarios/catalogue.md`.

This is Jade's worked example from the 2026-08-06 meeting. It loads all three artefact classes in one contained workflow including PnP device events unique to removable media, plus an executable launched from the USB volume, plus the eject and disconnect lifecycle. Three repetitions to observe run to run stability of the device identity fields and the artefact fingerprint.

## 1. Ground truth

VM reverted to `baseline_pre_scenarios` before each run. Same physical DISS USB stick attached each time (single NTFS partition, volume label DISS-USB, payload `\PORTABLE\HelloWorld.exe`). USB identity captured pre run by `scripts/scenarios/scenario4_capture_usb_identity.ps1` and stored at `evaluation/usb_identity.txt`.

Signed in as `dfanalyst`. Attached the USB via VMware Removable Devices, waited for the drive letter, opened Explorer, navigated to the USB root, navigated to `\PORTABLE\`, double clicked `HelloWorld.exe`, ejected the USB from Explorer, disconnected the device from the guest. Six actions per run. Full logs at `run_1/evaluation/ground_truth.csv`, `run_2/evaluation/ground_truth.csv`, `run_3/evaluation/ground_truth.csv`.

Run 1:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 11:45:27.843 | 11:45:57.534 | USB attach via VMware Removable Devices Connect |
| A02 | 11:46:25.947 | 11:47:31.289 | Open Explorer, navigate to USB root |
| A03 | 11:48:02.252 | 11:48:19.732 | Navigate to \PORTABLE\ inside USB root |
| A04 | 11:49:03.136 | 11:49:49.004 | Launch HelloWorld.exe from USB |
| A05 | 11:50:10.183 | 11:50:32.420 | Eject USB from Explorer |
| A06 | 11:50:59.838 | 11:51:30.450 | Disconnect USB from guest in VMware |

Run 2:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 20:33:34.012 | 20:34:16.083 | USB attach |
| A02 | 20:34:34.002 | 20:34:49.636 | Open Explorer, navigate to USB root |
| A03 | 20:35:20.250 | 20:35:31.843 | Navigate to \PORTABLE\ |
| A04 | 20:35:43.648 | 20:36:01.005 | Launch HelloWorld.exe |
| A05 | 20:36:14.525 | 20:36:36.016 | Eject USB |
| A06 | 20:36:47.325 | 20:37:10.229 | Disconnect USB |

Run 3:

| Action | Start (UTC) | End (UTC) | Description |
|---|---|---|---|
| A01 | 21:00:15.516 | 21:00:53.830 | USB attach |
| A02 | 21:01:07.722 | 21:01:30.049 | Open Explorer, navigate to USB root |
| A03 | 21:01:51.149 | 21:02:22.941 | Navigate to \PORTABLE\ |
| A04 | 21:02:40.794 | 21:03:01.176 | Launch HelloWorld.exe |
| A05 | 21:03:10.506 | 21:03:31.856 | Eject USB |
| A06 | 21:03:39.302 | 21:03:55.241 | Disconnect USB |

## 2. Artefact acquisition (per run)

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 4 -Run 1
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 4 -Run 2
D:\UOW\SEM3\msc-diss-7csef001w\scripts\scenarios> .\acquire_artefacts.ps1 -Scenario 4 -Run 3
```

Each acquisition mounted the corresponding post scenario snapshot (`scenario4_run1_post`, `scenario4_run2_post`, `scenario4_run3_post`) via Arsenal Image Mounter, copied the same set of channels and hives that the other scenarios use, and wrote a per run SHA-256 manifest.

Per run file counts and sizes:

| Run | Prefetch files | Event log files | Total files | Total size |
|---|---:|---:|---:|---|
| Run 1 | 355 | 5 | 369 | 135.18 MB |
| Run 2 | 353 | 5 | 367 | 133.70 MB |
| Run 3 | 349 | 5 | 363 | 133.36 MB |

Per run manifests:

- `run_1/artefacts/supporting/acquisition_manifest.csv` (369 SHA-256 rows)
- `run_2/artefacts/supporting/acquisition_manifest.csv` (367 SHA-256 rows)
- `run_3/artefacts/supporting/acquisition_manifest.csv` (363 SHA-256 rows)

All committed to git even though the raw files they hash are not.

## 3. Artefact parsing (per run)

Same Zimmerman toolchain applied to each run separately, output into that run's `artefacts/analysis/` folder.

Per run parsed row counts:

| File | Run 1 | Run 2 | Run 3 |
|---|---:|---:|---:|
| PECmd summary (`scenario_4_runN_prefetch.csv`) | 349 | 348 | 344 |
| PECmd timeline (`scenario_4_runN_prefetch_Timeline.csv`) | 1,218 | 1,200 | 1,188 |
| EvtxECmd output | 30,521 | 30,150 | 30,000 |
| SBECmd NTUSER | 0 | 0 | 0 |
| SBECmd UsrClass | 15 | 13 | 13 |

Distinctive HelloWorld.exe Prefetch rows across the three runs (all pointing at the USB volume path, all firing at the corresponding A04 second):

| Run | RunTime (UTC) | ExecutableName | Volume0Name | Volume0Serial |
|---|---|---|---|---|
| Run 1 | 2026-08-22 11:49:06 | HELLOWORLD.EXE | \VOLUME{01dd13b23dcb8909-043dd6e4} | 430D6E4 |
| Run 2 | 2026-08-22 20:35:47 | HELLOWORLD.EXE | \VOLUME{01dd13b23dcb8909-043dd6e4} | 430D6E4 |
| Run 3 | 2026-08-22 21:02:44 | HELLOWORLD.EXE | \VOLUME{01dd13b23dcb8909-043dd6e4} | 430D6E4 |

The volume GUID and serial are identical across all three runs, which is the primary reproducibility evidence for the "executable from removable media" attribution.

Distinctive EVTX events across the three runs. Each USB attach produces a rich EVTX chain: DriverFrameworks 2005 (module load) x14, 2000/2001 (host startup), 2003/2010 (device arrival), 2004/2006 (add device), plus Security 6416 (device install) with the USB device ID, plus Partition EID 1006 naming the device model:

| Run | Attach EVTX signature |
|---|---|
| Run 1 | 6416 DeviceId USB\VID_ABCD&PID_1234\6&39d724fe&0&6 (VMware synthetic PnP identifier), Partition 1006 Model: UDisk |
| Run 2 | 6416 DeviceId USB\VID_0E0F&PID_0002\6&39d724fe&0&7, Partition 1006 Model: UDisk, plus WPDClassInstaller 24576/24577/24579 (first time device install triggered by this VM state), SCM 7045 "WPD File System driver", UserPnp 20003 ServiceName WUDFWpdFs |
| Run 3 | Same as Run 2: 6416 DeviceId USB\VID_0E0F&PID_0002\6&39d724fe&0&7, Partition 1006 Model: UDisk |

The VMware synthetic PnP identifier issue is documented as a research finding in section 6 below.

## 4. Window filtering (per run)

```powershell
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 4 -Run 1
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 4 -Run 2
D:\UOW\SEM3\msc-diss-7csef001w\scripts\analysis> .\window_filter.ps1 -Scenario 4 -Run 3
```

Per run windowed row counts:

| File | Run 1 | Run 2 | Run 3 |
|---|---:|---:|---:|
| `windows.csv` | 6 | 6 | 6 |
| `*_prefetch_Timeline_windowed.csv` | 30 | 31 | 20 |
| `events_windowed.csv` | 200 | 216 | 157 |
| `NTUSER.csv` | 0 | 0 | 0 |
| `UsrClass.csv` | 15 | 13 | 13 |

Per action Prefetch hits across three runs:

| Action | Run 1 PF | Run 2 PF | Run 3 PF |
|---|---:|---:|---:|
| A01 attach | 1 | 9 | 10 |
| A02 nav USB root | 19 | 1 | 1 |
| A03 nav PORTABLE | 2 | 2 | 1 |
| A04 exec HelloWorld | 6 | 4 | 4 |
| A05 eject | 2 | 15 | 3 |
| A06 disconnect | 0 | 0 | 1 |

Per action ShellBag hits across three runs:

| Action | Run 1 SB | Run 2 SB | Run 3 SB |
|---|---:|---:|---:|
| A02 nav USB root | 3 (includes Desktop\This PC\E:) | 0 | 0 |
| A03 nav PORTABLE | 1 (Desktop\E:\\PORTABLE) | 1 | 1 |
| A05 eject | 6 (namespace refresh incl. Desktop\E:\\) | 5 | 5 |

## 5. Correlation (per run)

Per action analyses with evidence citations in `run_1/evaluation/correlation_table.md`, `run_2/evaluation/correlation_table.md`, `run_3/evaluation/correlation_table.md`.

### 5.1 Per action verdicts across three runs

| Action | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| A01 USB attach | CONFIRMED | CONFIRMED | CONFIRMED |
| A02 nav USB root | CONFIRMED | PARTIAL | PARTIAL |
| A03 nav PORTABLE | CONFIRMED | CONFIRMED | CONFIRMED |
| A04 exec HelloWorld.exe | CONFIRMED | CONFIRMED | CONFIRMED |
| A05 eject USB | CONFIRMED | CONFIRMED | CONFIRMED |
| A06 disconnect USB | PARTIAL | PARTIAL | PARTIAL |

Five of six actions reproduce their verdict exactly across all three runs. A02 shows a one run variance driven by when the UsrClass hive flush lands relative to the short A02 window. The A03 and A05 rows confirm the primary research finding: the USB volume path (E:\ and E:\\PORTABLE) is written to UsrClass BagMRU in every run.

### 5.2 Summary of evidence per action

| Action | Attributes it |
|---|---|
| A01 USB attach | DriverFrameworks EIDs 2003 (device arrival begin) plus 2010 (device arrival end); Partition EID 1006 with Model: UDisk; Security EID 6416 with the USB device ID; WUDFHOST prefetch |
| A02 nav USB root | UsrClass BagMRU row for `Desktop\This PC\E:` (or namespace refresh in Runs 2 and 3); Security EID 4663 object access on removable drive resources |
| A03 nav PORTABLE | UsrClass BagMRU row for `Desktop\E:\\PORTABLE` (all three runs); RUNDLL32 prefetch as Explorer namespace helper |
| A04 exec HelloWorld.exe | HELLOWORLD.EXE prefetch with USB volume path attribution; Security EID 4688 with parent explorer.exe (user double click origin) |
| A05 eject USB | UsrClass BagMRU namespace refresh row for `Desktop\E:\\`; Partition EID 1006 for the same UDisk device on the eject side (closes device lifecycle loop); RUNDLL32 prefetch as Explorer eject helper |
| A06 disconnect USB | DriverFrameworks EIDs 2100 (device removal), 2102 (device request), 2900/2901 (host shutdown), 1006/1008 (driver manager shutdown); Partition EID 1006 for the same UDisk device on the disconnect side |

### 5.3 Full row by row correlation tables

See `run_1/evaluation/correlation_table.md`, `run_2/evaluation/correlation_table.md`, `run_3/evaluation/correlation_table.md`.

## 6. Key findings

1. USB device lifecycle attribution is the study's strongest end to end evidential chain. Attach (A01), navigation (A02, A03), execute (A04), eject (A05), disconnect (A06) all produce distinct EVTX signatures that name the same device (Model: UDisk via Partition Diagnostic EID 1006 on both attach and disconnect sides), and ShellBags record the volume letter (E:) as it becomes visible. This is the reference example of three artefact triangulation working end to end.

2. The HelloWorld.exe execution from USB reliably produces Prefetch with volume path attribution to the removable volume. The volume GUID `\VOLUME{01dd13b23dcb8909-043dd6e4}` and volume serial `430D6E4` are identical across all three runs, satisfying the reproducibility claim for the "executable launched from removable media" attribution class.

3. VMware synthetic PnP identifiers do not match the physical USB stick's Windows Device Manager identity. Run 1 recorded `VID_ABCD&PID_1234` in the Security 6416 event, Runs 2 and 3 recorded `VID_0E0F&PID_0002`. Neither matches the physical stick's Device Manager view (`USBSTOR\DISK&VEN_GENERAL&PROD_UDISK&REV_5.00\6&38E547A7&2&_&0`). Forensic hardware identification of a specific physical device inside a VMware guest requires cross referencing VMware's per VM USB pass through logs. This is a research worthy finding about virtualised guest forensics that will be discussed in the evaluation chapter.

4. A02 (navigate to USB root) shows across run variance in ShellBag hit count. Run 1 captured the `Desktop\This PC\E:` BagMRU row inside the A02 window; Runs 2 and 3 did not, because the hive flush landed later (inside A05's window instead). This is a windowing artefact, not a coverage gap: the ShellBag entry exists in every run, it just lands in a different action window depending on Windows' hive persistence timing. Correlation methodology should account for ShellBag write latency of tens of seconds when scoring short action windows.

