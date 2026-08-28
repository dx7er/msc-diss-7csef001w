# Scenario 8 correlation table

Scenario: command-line execution (appendix). cmd.exe and powershell.exe launched from Start, one built-in command run in each. Artefact classes in matrix: Prefetch, EVTX.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 20:18:10 | Launch cmd.exe from Start | CMD.EXE 20:18:19 (direct hit); CONHOST.EXE 20:18:19; OPENCONSOLE.EXE 20:18:19; WINDOWSTERMINAL.EXE 20:18:19 (Windows 11 hosts cmd inside Windows Terminal by default); BACKGROUNDTASKHOST, RUNTIMEBROKER noise | Security 4688 x6 (parent svchost.exe reflects the Windows Terminal activation chain), 4689 x1 | no match | CONFIRMED | Prefetch of cmd.exe, conhost.exe, and windowsterminal.exe converge on the same second; EVTX 4688 chain corroborates. This is the study's cleanest evidence that Windows 11 encapsulates traditional consoles inside Windows Terminal, changing the Prefetch fingerprint from the Win10 baseline (which would show cmd.exe plus conhost.exe only). |
| A02 | 20:18:49 | cmd: whoami | WHOAMI.EXE 20:18:51 (direct hit); COMPATTELRUNNER.EXE, SVCHOST.EXE, WMIPRVSE.EXE | Security 4688 x7, 4689 x7, 5379 x7 credential reads, 4798 x5 group enum, 4799 x3 privileged group enum (all consistent with whoami's identity-lookup syscalls) | no match | CONFIRMED | whoami.exe is a distinct binary that Prefetch records directly, and its EVTX signature (4798/4799 group enumeration) is exactly what a whoami invocation produces. Two artefact classes with fully specific attribution. |
| A03 | 20:19:26 | cmd: dir C:\Windows | MPCMDRUN.EXE x4 (Defender running in parallel), SECURITYHEALTHHOST, SVCHOST (all noise) | Security 4688 x12 parent Windows Defender platform, 4689 x10, SecurityCenter EID 15 x2 | no match | MISSED | `dir` is a cmd.exe built-in, not a separate binary, so Prefetch records nothing for the command itself. Defender activity in the window is coincident background noise. Attribution of `dir` invocations from the three project artefacts is not possible without command-line auditing (Security 4688 with `CommandLine` captured, which is disabled by default on this baseline). |
| A04 | 20:20:14 | Close cmd | POWERSHELL.EXE 20:20:17 (the A05 launch bleeding into this window because A04's end and A05's start are 23 s apart); RUNTIMEBROKER x2, SPPSVC, TIWORKER, TRUSTEDINSTALLER (noise) | Security 4688 x11, 4689 x11 exit burst, SecurityCenter EID 15 x2, SPP EID 16394 | no match | PARTIAL | Closing cmd produces a modest 4689 process-exit signature (cmd plus conhost plus terminal-child exits) but no distinctive marker. The powershell.exe Prefetch belongs to A05, not this action; a stricter window-filter would have excluded it. Single-class weak attribution. |
| A05 | 20:20:48 | Launch powershell | OPENCONSOLE.EXE 20:20:53, WINDOWSTERMINAL.EXE 20:20:53, BACKGROUNDTASKHOST, MOUSOCOREWORKER, UIEORCHESTRATOR (Windows Terminal launching a new tab hosts PowerShell) | Security 4688 x14 parent svchost.exe (Terminal activation chain), 4689 x12, 5379 x4 credential reads | no match | PARTIAL | powershell.exe itself is not in the Prefetch dump for this window (the powershell.exe Prefetch that appears at 20:20:17 was consumed by A04's window because that window ran to 20:20:27 and the Prefetch fired at 20:20:17). The Terminal/OpenConsole Prefetch confirms a console app launched but does not identify PowerShell specifically. Single-class attribution with residual ambiguity. |
| A06 | 20:21:44 | PS: Get-Process | no match | Security 4689 x7 (exit burst of child processes Get-Process spawned to enumerate) | no match | MISSED | Get-Process is a PowerShell cmdlet running inside powershell.exe; no new binary starts, so no Prefetch. The 4689 exits are consequence-of-enumeration, not directly attributing. Same script-inside-shell pattern as A03. |
| A07 | 20:22:49 | Close powershell | no match | Security 4689 x4 exit burst | no match | MISSED | powershell.exe exit is captured in the 4689 events but is generic; nothing else distinctive. |

## Coverage summary

- CONFIRMED: 2 of 7 (A01, A02)
- PARTIAL: 2 of 7 (A04, A05)
- MISSED: 3 of 7 (A03, A06, A07)
- Per-class hits: Prefetch 5 of 7 (2 attributing, 3 noise), EVTX 7 of 7 (mostly generic; distinctive attribution only for A02 whoami), ShellBags 0 of 7 (out of scope per matrix)

## Interpretive observations

1. Launching a console application creates a distinctive Prefetch cluster on Windows 11 (WINDOWSTERMINAL plus OPENCONSOLE plus the shell binary itself) that reliably attributes the action. This is a stronger fingerprint than pre-Terminal Windows 10 baselines would show.
2. Built-in shell commands (`dir` inside cmd, `Get-Process` inside PowerShell) are invisible to all three artefacts because they execute inside the shell's own process. Attribution of command-line activity at the invocation level requires Security 4688 with the `CommandLine` field enabled (audit subcategory "Detailed Tracking, Process Creation, Include command line") or PowerShell Module Logging plus Script Block Logging. The study's baseline does not enable these; noting this as a known limitation of the artefact-parser scope is honest.
3. whoami.exe (A02) is the study's cleanest single-command attribution: because it is a standalone binary, Prefetch captures it directly, and its Security-log fingerprint (4798/4799 group enumerations) is uniquely tied to the identity-lookup syscall pattern.
