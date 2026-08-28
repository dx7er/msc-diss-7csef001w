# Scenario 5 correlation table

Scenario: file deletion via Explorer plus Recycle Bin (appendix). Target file `C:\DISS_TESTDATA\scenario5_delete\scenario5_target.txt` (239 bytes, SHA-256 1C35C3...E89). Artefact classes in matrix: Prefetch, EVTX, ShellBags.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 08:28:55 | Open Explorer, navigate to C:\DISS_TESTDATA\scenario5_delete | RUNDLL32.EXE 08:29:01 (Explorer namespace expansion); SPPSVC.EXE 08:29:24 background | Security 4688 x4 (parent svchost.exe), 4689 x10, 4663 x3 object-access on FS resource, 4798 x2 group enum | UsrClass BagMRU at 08:29:01: ten rows including root namespace refresh plus `Desktop\This PC\C:\DISS_TESTDATA\scenario5_delete` (target folder) | CONFIRMED | ShellBag directly attributes the navigation to the target folder with per-folder LastInteracted timestamp; EVTX 4663 object-access events corroborate filesystem interaction. Two artefact classes concur. |
| A02 | 08:29:59 | Delete scenario5_target.txt to Recycle Bin | no match | Security 4689 x1, Service Control Manager 7040 (BITS start type change, unrelated) | no match | MISSED | The delete-to-Recycle-Bin action is a shell-level file move that emits no Prefetch (no new binary), no distinctive Security-auditing event (object-access auditing is off for user data by default on Win11 baseline), and no ShellBag entry (Recycle Bin is a virtual namespace, not a filesystem folder). Attribution would require an `$I` and `$R` scan of the C:\$Recycle.Bin filesystem, which is outside the artefact-parser scope. |
| A03 | 08:30:48 | Open Recycle Bin from Desktop | no match | no match | no match | MISSED | Opening the Recycle Bin from the desktop icon produces zero rows in any windowed artefact: it is a shell-namespace folder inside the running explorer.exe process. Same class of coverage gap as A02. |
| A05 | 08:32:13 | Empty Recycle Bin | MPCMDRUN.EXE x4 at 08:32:18 (Windows Defender command-line scanner); CONHOST.EXE x2, DLLHOST, SECURITYHEALTHHOST, TIWORKER, TRUSTEDINSTALLER (Defender plus servicing chain) | Security 4688 x17 with parent Windows Defender platform path, 4689 x11, SecurityCenter EID 15 x2 (Defender product state) | no match | PARTIAL | Emptying the Recycle Bin triggers Windows Defender to scan the deleted content, producing a distinctive burst of MPCMDRUN Prefetch entries and 4688 events with Defender parent. This is indirect but consistent attribution (Defender rarely fires this cluster spontaneously in the middle of a user session). Single artefact class (EVTX plus the Prefetch of Defender's helpers all rolls into one attribution chain) so PARTIAL is the honest score. |

## Coverage summary

- CONFIRMED: 1 of 4 (A01)
- PARTIAL: 1 of 4 (A05)
- MISSED: 2 of 4 (A02, A03)
- Per-class hits: Prefetch 2 of 4 (A01 incidental, A05 Defender residue), EVTX 3 of 4 (A03 nothing at all), ShellBags 1 of 4 (A01 only)

## Interpretive observations

1. The delete-to-Recycle-Bin action (A02) is a documented gap in three-artefact forensic coverage: the delete is a shell move to a hidden per-user directory (`C:\$Recycle.Bin\<SID>\`) with `$I` metadata files, none of which surface in Prefetch, EVTX, or ShellBags. This is a genuine research finding rather than a tool failure; the evaluation matrix should carry an explicit "requires 4th artefact class" note against Scenario 5.
2. Emptying the Recycle Bin (A05) leaves a Defender-scan signature rather than a direct action signature. This is a reproducible pattern (Defender is provoked by bulk file removal) and can be scored as circumstantial evidence, but a cautious analyst would flag it as inference, not direct attribution.
3. Scenario 5 is the study's clearest example of an action that a user would consider destructive-and-observable but that the three project artefacts fail to attribute directly. This deserves prominent discussion in the evaluation chapter as a limitation of the three-artefact triangulation model.
