# Testbed Setup Checklist

Master procedure for building the Windows 11 forensic testbed used in this dissertation. Follow the steps in order. Do not begin formal data collection until Step 15 has passed.

**Testbed identifier:** TB-W11-25H2-01<br>
**Guest OS:** Windows 11 Pro 25H2<br>
**Hypervisor:** VMware Workstation Pro 17<br>
**VM directory (host):** `D:\UOW\SEM3\DISS-Win11-Testbed-VM\`<br>
**Config output directory (guest):** `C:\DISS_Config\`<br>
**Backup directory (host):** `D:\UOW\SEM3\Backups\`<br>
All timestamps are UTC in ISO 8601 format (`2026-07-14T15:34:21.382Z`).

---

## 1. Install Windows 11 Pro 25H2 in VMware Workstation Pro 17

**Purpose.** Produce a running VM whose hardware and identity match the proposal.

**Actions.**

- Create a new VM in VMware Workstation Pro 17.
- Allocate 4 vCPU, 7 GB RAM, 80 GB dynamic disk (split), vTPM enabled.
- Install Windows 11 Pro 25H2 from official ISO.
- Complete OOBE with a local account (no Microsoft account). Account used in this build: `dfanalyst`.

**Post-install check for residual installation trees.** If C:\ contains `Windows.old`, `$WINDOWS.~BT`, or `$WINDOWS.~WS` from a prior install attempt, record their presence in `vm-specification.md` and remove them before Step 11 (candidate snapshot). `Windows.old` contains a full prior Windows tree with its own Prefetch, event logs and registry hives, which would contaminate baseline artefacts if left in place.

```powershell
# Remove leftover Windows.old (run once, only before candidate baseline)
if (Test-Path C:\Windows.old) {
    takeown /F C:\Windows.old /R /D Y | Out-Null
    icacls C:\Windows.old /grant administrators:F /T | Out-Null
    Remove-Item -Path C:\Windows.old -Recurse -Force
}
```

**Records.** Note ISO SHA-256 and installation date in `vm-specification.md`.

---

## 2. Verify the installation matches the proposal

**Purpose.** Confirm the guest is the correct edition, version and build before any further configuration. Capture the account SID; per-user artefacts (ShellBags, per-user Prefetch traces, event log records) are indexed by SID.

**Actions (inside the guest, PowerShell as Administrator).**

```powershell
New-Item -ItemType Directory -Path C:\DISS_Config -Force | Out-Null

Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
    Select-Object ProductName, EditionID, DisplayVersion, CurrentBuild, UBR |
    Format-List |
    Out-File C:\DISS_Config\Windows-Version.txt

Get-Content C:\DISS_Config\Windows-Version.txt

whoami           | Out-File C:\DISS_Config\Whoami.txt
whoami /user /fo list | Out-File C:\DISS_Config\Whoami-User.txt
Get-LocalUser    | Select-Object Name, Enabled, LastLogon, PasswordExpires |
    Out-File C:\DISS_Config\Local-Users.txt
```

**Required results.**

- `EditionID` = `Professional`
- `DisplayVersion` = `25H2`
- `CurrentBuild` and `UBR` recorded exactly (used later to justify Windows build in the methodology)

If `EditionID` is `Core` (Home), stop and reinstall with a Pro key.

**Records.** Copy `Windows-Version.txt`, `Whoami.txt`, `Whoami-User.txt`, `Local-Users.txt` from `C:\DISS_Config\` to `testbed/evidence/` in the repo.

---

## 3. Configure identity, computer name and UTC

**Purpose.** Fix the guest's identity for the rest of the study. UTC removes ambiguity from every artefact timestamp we later parse.

**Actions.**

```powershell
Rename-Computer -NewName "DISS-W11-25H2" -Restart
```

After restart:

```powershell
Set-TimeZone -Id "UTC"
Get-TimeZone
[DateTime]::UtcNow.ToString("o")

