# VM Specification

Hardware and hypervisor state for the forensic testbed. Fields marked `TBD` are captured during setup steps and updated as we progress.

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
| Host OS | TBD (Windows 11 on host machine) |
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
| Timezone | UTC |

## Virtual hardware

| Field | Value |
|-------|-------|
| vCPU | 4 |
| RAM | 7 GB |
| Disk | 80 GB dynamic, split |
| vTPM | Enabled |
| Firmware | UEFI Secure Boot |
| Network adapter | Host-only, disconnected at power on (final state) |
| USB controller | Present, set to "Ask me what to do", no auto-connect |
| CD/DVD | Disconnected, no ISO |
| Shared folders | Disabled |
| Drag-and-drop | Disabled |
| Copy-and-paste | Disabled |

## Storage and encryption

| Field | Value |
|-------|-------|
| Disk media type (guest view) | TBD (captured in Step 8, `Get-PhysicalDisk`) |
| BitLocker on C: | Disabled (verified in Step 5) |
| Hibernation | Disabled (Step 5) |
| Fast Startup | Disabled (Step 5) |

## Time synchronisation

| Field | Value |
|-------|-------|
| VMware periodic timesync | Disabled (Step 10) |
| VMware one-off timesync at boot / snapshot restore | Retained |
| Time source of record | Guest UTC clock after post-boot correction |

## Baseline snapshots

Tracked in `snapshots.md`.

## Independent backups

Location: `D:\UOW\SEM3\Backups\`
Naming: `<snapshot-name>` mirrored, with `-SHA256.csv` manifest alongside.
