# VM Testbed

Single reference for the Windows 11 forensic testbed used in this dissertation. Combines what was previously split across the testbed checklist, VM specification, and snapshot log. Only steps and configurations actually executed are documented here.

## Identity

| Field | Value |
|-------|-------|
| Testbed identifier | TB W11 25H2 01 |
| Computer name | disstestbedvm |
| Primary account | dfanalyst (local, no Microsoft Account) |
| Account SID | `S-1-5-21-4209295338-567392030-2519289182-1001` |
| VM directory (host) | `D:\UOW\SEM3\DISS-Win11-Testbed-VM\` |
| Config output directory (guest) | `C:\DISS_Config\` |
| Timestamp policy | All UTC in ISO 8601 (e.g. `2026-07-14T15:34:21.382Z`) |

## Hypervisor

| Field | Value |
|-------|-------|
| Product | VMware Workstation Pro 17 |
| Exact version | 17.6.2 build 24409262 |
| Host OS | Windows 11 Pro 64 bit, build 26200.8973 |
| VMware Tools version | 12.4.5.49651 (build 23787635) |
| Snapshot mode | Power off (not suspend) |
| AutoProtect | Disabled |

## Guest OS

| Field | Value |
|-------|-------|
| Product | Windows 11 Pro |
| Display version | 25H2 |
| CurrentBuild | 26200 |
| UBR | 6584 |
| ProductName (registry, legacy) | `Windows 10 Pro` (known Win11 quirk; DisplayVersion is authoritative) |
| Locale | en_US (LCID 1033) |
| System language | en_US |
| Timezone | UTC (BaseUtcOffset 00:00:00) |
| Windows.old | Removed before Step 3 |

## Virtual hardware

| Field | Value |
|-------|-------|
| vCPU | 4 |
| RAM | 7 GB |
| Disk | 80 GB dynamic, split VMDK |
| vTPM | Enabled but unused |
| Firmware | UEFI Secure Boot |
| Network adapter | NAT, connected (approved by Jade 2026-08-06; supersedes original host only plan) |
| USB controller | Present, "Ask me what to do", no auto connect |
| CD/DVD | Disconnected, no ISO |
| Shared folders | Disabled |
| Drag and drop | Disabled |
| Copy and paste | Disabled |

## Storage and encryption

| Field | Value |
|-------|-------|
| Disk media type (guest view) | SSD, BusType NVMe (VMware Virtual NVMe Disk, 80 GB) |
| BitLocker on C: | Off (Version None, Fully Decrypted, no Key Protectors) |
| Hibernation | Off (`powercfg /hibernate off`, `hiberfil.sys` absent) |
| Standby timeout on AC | 0 (never sleep) |
| Fast Startup | Off |
| Active power scheme | Balanced (`381b4222-f694-41f0-9685-ff5bb260df2e`) |

## Windows updates and services

| Field | Value |
|-------|-------|
| Updates installed | KB5094126, KB5094135, KB5095189, KB5087051, KB5054156 (all 14/07/2026), plus KB5064531 from ISO. No Preview updates. |
| Windows Update service | Disabled (`wuauserv`, `UsoSvc`) after stable updates installed |

## Time synchronisation

| Field | Value |
|-------|-------|
| VMware periodic timesync | Disabled |
| VMware one off timesync at boot / snapshot restore | Retained |
| Time source of record | Guest UTC clock after post boot correction |

## Audit policy

Group Policy: **Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings** = Enabled.

Enabled subcategories:

| Subcategory | Success | Failure |
|-------------|---------|---------|
| Process Creation | Yes | No |
| Process Termination | Yes | No |
| Logon | Yes | Yes |
| Logoff | Yes | No |
| Other Logon/Logoff Events | Yes | No |
| Plug and Play Events | Yes | No |
| Removable Storage | Yes | Yes |

Additional: **Include command line in process creation events** = Enabled. Security event 4688 now contains the full command line.

Not enabled: global File System auditing (would require SACLs and creates noise).

Evidence in `scenarios/testbed_evidence/`: `audit-before.csv`, `audit-after.csv`, `audit-policy-backup.csv`, `audit-subcategories.txt`, `audit-registry.txt`.

## Event log capacity

| Log | Size |
|-----|------|
| Security | 256 MB (268435456 bytes) |
| System | 128 MB (134217728 bytes) |
| Application | 128 MB (134217728 bytes) |
| Microsoft Windows DriverFrameworks UserMode/Operational | 32 MB, enabled |

Configuration exports (`wevtutil gl ... /f:xml`) in `scenarios/testbed_evidence/`: `Security-Log-Config.xml`, `System-Log-Config.xml`, `Application-Log-Config.xml`, `DriverFrameworks-Log-Config.xml`. USB related channel inventory in `USB-Event-Channels.txt`.

## Prefetch

| Field | Value |
|-------|-------|
| `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters\EnablePrefetcher` | 3 |
| SysMain service | Running, StartType Automatic |
| Prefetch directory | `C:\Windows\Prefetch\` populated with `.pf` files |

Prefetch was not modified. Evidence in `scenarios/testbed_evidence/Prefetch-Config.txt`.

## Test data staging

Root: `C:\DISS_TESTDATA\`

Naming scheme: `S{NN}_{name}_{token}.{ext}` where token is a unique 4 character alphanumeric string per scenario. Tokens allow unambiguous grep across artefact CSVs. Baseline manifest in `scenarios/testbed_evidence/Test-Data-Manifest.txt`. Per scenario preconditions (folder trees, staged files) are documented in `scenarios/catalogue.md`.

## Software installed for scenarios

| Application | Version | Installed | Purpose |
|-------------|---------|-----------|---------|
| Notepad (built in) | Windows 25H2 default | Baseline | Application launch |
| Chrome, WinRAR, VLC, Adobe Reader, Zoom, Notepad++ | Latest at run time | Installed as part of scenario S01 | Cross artefact correlation (see `scenarios/catalogue.md`) |

## Build steps executed

Steps 1 to 11 of the original setup checklist were performed against `C:\DISS_Config\`, with outputs copied to `scenarios/testbed_evidence/`. High level summary:

1. **Install Windows 11 Pro 25H2** in VMware. Local account `dfanalyst`. Windows.old removed before baseline.
2. **Verify installation.** Recorded ProductName, EditionID, DisplayVersion, CurrentBuild, UBR, and account SID via `Get-ItemProperty` and `whoami /user`.
3. **Identity, computer name, UTC.** `Rename-Computer` to `disstestbedvm`, `Set-TimeZone UTC`, captured `Locale.txt` and `Language-List.txt`.
4. **Updated to a known patch level** with NAT temporarily enabled. Installed VMware Tools. Recorded `Installed-Hotfixes.txt`, `Defender-Version.txt`, `VMware-Tools-Version.txt`. Windows Update service disabled after.
5. **Encryption and power.** BitLocker off on C: (verified via `manage-bde -status`). Hibernation off. Standby timeout on AC = 0.
6. **Audit policy.** Group policy override enabled; process creation, process termination, logon/logoff, PnP, and removable storage subcategories set as per the table above. Command line inclusion in 4688 enabled. `auditpol` before/after CSVs captured.
7. **Event log capacity.** Security 256 MB, System 128 MB, Application 128 MB. DriverFrameworks UserMode/Operational enabled at 32 MB. XML configs exported.
8. **Prefetch readiness.** `EnablePrefetcher = 3`, `SysMain` running. `Prefetch-Config.txt` captured.
9. **Staged synthetic test data** under `C:\DISS_TESTDATA\`. Per scenario tokens and folder trees defined in `scenarios/catalogue.md`.
10. **VMware isolation applied.** Network switched to NAT (per Jade approval), guest isolation options set (no drag drop, no copy paste, no shared folders, CD/DVD disconnected, AutoProtect off, snapshot mode "power off"). VMware periodic timesync disabled; one off timesync at boot retained.
11. **Candidate baseline snapshot** taken from powered off state: `B00-CANDIDATE-W11-25H2-26200.6584-20260717` (2026-07-17T19:30:58Z).

## Snapshot log

Naming convention:

```
<ROLE>-W11-25H2-<CurrentBuild.UBR>-<YYYYMMDD>
```

Roles:

- `B00-CANDIDATE`: baseline candidate produced in Step 11; treated as the working baseline.
- `S00-UNIVERSAL-PRE`: child of `B00-CANDIDATE`, used as the single revert point at the start of every scenario run so the original candidate is never mutated.
- `S{NN}-R{NN}-POST`: post scenario state before evidence acquisition, one per scenario per repetition.

| Snapshot name | Type | Created (UTC) | Notes |
|---------------|------|---------------|-------|
| B00-CANDIDATE-W11-25H2-26200.6584-20260717 | Baseline candidate (working baseline) | 2026-07-17T19:30:58Z (host local: 20:30:58 BST) | Windows 26200.6584, VMware Tools 12.4.5, 4 vCPU / 7 GB RAM / 80 GB, UTC, audit on, WU disabled, NAT connected, BitLocker off. NAT approved by Jade 2026-08-06. |
| S00-UNIVERSAL-PRE | Universal pre scenario restore point | 2026-08-12T09:26:54Z (host local: 10:26:54 BST) | Child of B00-CANDIDATE; single revert point used before every scenario run. |
| S01-R01-POST | Post scenario, S01 R01 | 2026-08-17 | Six application installs (Chrome, WinRAR, VLC, Adobe Reader, Zoom, Notepad++). Acquired 2026-08-17. |