Get-WinSystemLocale     | Out-File C:\DISS_Config\Locale.txt
Get-WinUserLanguageList | Out-File C:\DISS_Config\Language-List.txt -Append
Get-Culture             | Out-File C:\DISS_Config\Locale.txt -Append
```

**Records.** `Locale.txt`, `Language-List.txt`. Update `vm-specification.md` with computer name, timezone, locale, language.

---

## 4. Finish updating before isolation

**Purpose.** Freeze the guest at a known patch level before we cut network access. No updates from this point onward during formal collection.

**Actions.**

- Temporarily set the VMware network adapter to NAT so updates can reach the internet.
- Install all normal stable Windows updates. Do NOT install Preview updates. Reboot. Repeat until no updates pending.
- Update Microsoft Store apps if any are used in scenarios.
- Install VMware Tools.
- Install every application needed for formal scenarios (Notepad ships by default; add anything else here).
- Reboot twice.

Record final state:

```powershell
Get-HotFix |
    Sort-Object InstalledOn -Descending |
    Select-Object HotFixID, Description, InstalledOn |
    Out-File C:\DISS_Config\Installed-Hotfixes.txt

Get-MpComputerStatus |
    Select-Object AMProductVersion, AMEngineVersion,
        AntivirusSignatureVersion, AntivirusSignatureLastUpdated |
    Format-List |
    Out-File C:\DISS_Config\Defender-Version.txt

(Get-Item 'C:\Program Files\VMware\VMware Tools\vmtoolsd.exe').VersionInfo |
    Select-Object FileVersion, ProductVersion |
    Format-List |
    Out-File C:\DISS_Config\VMware-Tools-Version.txt
```

**Records.** `Installed-Hotfixes.txt`, `Defender-Version.txt`, `VMware-Tools-Version.txt`. Copy to `testbed/evidence/`.

---

## 5. Check encryption and power behaviour

**Purpose.** BitLocker breaks offline VMDK acquisition. Hibernation and Fast Startup produce partial shutdowns that leave dirty registry hives and skew event log continuity.

**Actions.**

```powershell
manage-bde -status C:
```

If C: is encrypted:

```powershell
manage-bde -off C:
```

Wait until `manage-bde -status C:` reports fully decrypted. Do NOT remove the virtual TPM.

```powershell
powercfg.exe /hibernate off
powercfg.exe /change standby-timeout-ac 0
```

Document these as deliberate non-default testbed controls. Justification: the study requires clean, complete shutdowns to preserve artefact integrity across snapshots.

**Records.** Save BitLocker status output and note power settings in `vm-specification.md`.

---

## 6. Configure the audit policy

**Purpose.** Windows default auditing does not capture the events we need to correlate with Prefetch and ShellBag activity. We deliberately enable process creation, logon/logoff, plug-and-play and removable storage auditing. The methodology chapter must state that results represent a configured Windows 11 25H2 system, not a stock installation.

**Actions.** First capture the original policy for provenance:

```powershell
auditpol /get /category:* /r > C:\DISS_Config\audit-before.csv
auditpol /list /subcategory:* > C:\DISS_Config\audit-subcategories.txt
```

In `secpol.msc`, navigate to:

> Local Policies -> Security Options -> Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings

Set to **Enabled**.

Then run:

```powershell
auditpol /set /subcategory:"Process Creation"          /success:enable
auditpol /set /subcategory:"Process Termination"       /success:enable
auditpol /set /subcategory:"Logon"                     /success:enable /failure:enable
auditpol /set /subcategory:"Logoff"                    /success:enable
auditpol /set /subcategory:"Other Logon/Logoff Events" /success:enable
auditpol /set /subcategory:"Plug and Play Events"      /success:enable
auditpol /set /subcategory:"Removable Storage"         /success:enable /failure:enable
```

If any subcategory name is rejected, check `audit-subcategories.txt` and use the exact displayed name.

Enable process command line recording. In `gpedit.msc`:

> Computer Configuration -> Administrative Templates -> System -> Audit Process Creation -> Include command line in process creation events

Set to **Enabled**.

This causes Security event 4688 to include the full command line. Acceptable only because this is a synthetic lab; command lines would otherwise be considered PII.

Do NOT enable global File System auditing. It produces noise and requires SACLs on target objects.

Save the final policy:

```powershell
auditpol /get /category:* /r > C:\DISS_Config\audit-after.csv
auditpol /backup /file:C:\DISS_Config\audit-policy-backup.csv
```

**Records.** `audit-before.csv`, `audit-after.csv`, `audit-policy-backup.csv`, `audit-subcategories.txt`. Copy to `testbed/evidence/`. Update `vm-specification.md` with the enabled subcategory list.

---

## 7. Increase Event Log capacity

**Purpose.** Default Security log size is 20 MB, which rolls over quickly under Process Creation auditing. Rollover during a scenario destroys evidence.

**Actions.**

```powershell
wevtutil sl Security    /ms:268435456   # 256 MB
wevtutil sl System      /ms:134217728   # 128 MB
wevtutil sl Application /ms:134217728   # 128 MB
```

Inventory USB-related channels:

```powershell
wevtutil el |
    Select-String -Pattern "DriverFrameworks|Partition|Kernel-PnP|UserPnp|Storage" |
    Out-File C:\DISS_Config\USB-Event-Channels.txt
