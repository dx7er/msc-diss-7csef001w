# Windows Configuration State

Non-default settings applied to the guest for forensic instrumentation. Every entry here must be justified in the report's methodology chapter as a deliberate testbed control.

## Identity and locale

| Setting | Value | Set in step |
|---------|-------|-------------|
| Computer name | disstestbedvm | Set during OOBE (Step 1) |
| Primary account | dfanalyst (local) | Step 1 |
| Account SID | `S-1-5-21-4209295338-567392030-2519289182-1001` | Step 2 |
| Windows 11 build | 26200.6584 (DisplayVersion 25H2) | Step 2 |
| Windows updates installed (Step 4) | KB5094126, KB5094135, KB5095189, KB5087051, KB5054156 (all 14/07/2026), plus KB5064531 from ISO. No Preview updates. | Step 4 |
| VMware Tools | 12.4.5.49651 (build 23787635) | Step 4 |
| Windows Update service | Disabled (`wuauserv`, `UsoSvc`) after stable updates installed | Step 4 (end) |
| Timezone | UTC (BaseUtcOffset 00:00:00) | Step 3 |
| System locale | en-US (LCID 1033) | Step 3 |
| User language list | en-US | Step 3 |
| Culture | en-US | Step 3 |
| Windows.old removed | Yes, deleted before Step 3 | Post-Step 2 |

## Encryption and power

| Setting | Value | Set in step |
|---------|-------|-------------|
| BitLocker on C: | Off (verified: Version None, Fully Decrypted, Protection Off, no Key Protectors) | Step 5 |
| vTPM | Present but unused | Step 1 |
| Hibernation | Off (`powercfg /hibernate off`); `hiberfil.sys` absent | Step 5 |
| Standby timeout on AC | 0 (never sleep) | Step 5 |
| Fast Startup | Off (implied by hibernation off) | Step 5 |
| Active power scheme | Balanced (`381b4222-f694-41f0-9685-ff5bb260df2e`) | Step 5 |

## Audit policy

Group Policy: **Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy category settings** = Enabled.

Enabled subcategories (Step 6):

| Subcategory | Success | Failure |
|-------------|---------|---------|
| Process Creation | Yes | No |
| Process Termination | Yes | No |
| Logon | Yes | Yes |
| Logoff | Yes | No |
| Other Logon/Logoff Events | Yes | No |
| Plug and Play Events | Yes | No |
| Removable Storage | Yes | Yes |

Additional policy: **Include command line in process creation events** = Enabled. This causes Security event 4688 to contain the full process command line.

Not enabled: global File System auditing (would require SACLs and creates noise).

Provenance:

- Baseline `auditpol` state before changes: `C:\DISS_Config\audit-before.csv`
- Final `auditpol` state: `C:\DISS_Config\audit-after.csv`
- Policy backup: `C:\DISS_Config\audit-policy-backup.csv`
- All three copied to `testbed/config-snapshots/step-06/`.

## Event log capacity

| Log | Size | Set in step |
|-----|------|-------------|
| Security | 256 MB (268435456 bytes) | Step 7 |
| System | 128 MB (134217728 bytes) | Step 7 |
| Application | 128 MB (134217728 bytes) | Step 7 |
| Microsoft-Windows-DriverFrameworks-UserMode/Operational | 32 MB, enabled | Step 7 |

Configuration exports (from `wevtutil gl ... /f:xml`):

- `Security-Log-Config.xml`
- `System-Log-Config.xml`
- `Application-Log-Config.xml`

Stored in `testbed/config-snapshots/step-07/`.

## Prefetch

| Setting | Value | Set in step |
|---------|-------|-------------|
| `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters\EnablePrefetcher` | 3 | Verified Step 8 |
| SysMain service | Running | Verified Step 8 |
| Disk media type (guest view) | TBD | Step 8 |

Prefetch was not modified. If the registry value is missing on first boot, the pilot (Step 14) determines whether Prefetch is being generated in practice.

## Test data staging

Root: `C:\DISS_TESTDATA\`

| Path | Purpose |
|------|---------|
| `PILOT\P00R01_BROWSED_A7K9\ALPHA\BRAVO\CHARLIE\` | Browsed during pilot (positive) |
| `PILOT\P00R01_UNBROWSED_Q4M2\ALPHA\BRAVO\CHARLIE\` | Negative control, never opened in Explorer |

Naming scheme: `S{NN}_{name}_{token}.{ext}` where token is a unique 4-character alphanumeric string per scenario and repetition. Tokens allow unambiguous grep across artefact CSVs.

## VMware guest isolation

Applied in Step 10:

- Drag-and-drop: disabled
- Copy-and-paste: disabled
- Shared folders: disabled, none configured
- CD/DVD: disconnected, no ISO
- USB controller: present, "Ask me what to do", no auto-connect
- Network adapter: Host-only, disconnected at power on
- VMware Tools updates: manual
- AutoProtect: disabled
- Snapshot mode: power off, not suspend
- VMware periodic time sync: disabled (one-off boot/restore correction retained)

## Software installed for scenarios

| Application | Version | Installed | Purpose in scenarios |
|-------------|---------|-----------|----------------------|
| Notepad (built-in) | Windows 25H2 default | Baseline | Application-launch scenario |
| TBD | | | |
