# MSc Dissertation

Practical companion to the MSc dissertation: *Correlating Windows Artifacts Evidence to Reconstruct User Activity: A Forensic Analysis of Prefetch, Event Logs and ShellBags*.<br>
**Module:** 7CSEF001W.2, MSc Cyber Security and Forensics Project<br>
**Institution:** School of Computer Science and Engineering, University of Westminster<br>
**Author:** Syed Muhammad Saqlain Abbas (W21634541)<br>
**Supervisor:** Dr Jade James, Lecturer in Cyber Security and Digital Forensics<br>
**Ethics reference:** ETH2526-2077 (Class 1, approved 11 June 2026)<br>
**Submission:** 9 September 2026

## Abstract

This dissertation investigates the evidential value of three Windows 11 forensic artefacts (Prefetch, Windows Event Logs, and ShellBags) and develops a reproducible methodology for correlating them to reconstruct user activity. Single artefact analyses dominate the literature; this project addresses the gap by treating correlation across artefact classes as the unit of forensic contribution.

## Aim

Investigate the evidential value of Prefetch, Windows Event Logs and ShellBags on Windows 11, and develop a methodology to correlate them to reconstruct user activity that can be validated against ground truth.

## Objectives

1. **O1**: Systematic literature review of Windows artefact forensics and event reconstruction frameworks.
2. **O2**: Construct a controlled Windows 11 testbed with documented baseline state and hashed snapshots.
3. **O3**: Design and execute a set of user activity scenarios producing known ground truth.
4. **O4**: Extract artefacts using open source tooling (PECmd, EvtxECmd, SBECmd).
5. **O5**: Correlate extracted artefacts into a unified timeline of reconstructed user activity.
6. **O6**: Evaluate correlation output against ground truth for completeness, accuracy and evidential sufficiency.
7. **O7**: Compare open source methodology against a commercial baseline (Magnet AXIOM, optional).

## Scope of this repository

This repository holds the practical and technical output of the dissertation only:
- Windows 11 testbed preparation, configuration and specifications
- Executable scenarios that generate ground truth user activity
- Parsed and window-filtered CSV outputs derived from the collected artefacts
- Analysis scripts that correlate artefacts across sources
- Per-scenario findings, correlation tables and reconstructed timelines

The written dissertation is a separate Word document submitted to the University of Westminster. The following are not in this repository, by design:
- Report chapters, discussion, conclusion
- Literature review and theoretical background
- Written methodology chapter (the prose version)
- Supervisor meeting minutes, viva slides, planning admin

The report cites this repository for reproducibility. This repository does not reproduce the report.

## Access, ownership, and publication

The raw forensic artefacts collected from the study's controlled Windows 11 testbed (Prefetch `.pf` binaries, `.evtx` event log files, registry hive binaries such as NTUSER.DAT, UsrClass.dat, SYSTEM, SOFTWARE, and Amcache.hve) are property of the University of Westminster and were produced under Ethics reference ETH2526-2077 (Class 1, approved 11 June 2026). These raw evidence files are retained on the author's local disk and in the VM snapshot library for the purposes of submission and viva examination only, and are excluded from this repository's public GitHub mirror via `.gitignore`. Every per-scenario `acquisition_manifest.csv` (SHA-256 chain-of-custody manifest) is committed so that the identity and integrity of the retained raw files can be independently verified during examination.

The parsed CSV outputs and window-filtered CSV subsets derived from those raw files are committed to the repository so that a reader can inspect the evidence a correlation claim is based on without needing to re-run the parsers.

Similarly, the final dissertation report (the written Word document submitted to the University of Westminster) is University property and is not published to this repository.

## Repository structure

