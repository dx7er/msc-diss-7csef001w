# Correlating Windows Artifacts Evidence to Reconstruct User Activity

A Forensic Analysis of Prefetch, Event Logs and ShellBags on Windows 11.

**Module:** 7CSEF001W.2 &mdash; MSc Cyber Security and Forensics Project<br>
**Institution:** School of Computer Science and Engineering, University of Westminster<br>
**Author:** Syed Muhammad Saqlain Abbas (W21634541)<br>
**Supervisor:** Dr Jade James, Lecturer in Cyber Security and Digital Forensics<br>
**Ethics reference:** ETH2526-2077 (Class 1, approved 11 June 2026)<br>
**Submission:** 9 September 2026

---

## Abstract

This dissertation investigates the evidential value of three Windows 11 forensic artefacts (Prefetch, Windows Event Logs, and ShellBags) and develops a reproducible methodology for correlating them to reconstruct user activity. Single-artefact analyses dominate the literature; this project addresses the gap by treating correlation across artefact classes as the unit of forensic contribution.

## Aim

Investigate the evidential value of Prefetch, Windows Event Logs and ShellBags on Windows 11, and develop a methodology to correlate them to reconstruct user activity that can be validated against ground truth.

## Objectives

1. **O1** &mdash; Systematic literature review of Windows artefact forensics and event reconstruction frameworks.
2. **O2** &mdash; Construct a controlled Windows 11 testbed with documented baseline state and hashed snapshots.
3. **O3** &mdash; Design and execute a set of user-activity scenarios producing known ground truth.
4. **O4** &mdash; Extract artefacts using open-source tooling (PECmd, EvtxECmd, SBECmd).
5. **O5** &mdash; Correlate extracted artefacts into a unified timeline of reconstructed user activity.
6. **O6** &mdash; Evaluate correlation output against ground truth for completeness, accuracy and evidential sufficiency.
7. **O7** &mdash; Compare open-source methodology against a commercial baseline (Magnet AXIOM, optional).

## Methodology

Framing is forensic analysis, not software engineering. The candidate acts as the documented user on a controlled Windows 11 testbed, generating known-input activity that produces artefacts of known provenance.

Approach:

1. Snapshot a clean Windows 11 baseline before any scenario runs.
2. Execute scripted user-activity scenarios (S1&ndash;S5) with timestamps logged externally.
3. Snapshot post-scenario state; compute SHA-256 hashes for each artefact source.
4. Parse artefacts with open-source tools; export structured CSV/JSON output.
5. Correlate across artefact classes using a shared timeline schema.
6. Evaluate reconstruction fidelity against externally logged ground truth.

Evaluation draws on the TER-Model (Breitinger, Studiawan and Hargreaves, 2025) and the tamper-resistance factors of Vanini, Hargreaves and Breitinger (2024).

## Testbed

| Component | Specification |
|-----------|--------------|
| Hypervisor | VMware Workstation Pro 17 |
| Guest OS | Windows 11 Pro 25H2 |
| vCPU / RAM / Disk | 4 vCPU / 7 GB RAM / 80 GB dynamic |
| Account type | Local account (no MSA) |
| Timezone | UTC |
| Windows Update | Disabled after baseline |
| Network | Isolated (host-only) before baseline snapshot |
| Prefetch registry | `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters\EnablePrefetcher = 3` (verified) |
| Baseline snapshot | `BASELINE-PRE-SCENARIO-20260624` |

## Toolchain

| Tool | Version | Role |
|------|---------|------|
| PECmd (EricZimmermanTools) | latest | Prefetch parsing |
| EvtxECmd (EricZimmermanTools) | latest | Event Log parsing |
| SBECmd / ShellBags Explorer | latest | ShellBags parsing |
| Timeline Explorer | latest | Merged-timeline review |
| Python 3.12 + Pandas | 3.12.x | Correlation scripting |
| Jupyter | latest | Reproducible analysis notebooks |
| Microsoft Excel | 365 | Primary lightweight analysis |
| NIST CFReDS Hacking Case | current | Parser sanity check (optional) |
| Magnet AXIOM | Student licence | Commercial comparison (optional) |

## Repository structure

