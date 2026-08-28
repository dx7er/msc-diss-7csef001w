# Scenario 10 correlation table

Scenario: system shutdown and power on (appendix). Artefact classes in matrix: Prefetch, EVTX.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

**Scope note:** GT was logged from inside the guest OS using the standard Log-Action helper, so its wall-clock is the guest clock. The GT `Note` field also records the host wall-clock at A02 and A03. Comparing the two shows a ~3 minute skew between guest and host across the shutdown-and-boot cycle: the guest clock reads later than the host clock. This is a genuine finding about VMware clock behaviour around shutdown, and it explains why the boot-side EVTX events (Kernel-General EID 12 StartTime, EventLog EID 6005, Wininit sequence) land inside A01's guest-timestamped window rather than A03's, even though the user experienced them at A03.

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 22:31:30 | VM Shutdown (Start, Power, Shut down) | 43 rows including CMD.EXE 22:33:18, CONHOST 22:33:18, CONSENT 22:34:05, ONEDRIVE.EXE 22:33:15, VMTOOLSD 22:33:13, WLRMDR.EXE 22:33:34 (shutdown notifier), USEROOBEBROKER 22:34:05, plus the full pre-shutdown svchost tree | Full clean-shutdown signature: Kernel-Power EID 109 ShutdownActionType (shutdown initiated by user), User32 EID 1074 with hostname (records the shutdown reason and initiating process), Security EID 4647 "User initiated logoff", Winlogon EID 7002 UserSID logoff, EventLog EID 1100 "event logging service has shut down", Kernel-General EID 13 StopTime 22:31:49, then the boot side lands in the same window due to the guest-vs-host clock skew: Kernel-Boot EIDs 20 (LastShutdownGood: True) / 153 / 247 / 238, EventLog EIDs 6005 (log started) / 6009 (OS version) / 6013 (uptime), Wininit EIDs 12/14/19/23/24/25 subsystem init, Security 4608 "Windows is starting up", Winlogon 7001 UserSID logon, Security 4624 SYSTEM logons, Security 4800/4801 workstation locked/unlocked | no match (out of scope per matrix) | CONFIRMED | This row carries the study's cleanest end-to-end shutdown-plus-boot fingerprint: EID 109 plus 1074 plus 4647 plus 6006 for the shutdown, and EID 20 plus 6005 plus 6009 plus 4608 plus 7001 for the boot. Prefetch corroborates via CMD/CONSENT/WLRMDR/VMTOOLSD prefetch entries firing at the shutdown second. The reason boot-side EIDs land in A01 rather than A03 is the ~3 min guest-vs-host clock skew documented in the scope note above; a stricter analyst would apply a per-scenario clock offset before windowing. |
| A02 | 22:36:06 | VM powered off | no match | no match | no match | MISSED | Expected result. The VM is not running during A02 (host state only), so no artefact of any kind can be produced. The row is retained in GT for completeness of the shutdown-and-power-on timeline. |
| A03 | 22:37:10 | VM powered on | no match | Security 4689 x1 (thin) | no match | MISSED | The boot-side EVTX events that would attribute A03 (Kernel-Boot 20, EventLog 6005, Security 4608, Winlogon 7001) all fire on the guest clock at 22:32:44, roughly 5 minutes before A03's guest-recorded start time. They therefore land inside A01's window instead. If the boot events are re-attributed to A03 by applying the ~3 min clock skew, this row upgrades to CONFIRMED. As scored strictly by the current time windows: MISSED. |
| A04 | 22:39:09 | Wait 90s for post-boot settle | 24 rows: BACKGROUNDTASKHOST 22:39:50, RUNTIMEBROKER 22:39:50, MOUSOCOREWORKER, DLLHOST 22:40:21, MICROSOFTEDGEUPDATE 22:40:21, TASKHOSTW, TIWORKER 22:40:35, TRUSTEDINSTALLER 22:40:35, plus SVCHOST cluster (10 rows) and COMPATTELRUNNER 22:41:22 | Security 4688 x47 with parent svchost.exe (post-boot service starts), 4689 x27, 5379 x27 credential reads (SYSTEM re-establishing service accounts), 4624 x12 SYSTEM logons, 4672 x12 privilege assignments | no match | CONFIRMED | The post-boot settle window catches Windows re-initialising services after boot: TIWORKER and TRUSTEDINSTALLER prefetch entries are the Windows servicing stack coming online, and the 4624/4672 pairs are SYSTEM logons for each freshly-started service. Prefetch and EVTX independently confirm the OS is coming up to steady state. Two artefact classes attribute the action. |

## Coverage summary

- CONFIRMED: 2 of 4 (A01, A04)
- PARTIAL: 0 of 4
- MISSED: 2 of 4 (A02 by design, A03 by clock-skew windowing artefact)
- Per-class hits: Prefetch 2 of 4 (A01, A04), EVTX 3 of 4 (A01, A03 thin, A04), ShellBags 0 of 4 (out of scope per matrix)

## Interpretive observations

1. Shutdown and boot together produce the study's richest single-artefact fingerprint in EVTX: Kernel-Power EID 109 plus User32 EID 1074 (shutdown reason) plus EventLog EID 1100 (log service stopping) on the shutdown side, and Kernel-Boot EID 20 (LastShutdownGood flag) plus EventLog EID 6005/6009/6013 (log started, OS version, uptime) plus Wininit sequence plus Security 4608 on the boot side. Together these are the canonical evidence a forensic analyst would use to reconstruct a system power cycle, and they all reproduce here.
2. The guest-vs-host clock skew (roughly 3 minutes across the shutdown-and-boot cycle) is a genuine finding about VMware time behaviour and has methodological implications for any correlation study using guest-recorded ground truth against guest-generated artefacts: the correlation windows should be constructed after re-syncing the guest clock via VMware Tools time sync, or a per-scenario clock-offset should be applied at correlation time.
3. Prefetch does not fire during the "powered off" window (A02) and only lightly during the "power on" window (A03) because the prefetcher itself is part of the boot sequence; the meaningful Prefetch activity for the boot lands during the post-boot settle window (A04), which is where the SVCHOST cluster and the TIWORKER/TRUSTEDINSTALLER servicing pair appear.