```

If present, enable the DriverFrameworks channel:

```powershell
wevtutil sl "Microsoft-Windows-DriverFrameworks-UserMode/Operational" /e:true /ms:33554432
```

Record final configuration:

```powershell
wevtutil gl Security    /f:xml > C:\DISS_Config\Security-Log-Config.xml
wevtutil gl System      /f:xml > C:\DISS_Config\System-Log-Config.xml
wevtutil gl Application /f:xml > C:\DISS_Config\Application-Log-Config.xml
```

Do NOT clear the logs. Baseline restoration will provide an identical starting state.

**Records.** All XML configs and `USB-Event-Channels.txt`. Copy to `testbed/evidence/`.

---

## 8. Check Prefetch readiness

**Purpose.** Confirm Prefetch is enabled and SysMain is running. Prefetch is disabled on some SSDs by default; if it is off, we cannot proceed with the study as scoped.

**Actions.**

```powershell
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' |
    Select-Object EnablePrefetcher
Get-Service SysMain
Get-PhysicalDisk |
    Select-Object FriendlyName, MediaType, BusType, Size
```

Expected: `EnablePrefetcher = 3`, `SysMain` running.

List existing prefetch files:

```powershell
Get-ChildItem C:\Windows\Prefetch -Filter *.pf |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 15 Name, Length, LastWriteTimeUtc
```

Do NOT delete any `.pf` files. Do NOT modify the registry value blindly if it is missing or unexpected. The pilot in Step 14 proves whether Prefetch is actually being generated.

**Records.** Screenshot or `Out-File` the three commands' output to `Prefetch-Config.txt`. Copy to `testbed/evidence/`.

---

## 9. Stage synthetic test data

**Purpose.** Create scenario folders before the baseline so their creation timestamps predate the experiment. Files opened during scenarios then have clear provenance.

**Actions.**

```powershell
New-Item -ItemType Directory -Force `
    'C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9\ALPHA\BRAVO\CHARLIE'
New-Item -ItemType Directory -Force `
    'C:\DISS_TESTDATA\PILOT\P00R01_UNBROWSED_Q4M2\ALPHA\BRAVO\CHARLIE'
