# P00 - Excluded Pilot Scenario

P00 validates the complete experimental chain before `B00-CANDIDATE` is promoted to `B00-FORMAL`. Run it twice as `P00-R01` and `P00-R02`, restoring the identical candidate snapshot before each run. Pilot evidence is excluded from the dissertation's formal findings.

## Promotion questions

The two runs must establish that:

1. Prefetch is generated and PECmd can parse it.
2. Security process-creation and lock/unlock events are present.
3. Browsed folders appear in ShellBags while the unbrowsed negative control does not.
4. USB evidence is captured because USB activity is part of S04 and S07.
5. Targeted offline acquisition preserves evidence and hashes.
6. Host and guest clocks remain within the declared tolerance.

## Preconditions

- VM is not running and VMware Workstation is closed.
- An off-VM copy of `B00-CANDIDATE-W11-25H2-26200.6584-20260717` and its SHA-256 manifest exist.
- `PECmd`, `EvtxECmd`, and `SBECmd` are installed only on the host and recorded in `testbed/evidence/Host-Parser-Manifest.csv`.
- The network policy to be used for formal offline scenarios is applied consistently. Do not promote a NAT-connected pilot baseline and later change it to host-only/disconnected.
- A controlled USB device containing only synthetic test data is available.
- The positive-control path exists:
  `C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9\ALPHA\BRAVO\CHARLIE`
- The negative-control path exists but has never been opened in Explorer:
  `C:\DISS_TESTDATA\PILOT\P00R01_UNBROWSED_Q4M2`

## Run procedure

1. On the host, start the external logger before restoring or booting the VM:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\14c-log-ground-truth-HOST.ps1 -RunId P00-R01
   ```

2. Follow the logger prompts. Inside the guest, run the pre-capture when prompted:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\14a-pilot-pre-run.ps1 -RunId P00-R01
   ```

3. Browse only the positive-control folder tree. Wait 15 to 30 seconds at each level. Never open the `Q4M2` negative-control path.
4. Launch and close Notepad twice.
5. With the VMware guest focused, lock it using Win+L, wait 30 seconds, and unlock it.
6. Attach the controlled USB, browse its root and test folder, copy one synthetic file to local Documents, then safely eject it.
7. Wait 60 to 120 seconds after closing Explorer.
8. Run the guest post-capture when prompted:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\14b-pilot-post-run.ps1 -RunId P00-R01
   ```

9. Shut the guest down normally. Do not boot it again for this run.
10. Preserve and hash the complete post-run VM folder before any revert.
11. Acquire the targeted artefacts from the preserved copy and run the host parser/verifier.
12. Record the run in `testbed/pilot-log.md` and complete every item in `testbed/scripts/15-promotion-checklist.md`.
13. Restore the unchanged candidate and repeat all steps as `P00-R02`.

## Evidence retained per repetition

- Host ground-truth CSV
- Guest pre-run and post-run capture text files
- Full post-run VM SHA-256 manifest
- Targeted acquisition manifest
- Parser console log and parsed CSV outputs
- Completed promotion checklist
- Deviations and failed criteria, including negative findings

Raw `.pf`, `.evtx`, and Registry hive files remain outside Git. Their hashes and shareable parsed outputs are retained in the repository.
