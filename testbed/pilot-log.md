# Pilot Log

Chronological log of pilot runs executed against the candidate baseline (Step 14 of `testbed-checklist.md`). Two successful pilots (P00-R01 and P00-R02) are the promotion gate for `B00-CANDIDATE` -> `B00-FORMAL` (Step 15).

Pilot data is excluded from final findings; the purpose is to prove the baseline configuration is fit for formal collection.

## Status

| Item | State |
|------|-------|
| Baseline candidate | `B00-CANDIDATE-W11-25H2-26200.6584-20260717` created 2026-07-17T19:30:58Z |
| Steps 1-13 (build, isolation, offline-acquisition validation) | Complete |
| Step 14 pilots (P00-R01, P00-R02) | Not yet executed |
| Step 15 promotion | Blocked on pilots |

## Open items before pilot execution

- Network isolation decision. VM is currently NAT-connected; testbed-checklist Step 10 calls for Host-only + Connected/Connect-at-power-on unchecked. Pending supervisor confirmation that Host-only is acceptable for scenarios that need no host communication.
- Off-VM backup of the candidate. Deferred per `snapshots.md`; must be taken before P00-R01 so a corrupted VMDK does not cost the baseline.
- Formal scenario definitions (S1-S5). Pilot mirrors the intended scenario workflow; scenario scripts should exist in outline form before P00-R01 so the pilot exercises the real Explorer/Notepad/lock/USB sequence.
- Ground-truth CSV. Template lives at `scripts/14c-ground-truth-template.csv`. Confirm columns match `parse-and-verify` expectations in `14d-parse-and-verify-HOST.ps1` before the pilot run.

## Runs

| Run ID | Baseline | Start (UTC) | End (UTC) | Ground-truth CSV | Acquisition manifest | Promotion criteria met | Notes |
|--------|----------|-------------|-----------|------------------|----------------------|------------------------|-------|
| (none yet) | | | | | | | |

## Failed pilots

Recorded here with the failed promotion criterion and the correction applied. A failed pilot never modifies the current candidate in place; a new `BNN-CANDIDATE` is created per Step 15.

| Failed run | Failed criterion | Root cause | Correction | New candidate produced |
|------------|------------------|------------|------------|------------------------|
| (none yet) | | | | |
