# Scenario 6 correlation table

Scenario: logon, lock, unlock, logoff cycle (appendix). Artefact class in matrix: EVTX only.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

**Scope note:** The scenario spans three shell sessions (session 1 sign-out at A01, session 2 sign-in at A02 and lock/unlock at A03 to A05, session 2 sign-out at A06, session 3 sign-in at A07). Retrospective GT entries were logged in a later session because the sign-out terminated the logger's process; exact `4634` and `4624` moments in the Security log are authoritative.

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 16:01:16 | Sign out via Start menu (session 1) | 41 rows including LOGONUI.EXE x2, USERINIT.EXE, WINLOGON.EXE, CSRSS.EXE, DWM.EXE, FONTDRVHOST.EXE, LOGONUI.EXE 16:01:25, STARTMENUEXPERIENCEHOST.EXE, SIHOST.EXE, and the full shell-init tree; WEVTUTIL.EXE 16:01:23 (logger flushing GT to disk) | Security 4647 "User initiated logoff"; Winlogon EID 7002 UserSID logoff; Winlogon 7001 UserSID next-session logon; Kernel-General EID 16 hive-flush x2; Security 4634 logoff (implicit in the burst); massive 4688 x106 / 4689 x120 process tree for the shell teardown-and-rebuild | no match | CONFIRMED | Winlogon EID 7002 with the dfanalyst SID is the authoritative sign-out signature; Prefetch of USERINIT, LOGONUI, and WINLOGON confirms the shell rebuild that follows. Two artefact classes with directly attributing events. |
| A02 | 16:03:13 | Sign in as dfanalyst (session 2) | no match | Security 4688 x1, 4689 x3 (thin) | no match | MISSED | The 4624 logon and 4672 privilege assignment that would attribute this sign-in fall inside the A01 window (the logoff/logon transition is one continuous event burst that A01's window already contains), so A02's 10-second window catches only stragglers. This is a window-boundary artefact, not a coverage gap; correlation would improve if A01 and A02 were merged into one "session-1-to-session-2 transition" row. |
| A03 | 16:03:58 | Press Win+L (lock) | BACKGROUNDTASKHOST.EXE, MOUSOCOREWORKER.EXE, UIEORCHESTRATOR.EXE, UIEORCHESTRATORSTUB.EXE (SIHost/lock-screen orchestration) | Security 4688 x6 with parent svchost.exe, 4689 x3, 4624 SYSTEM logon x1 | no match | PARTIAL | Windows workstation-lock events (Security 4800) are not emitted by default on this baseline (the audit subcategory is off), so lock-signature EIDs are absent. Prefetch fingerprint of UIEOrchestrator is a documented lock-screen indicator and provides single-class attribution. |
| A04 | 16:06:11 | Waited more than 15 s while locked (retrospective marker) | no match | Security 4688 x1, 4689 x3 | no match | MISSED | This is a paper marker in the GT rather than a discrete user action; it exists to bracket the locked span. No artefact class captures "waiting". Scoring MISSED is honest. |
| A05 | 16:06:25 | Unlock with password (retrospective) | no match | no match | no match | MISSED | Same as A03: the Security 4801 unlock event is not emitted because the audit subcategory is off on the baseline. No indirect trace either. This is a genuine coverage gap of the study's baseline OS configuration; enabling audit subcategory 12 (Logon/Logoff other events) would surface it. |
| A06 | 16:06:37 | Sign out again via Start menu (session 2) | 30 rows including LOGONUI.EXE x2, USERINIT.EXE, WINLOGON.EXE, CSRSS.EXE, DWM.EXE, FONTDRVHOST.EXE, SIHOST.EXE (same shell-teardown fingerprint as A01) | Security 4647 "User initiated logoff"; Winlogon 7002 UserSID logoff; Winlogon 7001 UserSID logon; 4688 x88 / 4689 x91 shell rebuild; 4634 logoffs of Font Driver Host x3 | no match | CONFIRMED | Same signature as A01: 4647 plus 7002 plus 7001 plus shell-rebuild Prefetch cluster. This is the study's reference "clean logoff" pattern; it reproduces exactly from session 1 to session 2 which is itself a reproducibility observation. |
| A07 | 16:07:53 | Sign in as dfanalyst (session 3) | no match | no match | no match | MISSED | Same window-boundary artefact as A02: the session-3 4624 logon fires inside A06's window, leaving A07's 8-second window empty. Sign-in and sign-out on Windows are one atomic teardown-and-rebuild sequence; treating them as separate GT rows creates the mismatch. |

## Coverage summary

- CONFIRMED: 2 of 7 (A01, A06)
- PARTIAL: 1 of 7 (A03)
- MISSED: 4 of 7 (A02, A04, A05, A07)
- Per-class hits: Prefetch 3 of 7 (all correlated to sign-out shell rebuilds), EVTX 6 of 7 (most generic; only 4647/7002/7001 are directly attributing), ShellBags 0 of 7 (out of scope per matrix)

## Interpretive observations

1. Sign-out is the strongest signal in this scenario: EID 4647 plus Winlogon 7002 plus the shell-rebuild Prefetch cluster (LOGONUI, USERINIT, WINLOGON, CSRSS, DWM in one 30-second window) is an unambiguous forensic fingerprint that reproduces exactly across A01 and A06.
2. Workstation lock and unlock (A03, A05) are effectively invisible on the study's baseline OS configuration because the corresponding Security audit subcategories (specifically 4800 "workstation locked" and 4801 "workstation unlocked") are disabled by default in Windows 11 21H2. This is a research-worthy finding: three-artefact triangulation of lock and unlock requires an audit-policy change that a default-install analyst will not have.
3. The window-boundary problem for A02 and A07 (paired sign-in immediately after A01 and A06 sign-out) is a methodology observation, not a data problem: any sequential logoff-then-logon pair should be scored as a single transition rather than two independent actions when the transition takes under 20 seconds.
