# VM Specification

Hardware and hypervisor state for the forensic testbed. Fields marked `TBD` are captured during setup steps and updated as we progress.

## Identity

| Field | Value |
|-------|-------|
| Testbed identifier | TB-W11-25H2-01 |
| Computer name | DISS-W11-25H2 |
| Primary account | DISSUser (local, no Microsoft Account) |
| Account SID | TBD (captured in Step 2) |
| VM directory (host) | `D:\UOW\SEM3\DISS-Win11-Testbed-VM\` |

## Hypervisor

| Field | Value |
|-------|-------|
| Product | VMware Workstation Pro 17 |
| Exact version | TBD (record from `Help -> About`) |
| Host OS | TBD (Windows 11 on host machine) |
| VMware Tools version | TBD (captured in Step 4) |
| Snapshot mode | Power off (not suspend) |
| AutoProtect | Disabled |

## Guest OS

| Field | Value |
|-------|-------|
| Product | Windows 11 Pro |
| Display version | 25H2 |
| CurrentBuild | TBD (captured in Step 2) |
| UBR | TBD (captured in Step 2) |
| Locale | TBD (captured in Step 3) |
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