```

The first path will be browsed during the pilot. The second is a negative control and must never be opened in File Explorer.

Populate with synthetic files, unique tokens per scenario:

- `S01_ProjectNotes_A7K9.txt`
- `S02_ConfidentialReport_Q4M2.docx`
- `S03_USBTransfer_N8P3.txt`

Do NOT browse the scenario folders during setup. Any Explorer navigation now creates ShellBag entries before the experiment.

**Records.** Update `vm-specification.md` with the test-data root path and the token-naming scheme.

---

## 10. Configure VMware Workstation

**Purpose.** Isolate the guest so the experiment is not contaminated by host clipboard, host clock, host USB devices or accidental network reachability.

**Actions.** Finish all Windows preparation before this step, because copy/paste to the guest will no longer work after it.

With the VM shut down, in `VM -> Settings`:

- **Options -> VMware Tools:** updates set to Manual.
- **Options -> Guest Isolation:** disable drag-and-drop, disable copy-and-paste.
- **Options -> Shared Folders:** Disabled. Remove any shares.
- **Hardware -> CD/DVD:** uncheck Connected, uncheck Connect at power on, disconnect the Windows ISO.
- **Options -> AutoProtect:** disabled.
- **Options -> Snapshots:** select "power off" rather than "suspend".
- **Hardware -> USB Controller:** keep. Set "Ask me what to do". Do NOT auto-connect host USB devices.
- **Hardware -> Network Adapter:** switch to Host-only. Uncheck Connected. Uncheck Connect at power on.

Host-only still allows guest-to-host communication, so the two connection boxes must remain unchecked during formal experiments.

**VMware time synchronisation.** Inside the guest, check periodic sync:

```powershell
& 'C:\Program Files\VMware\VMware Tools\VMwareToolboxCmd.exe' timesync status
```

If enabled:

```powershell
& 'C:\Program Files\VMware\VMware Tools\VMwareToolboxCmd.exe' timesync disable
```

Retain VMware's one-off correction at boot and snapshot restore, otherwise a restored snapshot may start with a stale clock. Wait for that correction before declaring experimental T0. Record host and guest clock offsets. Treat pre-run `vmtoolsd.exe` time change events in Security 4616 as documented control noise.

**Records.** Screenshot every VMware Settings tab. Copy to `testbed/evidence/`.

---

## 11. Create a candidate baseline (not the formal baseline)

**Purpose.** Snapshot the guest in its prepared state so the pilots in Step 14 can prove the configuration works. If a pilot fails, we revert and correct before promoting.

**Actions.**

- Restart Windows twice.
- Confirm the network adapter is disconnected.
- Wait approximately 10 minutes for background activity to settle.
- Capture screenshots of `winver`, VMware hardware, network configuration.
- Save systeminfo:

```powershell
systeminfo > C:\DISS_Config\systeminfo.txt
```

- Do NOT clean Prefetch, event logs or registry data.
- Shut Windows down normally.
- Take a powered-off snapshot named:

```
B00-CANDIDATE-W11-25H2-<BUILD>-<UTC-YYYYMMDD>
```

Example: `B00-CANDIDATE-W11-25H2-26200.1234-20260714`.

Snapshot description must include: Windows build and UBR, VMware Workstation version, VMware Tools version, vCPU/RAM/disk, UTC timezone, audit settings summary, network state, BitLocker state.

**Records.** Append snapshot entry to `snapshots.md` with UTC timestamp.

---

## 12. Make an independent baseline backup

**Purpose.** A snapshot is metadata on top of split VMDKs. If the base file is corrupted or accidentally deleted, the snapshot is worthless. An off-VM backup provides a real recovery point.

**Actions.** With the VM powered off and VMware Workstation fully closed, run on the host:

```powershell
$src = 'D:\UOW\SEM3\DISS-Win11-Testbed-VM'
$dst = 'D:\UOW\SEM3\Backups\B00-CANDIDATE-W11-25H2-20260714'
Copy-Item -LiteralPath $src -Destination $dst -Recurse

Get-ChildItem -LiteralPath $dst -Recurse -File |
    Get-FileHash -Algorithm SHA256 |
    Export-Csv "$dst-SHA256.csv" -NoTypeInformation