```
msc-diss-7csef001w/
├── README.md                       (this file)
├── LICENSE.md
├── CITATION.cff
├── .gitignore                      (excludes raw forensic binaries)
├── vm_testbed.md                   (VM baseline documentation)
├── scenarios/
│   ├── catalogue.md                (list of all 10 scenarios and matrix)
│   ├── correlation_table_TEMPLATE.md
│   ├── testbed_evidence/           (baseline VM configuration outputs)
│   ├── scenario_1/                 (single run: no run_M/ subfolder)
│   │   ├── README.md               (what user did, what artefacts showed, verdict summary, key findings)
│   │   ├── artefacts/
│   │   │   ├── prefetch/           (raw .pf binaries; gitignored, local only)
│   │   │   ├── event_logs/         (raw .evtx binaries; gitignored)
│   │   │   ├── shellbags/          (raw NTUSER.DAT, UsrClass.dat; gitignored)
│   │   │   ├── supporting/         (raw SYSTEM, SOFTWARE, Amcache.hve; gitignored except acquisition_manifest.csv)
│   │   │   └── analysis/           (parsed CSVs, flat, committed)
│   │   │       └── windowed/       (per-action window-filtered CSVs, flat, committed)
│   │   └── evaluation/
│   │       ├── ground_truth.csv    (action log with UTC timestamps)
│   │       └── correlation_table.md (per-action verdict + analyst notes)
│   ├── scenario_2/                 (same layout)
│   ├── scenario_3/
│   ├── scenario_4/                 (multi run: 3 reps under run_M/)
│   │   ├── README.md               (scenario overview + 3-run reproducibility summary)
│   │   ├── evaluation/             (scenario-level notes and usb_identity.txt)
│   │   ├── run_1/                  (each run has its own artefacts/ + evaluation/)
│   │   │   ├── artefacts/{prefetch,event_logs,shellbags,supporting,analysis}/
│   │   │   └── evaluation/{ground_truth.csv, correlation_table.md}
│   │   ├── run_2/
│   │   └── run_3/
│   ├── scenario_5/
│   ├── scenario_6/
│   ├── scenario_7/                 (multi run, same layout as scenario_4)
│   ├── scenario_8/
│   ├── scenario_9/
│   └── scenario_10/
└── scripts/
    ├── testbed/                    (VM baseline setup, 01_ to 12_)
    ├── scenarios/                  (log_action.ps1, acquire_artefacts.ps1, per-scenario prep scripts)
    ├── analysis/                   (window_filter.ps1, correlate_scenario.py, extract_artefacts.ps1)
    └── evaluation/                 (evaluation_matrix.csv, evaluation_matrix.md)
```

## Methodology

Framing is forensic analysis, not software engineering. The candidate acts as the documented user on a controlled Windows 11 testbed, generating known input activity that produces artefacts of known provenance.

Approach:

1. Snapshot a clean Windows 11 baseline before any scenario runs.
2. Execute scripted user activity scenarios (Scenario 1 to Scenario 10) with timestamps logged externally via `log_action.ps1`.
3. Snapshot post-scenario state; compute SHA-256 hashes for each artefact source.
4. Acquire raw artefacts offline from the post-scenario snapshot via `acquire_artefacts.ps1`.
5. Parse artefacts with open source tools (PECmd, EvtxECmd, SBECmd); export structured CSV output into each scenario's `artefacts/analysis/` folder.
6. Filter parsed CSVs to per-action time windows using `window_filter.ps1`; outputs land in `artefacts/analysis/windowed/`.
7. Correlate windowed artefacts against ground truth per action; verdict scored CONFIRMED, PARTIAL or MISSED in `evaluation/correlation_table.md` with an analyst-notes column for critical evaluation.
8. Aggregate per-scenario findings into a cross-scenario evaluation matrix in `scripts/evaluation/evaluation_matrix.md` (with CSV mirror at `evaluation_matrix.csv`).

Evaluation draws on the TER Model (Breitinger, Studiawan and Hargreaves, 2025) and the tamper resistance factors of Vanini, Hargreaves and Breitinger (2024).

## Testbed specification

