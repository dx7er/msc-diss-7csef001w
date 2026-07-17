# Step 15 - Baseline promotion checklist

Complete this checklist against P00-R01 AND P00-R02 outputs before promoting
`B00-CANDIDATE` to `B00-FORMAL`. If ANY box is unchecked, do not promote.
Create `B01-CANDIDATE` after fixing the issue and re-run both pilots.

## Promotion criteria

Both pilots must satisfy every item.

- [ ] Prefetch was generated during the pilot. `PECmd` output shows at least
      one new/updated `.pf` file with `LastWriteTimeUtc >= T0`.
- [ ] `PECmd` parsed the Prefetch files without error.
- [ ] Security event 4688 recorded for Notepad. Look in `<RunId>-Security.csv`
      for `EventId=4688` with `NewProcessName` matching `notepad.exe`.
- [ ] Security event 4688 payload contains the command line (proves the
      registry policy from Step 6 is active).
- [ ] Security events 4800 (lock) and 4801 (unlock) both recorded.
- [ ] ShellBag output includes the BROWSED path token `A7K9`.
- [ ] ShellBag output does NOT include the UNBROWSED path token `Q4M2`.
- [ ] USB events captured, if USB was in scope. `DriverFrameworks-UserMode/Operational`
      or `Microsoft-Windows-Kernel-PnP/Configuration` shows insertion.
- [ ] Event logs did NOT roll over during the pilot. `wevtutil gl Security`
      output shows a size still within the configured maximum.
- [ ] Offline acquisition succeeded (`13-validate-offline-acquisition-HOST.ps1`
      exit code 0, expected artefacts extracted).
- [ ] All raw evidence hashes in acquisition manifest match. Re-run the
      SHA-256 on the extracted files; compare to `acquisition-manifest.csv`.
- [ ] No forensic analysis tool ran inside the evidence VM at any point.
- [ ] Host and guest clock offsets before and after the pilot are within
      declared tolerance (default: less than 2 seconds).

## Promotion procedure

Once every box is ticked for BOTH P00-R01 and P00-R02:

1. In VMware Workstation, VM > Snapshot > Snapshot Manager.
2. Right-click the `B00-CANDIDATE-W11-25H2-26200.6584-20260717` snapshot.
3. Rename to:

   ```
   B00-FORMAL-W11-25H2-26200.6584-20260717
   ```

4. Update `testbed/snapshots.md` in the repo:
   - Append promotion row: `B00-FORMAL-W11-25H2-26200.6584-20260717`, type
     `Formal baseline`, created UTC, description (mirror the candidate
     description plus "promoted after P00-R01 and P00-R02 passed").
   - Link the backup manifest path.
5. Update the top of `testbed/setup-checklist.md`:

   ```
   Formal baseline: B00-FORMAL-W11-25H2-26200.6584-20260717
   Promoted: <UTC>
   Pilots passed: P00-R01, P00-R02
   ```

6. From this point onward:
   - No testbed changes (settings, registry, audit policy, event log size).
   - No tool changes (PECmd, EvtxECmd, SBECmd, Timeline Explorer versions
     are frozen at the versions recorded in Step 4).
   - No application updates on the guest.
   - Any change invalidates every artefact collected after it.

## If promotion fails

Do not modify the current candidate in place. Instead:

1. Note the failed criterion in `testbed/snapshots.md` under a "Failed
   candidates" section.
2. Boot the candidate one more time via a snapshot revert.
3. Apply the correction.
4. Shut down cleanly.
5. Take a new snapshot named `B01-CANDIDATE-W11-25H2-<build>-<UTC>`.
6. Discard the failed candidate snapshot only after `B01-CANDIDATE` passes
   its own pilots.