```

Copy the entire VM directory, not one `.vmdk`. Split disks and snapshot deltas mean a single-file copy will omit evidence.

**Records.** Store the `-SHA256.csv` alongside the backup. Note the backup name and manifest path in `snapshots.md`.

---

## 13. Validate offline acquisition before experiments

**Purpose.** Prove that we can pull artefacts out of the VMDK without booting the guest. If this does not work, no evidence collected during scenarios is trustworthy.

**Actions.** Using a copy of the candidate baseline (never the working VM):

- Verify the VMDK can be mounted read-only.
- Confirm VMware encryption and vTPM do not prevent access.
- Confirm C: is visible and decrypted.
- Test collection of:
  - `C:\Windows\Prefetch\`
  - `C:\Windows\System32\winevt\Logs\`
  - `C:\Users\dfanalyst\NTUSER.DAT*`
  - `C:\Users\dfanalyst\AppData\Local\Microsoft\Windows\UsrClass.dat*`

For ShellBags, retain the main hives plus `.LOG1`, `.LOG2`, `.TM.blf` and `.regtrans-ms` companions when present. Never mount the only copy read/write.

**Records.** Note the tools used to mount and hash, and store the acquisition manifest in `testbed/evidence/`.

---

## 14. Run two excluded pilot repetitions

**Purpose.** The pilots run the intended scenario workflow twice against the candidate baseline. If both produce the expected evidence, the baseline is ready for formal use. Pilot data is discarded; it is not part of the final findings.

**Pilot procedure (P00-R01, then P00-R02 from the identical baseline).**

1. Restore `B00-CANDIDATE`.
2. Start Windows and wait 60 seconds for VMware time correction.
3. Record host UTC and guest UTC.
4. Begin a host-side ground-truth log.
5. Open File Explorer.
6. Browse each level of `P00R01_BROWSED_A7K9`. Wait 15-30 seconds at each level.
7. Never browse the negative-control path.
8. Launch Notepad twice, closing it normally each time.
9. Press Win+L. Wait approximately 30 seconds. Unlock the VM.
10. If USB is in scope: attach a controlled USB, browse it, copy the synthetic file, safely eject, disconnect.
11. Close Explorer.
12. Wait 60-120 seconds.
13. Record final guest and host clock offset.
14. Shut Windows down normally. Do NOT boot again.
15. Preserve and hash the complete VM folder before reverting.
16. Acquire and parse targeted artefacts on the host.

**Ground-truth log columns.**

`RunID | ActionID | ActualAction | HostUTCStart | HostUTCEnd | TargetExecutable | TargetPath | ClockOffsetBefore | ClockOffsetAfter | ObservedOutcome | Deviation`

**Expected evidence.**

| Action | Expected evidence |
|--------|--------------------|
| Launch Notepad | Notepad Prefetch, Security 4688 |
| Browse unique folder | ShellBag path in NTUSER.DAT / UsrClass.dat |
| Lock and unlock | Security 4800, 4801 with associated 4624 |
| Connect USB | PnP/USB events (e.g. 6416), possibly removable storage events |
| Clean shutdown | Correct Event Log and registry hive flush |

**Records.** Pilot ground-truth CSVs, host acquisition logs and parsed output are committed to the repository. Raw evidence files are not committed; SHA-256 hashes and parsed CSVs are.

---

## 15. Promote the baseline

**Purpose.** Formalise the tested baseline. From this point onward no testbed changes are permitted during formal collection.

**Promotion criteria (both pilots must pass).**

- Prefetch is generated and PECmd parses it cleanly.
- Security 4688 recorded for the chosen application.
- Security 4800 and 4801 recorded for lock/unlock.
- Browsed unique path appears in ShellBag output.
- Unbrowsed negative-control path does NOT appear.
- USB events captured if USB is in scope.
- Event Logs did not roll over.
- Offline acquisition works.
- All raw evidence hashes verify.
- No forensic analysis tool ran inside the evidence VM.
- Host and guest clock offsets are within declared tolerance.

If anything fails, revert the candidate, correct the configuration, create `B01-CANDIDATE`, and repeat both pilots.

Once everything passes, rename or freeze the snapshot as:

```
B00-FORMAL-W11-25H2-<BUILD>-<UTC-YYYYMMDD>
```

No testbed, tool, application, audit-policy or parser-map changes are permitted after this point during formal data collection.

**Records.** Append promotion entry to `snapshots.md`. Update the top of this document to reference the formal baseline name.
