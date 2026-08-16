# Snapshot Log

Every powered-off snapshot and its off-VM backup recorded here. Snapshot names encode role, guest, build and UTC date.

## Naming convention

```
<ROLE>-W11-25H2-<CurrentBuild.UBR>-<YYYYMMDD>
```

Roles:

- `B00-CANDIDATE`: baseline candidate produced in Step 11; treated as the working baseline for this study (see baseline decision below).
- `S00-UNIVERSAL-PRE`: universal pre-scenario snapshot taken off `B00-CANDIDATE`; single revert point used at the start of every scenario run in place of per-run PRE snapshots.
- `S{NN}-R{NN}-POST`: post-scenario state before evidence acquisition (one per scenario per repetition).

**Baseline decision (2026-08-12):** Testbed Steps 13-15 (offline-acquisition validation, pilots, formal promotion) were skipped by explicit user decision. `B00-CANDIDATE` is treated as the working baseline; no `B00-FORMAL` promotion is being performed. `S00-UNIVERSAL-PRE` is the revert point used by all scenario runs to keep the original `B00-CANDIDATE` untouched. NAT (rather than host-only) is approved by Jade (meeting 2026-08-06).

## Log

| Snapshot name | Type | Created (UTC) | Backup manifest | Notes |
|---------------|------|---------------|-----------------|-------|
| B00-CANDIDATE-W11-25H2-26200.6584-20260717 | Baseline candidate (treated as working baseline) | 2026-07-17T19:30:58Z (host local: 20:30:58 BST) | Deferred | Windows 26200.6584, VMware Tools 12.4.5, 4 vCPU / 7 GB RAM / 80 GB, UTC, audit on, WU disabled, NAT connected, BitLocker off. NAT approved by Jade 2026-08-06 (supersedes original host-only plan). |
| S00-UNIVERSAL-PRE | Universal pre-scenario restore point | 2026-08-12T09:26:54Z (host local: 10:26:54 BST) | Not backed up (state = B00-CANDIDATE) | Child of B00-CANDIDATE; single revert point used before every scenario run. |

## Off-VM backups

Location: `D:\UOW\SEM3\Backups\<snapshot-name>\`
Manifest: `<snapshot-name>-SHA256.csv` alongside.

| Backup | Snapshot mirrored | Manifest SHA-256 lines | Total size | Verified |
|--------|-------------------|------------------------|------------|----------|
| (none yet) | | | | Deferred: candidate not yet promoted. Independent backup planned post-promotion. |
