# Supplementary documentation

Material that supports the study but is not part of the code or artefact tree.

## Files

- `practical_execution_log.pdf` (158 pages, 7 MB) — full Notion export of the practical working log kept during scenario execution. Contains verbatim PowerShell transcripts, terminal screenshots, and per-scenario sanity-check output for the parsing and correlation steps. This is the primary execution evidence for the report methodology chapter.

  Coverage by scenario in the log:
  - Pre-scenario baseline capture and `Log-Action` helper definition (pages 1 to 2).
  - Scenario 1 execution transcript (pages 2 to 5) and parsing plus sanity checks (pages 133 to 139).
  - Scenario 4 run 1, 2, 3 parsing plus sanity checks (pages 140 to 154).
  - Scenario 7 run 1, 2, 3 parsing (pages 155 to 158).
  - Additional scenarios' execution notes interleaved (pages 5 to 129).

  The log is a working notebook and reads chronologically rather than by scenario section; use the page ranges above to locate specific runs.

## Relationship to the rest of the repo

The scripts in `scripts/` are the productionised version of what this log shows being run interactively. The CSVs under `scenarios/scenario_N/artefacts/analysis/` are the outputs the log's sanity-check commands read from. The correlation tables under `scenarios/scenario_N/evaluation/` are written from the evidence dumps this log records. In short:

- Log = what happened live at the keyboard.
- Repo = the reproducible study built from what happened.

Anything the report cites as "we ran X and observed Y" should be traceable to a page in this log; anything the report cites as a script or output should be traceable to a file in the repo.