| Component | Specification |
|-----------|--------------|
| Hypervisor | VMware Workstation Pro 17 |
| Guest OS | Windows 11 Pro 25H2 |
| vCPU / RAM / Disk | 4 vCPU / 7 GB RAM / 80 GB dynamic |
| Account type | Local account (no Microsoft Account) |
| Timezone | UTC |
| Windows Update | Disabled after baseline |
| Network | NAT (approved by Jade 2026-08-06) |
| Prefetch registry | `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters\EnablePrefetcher = 3` (verified) |
| Baseline snapshot | `baseline_candidate` (Windows 26200.6584, taken 2026-07-17) |

Full setup in `vm_testbed.md`.

## Toolchain

| Tool | Role |
|------|------|
| PECmd (EricZimmermanTools) | Prefetch parsing |
| EvtxECmd (EricZimmermanTools) | Windows Event Log parsing |
| SBECmd (EricZimmermanTools) | ShellBags parsing |
| Timeline Explorer | Merged timeline review |
| Python 3.10+ | Correlation script (`scripts/analysis/correlate_scenario.py`) |
| PowerShell 5+ | Acquisition, logging, window-filtering scripts |
| Arsenal Image Mounter | Read-only VMDK mount for offline acquisition |
| Magnet AXIOM (student licence) | Commercial baseline comparison (optional) |

Parser versions and CLI flags used for each artefact class are recorded per run alongside the parsed outputs.

## Reproducibility and integrity

- Every artefact source is SHA-256 hashed on collection.
- Snapshot names encode the scenario and run identifier; snapshot list lives in `vm_testbed.md`.
- Ground truth for each scenario is logged externally at the moment of execution, independent of the artefacts being tested.
- Per-run acquisition manifests live at `scenarios/scenario_N/artefacts/supporting/acquisition_manifest.csv` (single run) or `scenarios/scenario_N/run_M/artefacts/supporting/acquisition_manifest.csv` (multi run). These are committed to the repository even though the raw binaries they hash are not.
- Baseline VM configuration state is captured in `scenarios/testbed_evidence/` and summarised in `vm_testbed.md`.

## How to reproduce

Complete step by step reproduction instructions live in `REPRODUCIBILITY.md` at the repository root. That file covers host prerequisites, VM baseline build, the six phase per scenario workflow, the exact commands used for acquisition, parsing and window filtering, per scenario reproduction steps for all ten scenarios, and troubleshooting notes. Read it before attempting any reproduction of the study.

## Ethics

Ethics reference **ETH2526-2077** (Class 1) was signed off as not requiring approval on 11 June 2026 and expires 9 September 2026. No human subjects, no personal data, no third party systems. All data originates from a controlled virtual machine operated solely by the author.

## Key references

Breitinger, F., Studiawan, H. and Hargreaves, C. (2025) 'A SoK on event reconstruction in digital forensics'.
Hargreaves, C. and Patterson, J. (2012) 'An automated timeline reconstruction approach for digital forensic investigations'.
Vanini, C., Hargreaves, C. and Breitinger, F. (2024) 'Tamper resistance of Windows event logs and other artefacts'.
Zhu, Y., Gladyshev, P. and James, J. (2009) 'Using ShellBag information to reconstruct user activities'.
Case, A., Cristina, A., Marziale, L., Richard, G.G. and Roussev, V. (2008) 'FACE: Automated digital evidence discovery and correlation'.

## Licence

Source code and scripts in this repository are released under the MIT Licence (see `LICENSE.md`).
Text content (setup notes, scenario steps, findings writeups) is released under CC BY 4.0.
The dissertation report itself is not in this repository and is not covered by these licences; it is the intellectual property of the author and the University of Westminster.

## Citation

If referencing this work before formal publication:

> Abbas, S.M.S. (2026) *Correlating Windows Artifacts Evidence to Reconstruct User Activity: A Forensic Analysis of Prefetch, Event Logs and ShellBags*. MSc dissertation, University of Westminster.

Machine readable citation in `CITATION.cff`.

## Contact

Author: w2163454@westminster.ac.uk<br>
Supervisor: j.james@westminster.ac.uk
