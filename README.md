# MSc Dissertation 

 Practical companion to the MSc dissertation: *Correlating Windows Artifacts Evidence to Reconstruct User Activity: A Forensic Analysis of Prefetch, Event Logs and ShellBags*.<br>
**Module:** 7CSEF001W.2 &mdash; MSc Cyber Security and Forensics Project<br>
**Institution:** School of Computer Science and Engineering, University of Westminster<br>
**Author:** Syed Muhammad Saqlain Abbas (W21634541)<br>
**Supervisor:** Dr Jade James, Lecturer in Cyber Security and Digital Forensics<br>
**Ethics reference:** ETH2526-2077 (Class 1, approved 11 June 2026)<br>
**Submission:** 9 September 2026

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


## Scope of this repository

This repository holds the **practical and technical output** of the dissertation only:
- Windows 11 testbed preparation, configuration and specifications
- Executable scenarios that generate ground-truth user activity
- Collected forensic artefacts (raw where sharable; parsed CSV/JSON)
- Analysis scripts and notebooks that correlate artefacts across sources
- Findings tables and reconstructed timelines

The **written dissertation** is a separate Word document submitted to the University of Westminster. The following are **not** in this repository, by design:
- Report chapters, discussion, conclusion
- Literature review and theoretical background
- Written methodology chapter (the prose version)
- Supervisor meeting minutes, viva slides, planning admin

The report cites this repository for reproducibility. This repository does not reproduce the report.


## Repository structure
```
msc-diss-7csef001w/
├── README.md
├── LICENSE.md
├── CITATION.cff
├── .gitignore
├── artefacts/
│   ├── prefetch/findings.md
│   ├── event-logs/findings.md
│   └── shellbags/findings.md
└── testbed/
    ├── testbed-checklist.md
    ├── vm-specification.md
    ├── snapshots.md
    ├── evidence/            (config artefacts)
    └── scripts/             (build/pilot scripts)
```

## Methodology

Framing is forensic analysis, not software engineering. The candidate acts as the documented user on a controlled Windows 11 testbed, generating known-input activity that produces artefacts of known provenance.
<br>Approach:
1. Snapshot a clean Windows 11 baseline before any scenario runs.
2. Execute scripted user-activity scenarios (S1&ndash;S5) with timestamps logged externally.
3. Snapshot post-scenario state; compute SHA-256 hashes for each artefact source.
4. Parse artefacts with open-source tools; export structured CSV/JSON output.
5. Correlate across artefact classes using a shared timeline schema.
6. Evaluate reconstruction fidelity against externally logged ground truth.
Evaluation draws on the TER-Model (Breitinger, Studiawan and Hargreaves, 2025) and the tamper-resistance factors of Vanini, Hargreaves and Breitinger (2024).


## Testbed specification

| Component | Specification |
|-----------|--------------|
| Hypervisor | VMware Workstation Pro 17 |
| Guest OS | Windows 11 Pro 25H2 |
| vCPU / RAM / Disk | 4 vCPU / 7 GB RAM / 80 GB dynamic |
| Account type | Local account (no Microsoft Account) |
| Timezone | UTC |
| Windows Update | Disabled after baseline |
| Network | Host-only, isolated, before baseline snapshot |
| Prefetch registry | `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters\EnablePrefetcher = 3` (verified) |
| Baseline snapshot | `BASELINE-PRE-SCENARIO-20260624` |

Full setup steps in `testbed/testbed-checklist.md`.

## Toolchain

| Tool | Role |
|------|------|
| PECmd (EricZimmermanTools) | Prefetch parsing |
| EvtxECmd (EricZimmermanTools) | Windows Event Log parsing |
| SBECmd / ShellBags Explorer | ShellBags parsing |
| Timeline Explorer | Merged-timeline review |
| Python 3.12 with Pandas | Correlation scripts |
| Jupyter | Analysis notebooks |
| Magnet AXIOM (student licence) | Commercial baseline comparison (optional) |

Command-line arguments and versions used for each parser are recorded alongside the corresponding `findings.md` in `artefacts/`.

## Reproducibility and integrity

- Every artefact source is SHA-256 hashed on collection and again before parsing.
- Snapshot names encode ISO-8601 date; snapshot log lives in `testbed/snapshots.md`.
- Ground truth for each scenario is logged **externally** at the moment of execution, independent of the artefacts being tested.
- Parser versions and CLI flags used for each artefact class are recorded alongside `findings.md` in `artefacts/prefetch/`, `artefacts/event-logs/` and `artefacts/shellbags/`.
- Baseline VM configuration state is captured in `testbed/evidence/` and summarised in `testbed/vm-specification.md`.

## How to reproduce

1. Build the VM per `testbed/testbed-checklist.md`.
2. Take the baseline snapshot; record it in `testbed/snapshots.md`.
3. Execute a scenario against the baseline snapshot; log wall-clock UTC alongside the scenario ground truth.
4. Take post-scenario snapshot; extract artefacts offline from the guest disk.
5. Parse with PECmd, EvtxECmd and SBECmd; output lands in `artefacts/prefetch/`, `artefacts/event-logs/` and `artefacts/shellbags/`.
6. Compare parsed output against ground truth; record findings in each `findings.md`.

## Ethics

Ethics reference **ETH2526-2077** (Class 1) was signed off as not requiring approval on 11 June 2026 and expires 9 September 2026. No human subjects, no personal data, no third-party systems. All data originates from a controlled virtual machine operated solely by the author.


## Key references
 
Breitinger, F., Studiawan, H. and Hargreaves, C. (2025) 'A SoK on event reconstruction in digital forensics'.
Hargreaves, C. and Patterson, J. (2012) 'An automated timeline reconstruction approach for digital forensic investigations'.
Vanini, C., Hargreaves, C. and Breitinger, F. (2024) 'Tamper resistance of Windows event logs and other artefacts'.
Zhu, Y., Gladyshev, P. and James, J. (2009) 'Using ShellBag information to reconstruct user activities'.
Case, A., Cristina, A., Marziale, L., Richard, G.G. and Roussev, V. (2008) 'FACE: Automated digital evidence discovery and correlation'.
 


## Licence

Source code and scripts in this repository are released under the MIT Licence (see `LICENSE.md`).
Text content (setup notes, scenario steps, findings write-ups) is released under CC BY 4.0.
The dissertation report itself is not in this repository and is not covered by these licences; it is the intellectual property of the author and the University of Westminster.

## Citation

If referencing this work before formal publication:

> Abbas, S.M.S. (2026) *Correlating Windows Artifacts Evidence to Reconstruct User Activity: A Forensic Analysis of Prefetch, Event Logs and ShellBags*. MSc dissertation, University of Westminster.

Machine-readable citation in `CITATION.cff`.

## Contact

Author: w2163454@westminster.ac.uk<br>
Supervisor: j.james@westminster.ac.uk