```
msc-diss-7csef001w/
|-- README.md
|-- LICENSE
|-- CITATION.cff
|-- .gitignore
|-- .gitattributes
|
|-- docs/
|   |-- proposal/                 # Approved proposal PDF, marking rubric
|   |-- ethics/                   # ETH2526-2077 approval screenshot, form
|   |-- meetings/                 # Supervisor meeting minutes
|   |-- final-report/             # Working draft, revisions, submitted PDF
|   `-- viva/                     # Defence slides and notes
|
|-- lit-review/
|   |-- matrix.xlsx               # Literature matrix (author, year, artefact, gap)
|   |-- notes/                    # Per-paper Notion-format summaries (Markdown)
|   `-- references.bib            # BibTeX (mirror of Word bibliography)
|
|-- testbed/
|   |-- build-notes.md            # Step-by-step build log
|   |-- baseline-manifest.csv     # File hashes and registry state at baseline
|   |-- snapshots.md              # Snapshot naming, timestamps, SHA-256
|   `-- vm-config.md              # VMX-relevant settings (no VMDK committed)
|
|-- scenarios/
|   |-- S1-file-access/
|   |   |-- script.md             # Human-readable steps
|   |   |-- ground-truth.csv      # Externally logged expected events
|   |   `-- run-log.md            # Actual execution log with wall-clock
|   |-- S2-usb-insertion/
|   |-- S3-application-launch/
|   |-- S4-folder-navigation/
|   `-- S5-file-deletion/
|
|-- artefacts/
|   |-- raw/                      # Copied Prefetch/EVTX/ShellBags (git-ignored if large)
|   |-- parsed/                   # PECmd/EvtxECmd/SBECmd CSV output
|   `-- hashes.csv                # SHA-256 of every raw and parsed file
|
|-- correlation/
|   |-- schema.md                 # Unified timeline column schema
|   |-- notebooks/                # Jupyter analysis notebooks
|   |-- scripts/                  # Python helpers (parse wrappers, mergers)
|   `-- output/                   # Correlated timelines per scenario
|
|-- evaluation/
|   |-- metrics.md                # Completeness / accuracy definitions
|   |-- ter-model-mapping.md      # Mapping to Breitinger 2025 TER-Model
|   |-- tamper-resistance.md      # Vanini 2024 seven-factor scoring
|   `-- results/                  # Per-scenario evaluation CSVs
|
|-- risk-register/
|   `-- risks.md                  # Live risk log with mitigations
|
`-- admin/
    |-- gantt.md                  # Phase timeline mirror of proposal
    `-- weekly-log.md             # Short weekly progress entries
```

## Reproducibility

Every artefact source is SHA-256 hashed on collection and again before parsing. Snapshot names encode ISO-8601 date. Ground truth for each scenario is logged externally in `scenarios/S*/ground-truth.csv` at the time of execution, independent of the artefacts being tested. Parser versions and command-line arguments are recorded in `correlation/scripts/` alongside the wrapper that produced each output.

## Timeline

| Phase | Weeks | Focus | Objectives |
|-------|-------|-------|-----------|
| 1 | W1&ndash;2 (28 May &ndash; 10 Jun) | Literature review, proposal, ethics | O1 |
| 2 | W3&ndash;4 (11 Jun &ndash; 24 Jun) | Testbed construction, baseline snapshot | O2 |
| 3 | W5&ndash;7 (25 Jun &ndash; 15 Jul) | Scenario design, data collection | O3 |
| 4 | W8&ndash;10 (16 Jul &ndash; 5 Aug) | Artefact extraction, correlation | O4, O5 |
| 5 | W11&ndash;13 (6 Aug &ndash; 26 Aug) | Validation, evaluation | O6, O7 |
| 6 | W14&ndash;15 (27 Aug &ndash; 9 Sep) | Write-up, submission | O7 |

## Ethics

Ethics reference **ETH2526-2077** was reviewed as Class 1 and signed off as not requiring approval on 11 June 2026. No human subjects, no personal data, no third-party systems are involved. All data originates from a controlled virtual machine operated solely by the candidate. Approval expires 9 September 2026, aligned with the submission deadline. Approval documentation is stored in `docs/ethics/`.

## Key references

Breitinger, F., Studiawan, H. and Hargreaves, C. (2025) 'A SoK on event reconstruction in digital forensics'.
Hargreaves, C. and Patterson, J. (2012) 'An automated timeline reconstruction approach for digital forensic investigations'.
Vanini, C., Hargreaves, C. and Breitinger, F. (2024) 'Tamper resistance of Windows event logs and other artefacts'.
Zhu, Y., Gladyshev, P. and James, J. (2009) 'Using ShellBag information to reconstruct user activities'.
Case, A., Cristina, A., Marziale, L., Richard, G.G. and Roussev, V. (2008) 'FACE: Automated digital evidence discovery and correlation'.

Full bibliography in `lit-review/references.bib` and in the final report.

## Licence and academic notice

Source code in this repository is released under the MIT License (see `LICENSE`). Written work (dissertation drafts, proposal, meeting notes, evaluation write-ups) is the intellectual property of the author and the University of Westminster and is not licensed for reuse. Reuse of any content for academic submission by another party would constitute plagiarism under the University's Academic Misconduct Regulations.

## Citation

If referencing this work before formal publication, cite as:

> Abbas, S.M.S. (2026) *Correlating Windows Artifacts Evidence to Reconstruct User Activity: A Forensic Analysis of Prefetch, Event Logs and ShellBags*. MSc dissertation, University of Westminster.

A machine-readable citation is provided in `CITATION.cff`.

## Contact

Author: dx73r@protonmail.com
Supervisor: j.james@westminster.ac.uk
