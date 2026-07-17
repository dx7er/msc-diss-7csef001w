# VM Specification and Windows Configuration

Single reference for the forensic testbed's hardware, hypervisor and Windows configuration state. Every non-default value here is a deliberate testbed control and must be justified in the report's methodology chapter.

Companion evidence for each control (audit CSVs, log config XMLs, Prefetch registry dump, etc.) is stored in `testbed/evidence/`. Reproducible build steps are in `testbed/testbed-checklist.md`.

## Identity

| Field | Value |
|-------|-------|
| Testbed identifier | TB-W11-25H2-01 |
| Computer name | disstestbedvm |
| Primary account | dfanalyst (local, no Microsoft Account) |
| Account SID | `S-1-5-21-4209295338-567392030-2519289182-1001` |
| VM directory (host) | `D:\UOW\SEM3\DISS-Win11-Testbed-VM\` |

## Hypervisor

| Field | Value |
|-------|-------|
| Product | VMware Workstation Pro 17 |
| Exact version | TBD (record from `Help -> About`) |
| Host OS | Windows 11 on host machine |
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
| Locale | en-US (LCID 1033) |
| System language | en-US |
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
| Network adapter | **NAT, connected** (isolation to Host-only + disconnected deferred pending supervisor sign-off; recorded in `snapshots.md`) |
| USB controller | Present, "Ask me what to do", no auto-connect |
| CD/DVD | Disconnected, no ISO |
| Shared folders | Disabled |
| Drag-and-drop | Disabled |
| Copy-and-paste | Disabled |

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
| VMware one-off timesync at boot / snapshot restore | Retained |
| Time source of record | Guest UTC clock after post-boot correction |

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

Evidence in `testbed/evidence/`: `audit-before.csv`, `audit-after.csv`, `audit-policy-backup.csv`, `audit-subcategories.txt`, `audit-registry.txt`.

## Event log capacity

| Log | Size |
|-----|------|
| Security | 256 MB (268435456 bytes) |
| System | 128 MB (134217728 bytes) |
| Application | 128 MB (134217728 bytes) |
| Microsoft-Windows-DriverFrameworks-UserMode/Operational | 32 MB, enabled |

Configuration exports (`wevtutil gl ... /f:xml`) in `testbed/evidence/`: `Security-Log-Config.xml`, `System-Log-Config.xml`, `Application-Log-Config.xml`, `DriverFrameworks-Log-Config.xml`. USB-related channel inventory in `USB-Event-Channels.txt`.

## Prefetch

| Field | Value |
|-------|-------|
| `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters\EnablePrefetcher` | 3 |
| SysMain service | Running, StartType Automatic |
| Prefetch directory | `C:\Windows\Prefetch\` populated with `.pf` files |

Prefetch was not modified. Evidence in `testbed/evidence/Prefetch-Config.txt`.

## Test data staging

Root: `C:\DISS_TESTDATA\`

| Path | Purpose |
|------|---------|
| `PILOT\P00R01_BROWSED_A7K9\ALPHA\BRAVO\CHARLIE\` | Browsed during pilot (positive) |
| `PILOT\P00R01_UNBROWSED_Q4M2\ALPHA\BRAVO\CHARLIE\` | Negative control, never opened in Explorer |

Naming scheme: `S{NN}_{name}_{token}.{ext}` where token is a unique 4-character alphanumeric string per scenario. Tokens allow unambiguous grep across artefact CSVs. Manifest in `testbed/evidence/Test-Data-Manifest.txt`.

## Software installed for scenarios

| Application | Version | Installed | Purpose |
|-------------|---------|-----------|---------|
| Notepad (built-in) | Windows 25H2 default | Baseline | Application-launch scenario |
| TBD | | | Pending scenario definition |

## Baseline snapshots

Tracked in `testbed/snapshots.md`. Current candidate: `B00-CANDIDATE-W11-25H2-26200.6584-20260717`.

## Independent backups

Location: `D:\UOW\SEM3\Backups\`. Naming: `<snapshot-name>` mirrored with `-SHA256.csv` manifest alongside. Deferred until baseline promotion.
