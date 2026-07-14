# Snapshot Log

Every powered-off snapshot and its off-VM backup recorded here. Snapshot names encode role, guest, build and UTC date.

## Naming convention

```
<ROLE>-W11-25H2-<CurrentBuild.UBR>-<YYYYMMDD>
```

Roles:

- `B00-CANDIDATE` - baseline candidate produced in Step 11; not yet proven by pilots
- `B00-FORMAL` - baseline promoted in Step 15 after both pilots pass
- `B01-CANDIDATE`, `B02-CANDIDATE`, ... - subsequent candidates if the first fails pilots
- `S{NN}-R{NN}-PRE` - pre-scenario restore point (identical to baseline; created at experiment start)
- `S{NN}-R{NN}-POST` - post-scenario state before evidence acquisition

## Log

| Snapshot name | Type | Created (UTC) | Backup manifest | Notes |
|---------------|------|---------------|-----------------|-------|
| (none yet) | | | | Baseline not yet taken |

## Off-VM backups

Location: `D:\UOW\SEM3\Backups\<snapshot-name>\`
Manifest: `<snapshot-name>-SHA256.csv` alongside.

| Backup | Snapshot mirrored | Manifest SHA-256 lines | Total size | Verified |
|--------|-------------------|------------------------|------------|----------|
| (none yet) | | | | |
