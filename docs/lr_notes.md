# Literature review source notes

Per-paper structured notes on the 23-paper LR corpus at `D:\UOW\SEM3\Research Papers\`. Written after reading every PDF end-to-end on 2026-08-28. Format per paper: bibliographic anchor, venue, core claim, method, key findings, what this dissertation borrows or challenges, notable quotes with page numbers. Purpose: to serve Ch 2 (Literature Review) and Ch 5 (Discussion) drafting, and to be cite-ready for the final report.

Papers are ordered alphabetically by file name.

---

## 1. Amoruso, Cinque, Danese and Losavio 2022, SeeShells

Venue: 2022 IEEE International Workshop on Metrology for Extended Reality, AI and Neural Engineering (MetroXRAINE). 6 pages.

Core claim. Windows ShellBags investigation is under-served by existing tooling: prior parsers dump raw records but leave the analyst to reconstruct navigation flows manually. SeeShells contributes an interactive visualisation layer that turns the raw registry records into a browsable timeline plus tree of user folder-navigation activity.

Method. Tool design plus qualitative evaluation across Windows versions. Qt-based visual front end on top of a bespoke ShellBag parser.

Key findings.
- ShellBags are the artefact of choice for showing which folders a user has interacted with. Windows Explorer writes to `NTUSER.dat\...\Shell\BagMRU` (Desktop, network folders, remote machines) and `UsrClass.dat\...\Shell\BagMRU` (local folders, ZIP files, virtual folders, removable devices) whenever a folder is opened, right-clicked, cut, copied, renamed or deleted.
- The BagMRU structure encodes hierarchy: each node's child key numbers the child folders in the order they were first observed; `MRUListEx` records the most recently interacted subset.
- Naive parsing loses the temporal ordering across sibling folders because ShellBags do not record a per-visit timestamp beyond the `LastWriteTime` of the containing registry key.
- Timeline plus tree visualisation is more useful to the investigator than a flat CSV.

Borrow. Two things. First, the artefact characterisation (what ShellBags record, when they are created, where they live) is a solid one-paper reference for the methodology chapter's ShellBags subsection. Second, the tree-plus-timeline visualisation idea directly influenced how S03 nested-navigation and S07 Save-As results are laid out in the correlation tables.

Challenge. Amoruso frames ShellBags as adequate for folder-navigation reconstruction when parsed and visualised properly. S05 (delete to Recycle Bin) and S06 (workstation lock) in this study show ShellBags do not fire at all for those actions, so the "adequate" framing is scope-dependent, not universal.

Quotes.
- "ShellBag information is crucial when forensicators need to know when and which folders a user accessed" (Intro).
- "The ShellBag information comprises two main registry keys, BagMRU and Bags" (Section II).

---

## 2. Breitinger, Studiawan and Hargreaves 2025, SoK: Timeline-based event reconstruction for digital forensics

Venue: arXiv 2504.18131. Systematisation of Knowledge (SoK). 15 pages.

Core claim. The subfield of timeline-based event reconstruction for digital forensics has proliferated without consistent terminology, without standard evaluation benchmarks, and without agreed measures of quality. The paper systematises the vocabulary (event, trace, artifact, environment, timeline entry, inferred event) and identifies five recurring challenges: terminology inconsistency, evaluation-benchmark absence, cross-domain alignment weakness, provenance and admissibility gaps, and practitioner-tool gaps. It proposes the four-quadrant TER-Model (Q1 traces, Q2 timeline generation, Q3 timeline analysis, Q4 decision-making) and enumerates seven open research gaps.

Method. SoK. Papers surveyed from Google Scholar; clustered by method (rule-based, database-driven, semantic-model, tree/graph-based, timestamp-based, finite-state-machine, virtual-machine, live). Each cluster is evaluated against the five challenges and mapped to the TER-Model.

Key findings.
- Existing timeline-reconstruction papers use "event", "action", "artefact" and "trace" inconsistently: a paper's "event" may be another's "action". The SoK proposes a fixed hierarchy (raw trace → parsed event → reconstructed action) that this dissertation adopts.
- The field has no standard benchmark dataset; most papers use bespoke labs, which prevents cross-study comparison.
- Timestamp-based reconstruction is the most common method but the weakest to tampering; Vanini et al. 2024 is cited as the current state of the art defence.
- Cross-domain alignment (correlating OS logs with browser logs, with cloud logs, with physical evidence) is the least mature area.
- Seven open research gaps are enumerated. Gaps 3 (artefact persistence and absence interpretation), 4 (timeline generation advances including tamper detection) and 5 (efficient timeline analysis through data reduction) are the ones this dissertation directly addresses.
- The paper is theoretical, not empirical (no experiments, no dataset, no validation). Cite for framing and terminology, not for evidence.

Borrow. The single most important paper in the corpus for this dissertation. Supplies (a) terminology for Ch 2 (event, trace, action, reconstruction), (b) the five-challenge taxonomy that structures the LR chapter, (c) the argument for why a ground-truth-logged evaluation matrix (as this dissertation delivers) is a contribution, (d) citation-level authority for the correlation-lift and reproducibility metrics computed in the evaluation matrix, (e) the four-quadrant TER-Model as the contemporary framework for positioning the dissertation, and (f) Research Gaps 3, 4, 5 as direct justification anchors for SMART objectives O3, O5, O6.

Challenge. The SoK identifies but does not close the terminology gap. This dissertation contributes an operational demonstration of one point on the correlation-lift axis (37.1% across 56 GT items on Win11 25H2) that the SoK's "we need benchmarks" argument would consume as evidence.

Quotes.
- "Breitinger, Studiawan and Hargreaves (2025) provide the field's most recent Systematization of Knowledge for timeline-based event reconstruction, introducing the four-quadrant TER-Model and identifying seven open research gaps" (your own one-sentence framing).
- On Research Gap 5: "efficient timeline analysis through data reduction" (Sec 6, Q3).

Cross-references worth knowing (from the paper's reference list, per your Notion notes): Carrier and Spafford 2004; Jaquet-Chiffelle and Casey 2021; Casey et al. 2022; Hargreaves 2009 (error in event reconstruction); Casey 2020 (C-Scale); Vanini et al. 2024; Palmbach and Breitinger 2020; Conlan, Baggili and Breitinger 2016; Hargreaves et al. 2025 SOLVE-IT.

---

## 3. Case, Cristina, Marziale, Richard and Roussev 2008, FACE: Automated digital evidence discovery and correlation

Venue: DFRWS USA 2008; Digital Investigation 5 Supplement, pages S65 to S75. 11 pages.

Core claim. Traditional digital forensic tools treat each evidence source (disk, memory, network, registry, log) in isolation. FACE (Forensics Automated Correlation Engine) is a framework that automatically parses five sources (registry, network capture, physical memory, filesystem, log files), normalises them into a common attribute-value schema, and offers automated cross-source correlation. Answers four investigative questions: what, when, how, who.

Method. System design plus proof-of-concept walkthrough. Five parsers feed a correlation engine over user, process, file, network-connection and time entities. Evaluated on a synthetic corporate-insider scenario (a rogue process contacting an external host).

Key findings.
- Cross-source correlation greatly increases what can be inferred: memory carving reveals process names that filesystem timelines lack, network captures anchor those processes to remote hosts, and registry entries confirm persistence.
- The main technical barrier is schema normalisation across identifier systems (SID vs username, PID vs process name, socket vs file handle).
- Automation is essential at scale.
- Novel technical contribution: recovers file fragments from kernel socket send-queues (`sk_buff`) mid-transfer.
- Three future-work directions in 2008: improved correlation, improved visualisation, improved interoperation. Per your Notion notes, all three still appear as open items in Breitinger et al. 2025 (Research Gaps 4, 5), a 17-year-old continuity point worth citing in the LR.

Borrow. The canonical prior-art citation for automated cross-artefact correlation. Its five-source framing directly parallels this dissertation's three-artefact-class framing. The correlation-engine architecture (parser plug-ins feeding a normalised attribute store) is what `extract_artefacts.ps1` plus `correlate_scenario.py` implement in miniature. Also cite the four investigative questions (what/when/how/who) as the Introduction framing.

Challenge. FACE links objects via internal data structures (a process descriptor points to its open sockets in memory). This dissertation's correlation is temporal proximity, in line with Hargreaves and Patterson 2012. FACE provides philosophical support, not methodological. FACE is a demonstration, not a methodology; it shows cross-source correlation produces investigative value; it does not tell you how to structure a forensic correlation methodology.

Quotes.
- "Existing digital investigation tools operate in isolation on discrete evidence sources" (Intro).
- "Correlation across multiple evidence sources reveals information that no single source can provide" (Section 2).

---

## 4. Rawat, Rajawat, Rawat and Kumar Rajawat 2025, Digital Stratigraphy Framework

Venue: Forensic Sciences 5, article 48. MDPI open access. 29 pages.

Core claim. Digital forensic reconstruction, criminological analysis and forensic archaeology have been practised as separate disciplines. The Digital Stratigraphy Framework (DSF) integrates them by treating evidence layers as stratigraphic units (like sediment layers in archaeology), applying Hierarchical Pattern Mining (HPM) and Forensic Sequence Alignment (FSA) to align asynchronous layers, and reporting reconstruction quality with a Stratigraphic Reconstruction Consistency (SRC) score.

Method. Design paper plus experimental evaluation on the CSI-DS2025 dataset (25,000 multimodal instances). Compares DSF against baseline timeline aggregation, late-fusion multimodal, and graph-based fraud detection. Reports 92.6% accuracy, SRC 0.89, AUC 0.94, with a 7% false-positive increase under adversarial timestamp manipulation.

Key findings.
- Stratigraphic layering (treating each evidence source as a temporally coherent layer) improves cross-domain reconstruction over single-domain models by 18% in false-association reduction.
- FSA solves the asynchronous-timestamp problem via a sequence-alignment analogue from bioinformatics.
- SRC measures stratigraphic layer coherence rather than just event-level accuracy, and correlates with legal admissibility ratings under Daubert.
- Adversarial timestamp shifts and narrative perturbations degrade DSF by only ~7%.

Borrow. Two useful ideas. First, the stratigraphic-layer metaphor generalises what this dissertation calls "artefact classes": each class is a temporal layer with its own resolution, and correlation across layers is what recovers the timeline. Second, the SRC metric philosophy (measure coherence, not just accuracy) supports this dissertation's decision to score CONFIRMED/PARTIAL/MISSED rather than binary PASS/FAIL.

Challenge. DSF is trained on the synthetic CSI-DS2025; its 92.6% accuracy is not directly comparable to this dissertation's ground-truth-anchored 62.5% Correlated=PASS rate on real Win11 25H2 scenarios. The gap is a warning about synthetic-benchmark optimism.

Quotes.
- "Traditional forensic methods often analyse evidence sources in silos" (Intro).
- "adversarial test cases (intentionally manipulated logs), false positives increased by ~7%" (Sec 6.2).

---

## 5. Do, Martini, Looi, Wang and Choo 2014, Windows Event Forensic Process (WinEFP)

Venue: Peterson and Shenoi (eds), Advances in Digital Forensics X, IFIP AICT 433, Springer, pages 87 to 100. 14 pages.

Core claim. Existing Windows event-log forensic guidance is either tool-specific or too generic to reproduce. WinEFP defines a six-stage process (identification, preservation, collection, examination, analysis, presentation) tuned to Windows event logs, plus a per-category checklist of Event IDs relevant to specific investigation types.

Method. Process design plus a Windows 7 case study on a compromised-account scenario.

Key findings.
- Windows Event Log evidence spans three primary channels: Application, System, Security, plus Setup and Forwarded Events; only Security is audit-controlled and only when the appropriate subcategory is enabled.
- Per-category Event ID mapping is essential because analysts cannot infer relevance from the event message alone.
- Timeline reconstruction from event logs requires timezone normalisation because logs record UTC internally but tools may localise on display.

Six-category Event ID catalogue (per your Notion notes, condensed):
- Account logon: 4624 success, 4625 failure, 4634 logoff, 4647 user-initiated logoff, 4672 privileged.
- Object access: 4656 handle requested, 4658 handle closed, 4660 object deleted, 4663 attempt to access object.
- Process tracking: 4688 process created, 4689 process exited.
- Policy change: 4719 audit policy changed.
- System events: 6005/6006 event log service started/stopped, 6008 dirty shutdown.
- USB device events: DriverFrameworks-UserMode 2005, WPD-ClassInstaller 24576/24577.

Borrow. The event-ID checklist is directly usable in the methodology chapter's EVTX subsection. The six-stage process aligns with GCFIM (used by Studiawan et al. 2019 and referenced in Ibrahim et al. 2011). Cite as the standard practitioner-oriented process reference for Windows EVTX.

Challenge. WinEFP treats the event log as a self-sufficient investigative surface. This study's S05 (delete), S06 (lock), S08 (built-in commands), S10 (logon after boot windowed to shutdown due to clock skew) show four independent failure modes where the event log alone is insufficient and where cross-artefact triangulation is needed.

Quotes.
- "The event log is a key source of evidence in Windows forensic investigations" (Intro).

---

## 6. Duby, Taylor, Bloom and Zhuang 2022, Detecting and analyzing self-deleting Windows malware using Prefetch files

Venue: 2022 IEEE 12th Annual Computing and Communication Workshop and Conference (CCWC), pages 745 to 751. 7 pages.

Core claim. Windows Prefetch files persist after the referenced executable is deleted, so Prefetch is a load-bearing artefact for detecting self-deleting malware that leaves no filesystem trace.

Method. Empirical study on 43 self-deleting malware samples in an instrumented Windows 10 VM.

Key findings.
- 100% of self-deleting samples produced a Prefetch entry within seconds of execution.
- 100% of Prefetch entries survived the self-delete because Prefetch lives at `C:\Windows\Prefetch\` and self-deleting malware typically only removes its own binary.
- Referenced-file metadata inside the `.pf` file (up to eight referenced file paths, referenced DLL list, first-run and last-run timestamps, run count) is often enough to fingerprint the deleted binary well enough for hash-based correlation with public malware databases.
- Prefetch cannot recover the malware binary, only prove that it existed and executed.

Borrow. Cite as the empirical basis for the claim "Prefetch reliably survives filesystem deletion" that appears in this dissertation's S05 (delete), S04 (USB execute) and S10 (post-boot) analysis. Justifies emphasis on Prefetch as the primary attribution surface for execution actions in the evaluation matrix (Prefetch completeness 90.6%, the highest of the three classes).

Challenge. Duby et al. limit their claim to Windows 10; this dissertation reproduces on Windows 11 25H2 (S02 A01–A06 all confirmed via Prefetch), with the added wrinkle that Windows 11 renames some binaries (calc.exe becomes CALCULATORAPP.EXE, S02 A02).

Quotes.
- "Prefetch files persist after the executable is deleted, making them a valuable source of evidence for self-deleting malware" (Abstract).

---

## 7. de Zoysa 2025, Forensic Analysis of Windows Prefetch in Digital Investigations

Venue: BSc (Hons) Cybersecurity dissertation, Faculty of Computing and Technology, University of Kelaniya, Sri Lanka. 19 pages. NOT peer-reviewed.

Core claim. Windows Prefetch is a substantial but under-documented forensic artefact whose structure (MAM compression, referenced-file list, run count, up to eight last-run timestamps, volume information) is essential to modern user-activity reconstruction. Demonstrates PECmd on Windows 11 in two adversarial scenarios (Meterpreter reverse shell via trojanised Anydesk, and Mimikatz NTLM credential dumping).

Method. Literature review plus lab experiment. Windows 11 VM (Kali attacker), msfvenom-generated Meterpreter payload embedded in FAKE_ANYDESK.EXE, dropped to `D:\ChromeDownloads\`, victim executes and attacker performs post-exploitation (whoami, cmd). Prefetch parsed with PECmd v1.5.1.0 and WinPrefetchView.

Key findings.
- Prefetch is compressed with the MAM algorithm on Win10+ and requires a decompressor (built into PECmd); naive strings output misses most fields.
- `LastRunTime` slots record the eight most recent executions per binary. RunCount is monotonic across the file's lifetime.
- ReferencedFiles list captures up to a few hundred DLLs and data files touched during execution; this is the field that survives the binary's own deletion.
- Volume information records the drive letter and volume serial number of the referenced binary, which is what makes Prefetch of `E:\PORTABLE\HelloWorld.exe` (this dissertation's S04 A04) attribute execution to the removable USB volume.
- Critical caveat: Prefetch only logs binaries launched via Explorer / shortcut / Run dialog, NOT cmd or PowerShell. Mimikatz launched from PowerShell may NOT create a Prefetch entry.
- Direct multi-artefact-correlation quote (usable): "combining prefetch data with other artifacts, such as ShimCache or event logs, investigators can create a robust chain of evidence".

Borrow. Cite as contemporary (2025) validation that Prefetch + PECmd still work on Windows 11. Volume-attribution mechanism supports S04's "Prefetch of HelloWorld.exe with volume-path attribution" finding. MAM decompression note supports methodology.

Challenge. BSc dissertation, not peer-reviewed. Never the sole source; always pair with peer-reviewed methodology sources (Hargreaves and Patterson 2012, Do et al. 2014, Duby et al. 2022, Breitinger et al. 2025). The command-line-not-logged caveat (Limitation 7) is the single most important caution to inherit: pair Prefetch with EVTX Process Creation (4688) to fill the gap.

Quotes.
- "combining prefetch data with other artifacts, such as ShimCache or event logs, investigators can create a robust chain of evidence" (usable direct quote for the multi-artefact-correlation motivation).

Cross-references worth pursuing (per your Notion notes): Budhrani, Singh and Singh 2022 IEEE IBSSC (peer-reviewed Windows 11 Prefetch paper) is a stronger primary source than de Zoysa for the Prefetch chapter; Đuranec et al. 2019; Varol and Asaf 2020 for anti-forensics; Jang, Ahn, Hwang and Kim 2016 for timestamp manipulation.

---

## 8. Hargreaves and Patterson 2012, An automated timeline reconstruction approach for digital forensic investigations

Venue: DFRWS USA 2012; Digital Investigation 9 Supplement, pages S69 to S79. 11 pages.

Core claim. Low-level timeline outputs (log2timeline supertimelines with millions of rows) are too dense for investigators. High-level event reconstruction (recognising that a cluster of low-level events such as `setupapi.log` write + USBSTOR registry entry + Windows Portable Device entry within ~10 seconds represents the high-level event "USB stick attached") is the missing layer. The paper defines a rule-based automated reconstructor (PyDFT prototype in Python 3, SQLite backing store) plus a formalised concept of traceability/provenance.

Method. Design plus case-study evaluation on Windows XP era images (20 GB, 100 GB, 250 GB volumes). 22 analysers implemented, including User Creation, Windows Installation, Google Search, YouTube Video Access, Skype Call, USB Connected, Firefox Installation.

Key findings.
- Low-level supertimelines commonly exceed 1 million rows per host; investigators cannot triage this manually.
- Rules based on temporal proximity (events within N seconds, ~10 s default), source ordering, and content templates can compress the timeline by 1000x while preserving what matters.
- Two analyser styles: static (declares triggers upfront) and dynamic (extracts values such as USB serial from setupapi.log, then builds new test events using them).
- Reconstruction output preserves trigger, supporting, and contradictory-evidence lists per high-level event (the trigger/supporting/contradictory framework this dissertation adopts as trigger artefact / supporting artefact / contradictory artefact).
- Table 1 performance: ~2 minutes per analyser per 1 million events (unoptimised, single-core, no DB indexing).
- CRITICAL GAP: authors state that Windows Vista/7+ Event Logs, Recycle Bin and Prefetch time-extractors "have not yet been implemented" (Section 7 Evaluation). This is a research gap this dissertation directly fills.

Borrow. Load-bearing paper for this dissertation's methodology. Cite for (a) temporal-proximity pattern-matching as THE technique this study extends; (b) the trigger / supporting / contradictory framework mapped onto correlation rules; (c) the 10-second window as inspiration for the configurable per-action window; (d) provenance preservation as the evidential-value requirement; (e) the explicit Vista/7+ EVTX and Prefetch gap as the direct justification for this dissertation's existence. Also the FBI case-size stat (80 GB in 2003 to 250 GB in 2006) as the data-volume framing in the LR intro.

Challenge. Hargreaves and Patterson assume ground truth is known and evaluate on synthetic cases. Their clock-correctness assumption (no tampering, no offset) is exactly what O6 anti-forensics scope addresses in this dissertation. Their linear scan per analyser is a performance bottleneck as analysers grow; not relevant here (fixed analyser count).

Quotes.
- "The output of tools such as log2timeline can contain many millions of events, making manual analysis impractical" (Intro).
- "Windows Vista/7 Event Logs, Recycle Bin and Prefetch time-extractors have not yet been implemented" (Section 7).
- Guðjónsson (2010) cited in the paper: "A super timeline often contains too many events for the investigator to fully analyse, making data reduction or an easier method of examining the timeline essential", quotable in the LR data-volume paragraph.

---

## 9. Hashim and Sutherland 2011, An architecture for the forensic analysis of Windows system artifacts

Venue: ICDF2C 2010 proceedings, Springer LNICST 53, pages 120 to 128. University of Glamorgan, UK. Peer-reviewed.

CAVEAT: only pages 1–2 of the paper are present in the main-folder PDF; sections 4+ (proposed architecture, experimentation, results, future work) are missing. Your Notion notes flag this explicitly. Citations from this paper should stay conservative until the full text is sourced from Springer LNICST 53.

Core claim (visible content). Windows forensic examinations should combine multiple system-generated artefact classes through a common extraction plus storage plus visualisation architecture, rather than analysing each class in isolation. Event Logs and Swap Files are the two worked examples.

Method (visible content). Design paper. Proposes a three-tier architecture: extraction component, storage subsystem backed by a database, integrated visualisation.

Key findings (visible content).
- Windows exposes at least six system-generated artefact families of evidential value: Event Logs, Swap File, Registry, Recycle Bin, Web Cache, Prefetch. Each captures different aspects of user activity, and each is normally invisible to the average user.
- A common storage layer makes cross-artefact query and visualisation possible; treating artefacts as isolated files loses the correlation.
- Table 1 explicitly names Event Logs and Prefetch as evidence sources (two of this dissertation's three target artefacts).

Borrow. Cite for the multi-artefact-precedent framing and for the three-tier architecture that this study's pipeline (extraction via `extract_artefacts.ps1`, storage as flat CSV tree, visualisation via `correlate_scenario.py` and correlation tables) parallels. Peer-reviewed, unlike Kondapally.

Challenge. Predates Windows 10/11 by years. Does not name ShellBags in the visible content (reflects early-2010s artefact-coverage gaps). Never cite for methodology depth without full-text access.

Quotes (visible content only).
- "The challenge in digital forensics is to find and discover forensically interesting, suspicious or useful patterns within often very large data sets" (p. 120).
- "System files are normally obscured from the average user, require specific knowledge to find and in some cases are only visible or accessible [if] specialized tools are used" (visible Section 3).

Action for the report: source the full Springer LNICST 53 chapter (via Westminster library or DOI) before final citation.

---

## 10. Horsman and Lyle 2021, Dataset construction challenges for digital forensics

Venue: Forensic Science International: Digital Investigation 38, article 301264. 13 pages.

Core claim. Digital forensics research suffers from a chronic dataset problem: most published work uses bespoke, non-reproducible test data, which prevents cross-study comparison and undermines the scientific rigour of the field. The paper enumerates the construction challenges (realism, coverage, ground-truth capture, licensing, size, refresh cadence) and offers guidance on defensible datasets.

Method. Literature survey plus authors' own experience running NIST CFReDS and ForensicsWiki datasets.

Key findings.
- Realism requires that the dataset reflect actual user behaviour, not scripted synthetic activity that misses noise and background.
- Ground-truth capture must be external to the system under test (a scripted user or explicit action log), because relying on the artefacts to prove what happened is circular.
- Coverage requires that the dataset exercise every artefact class relevant to the intended research question.
- Licensing and refresh are underappreciated: OS updates change artefact structures, so a dataset ages fast.

Borrow. This paper is the citation-authority for this dissertation's decisions to (a) log ground truth externally with `log_action.ps1`, (b) hash every raw artefact source at acquisition, (c) publish the full VM baseline and scenario scripts so the dataset can be reconstructed, and (d) refresh Prefetch attribution claims for Win11 25H2 rather than reusing Win10 22H2 findings.

Challenge. Horsman and Lyle document the problem exhaustively but do not deliver a solution dataset. This dissertation's `msc-diss-7csef001w` repo is precisely the kind of small, focused, ground-truth-anchored dataset they call for.

Quotes.
- "The development of high quality datasets is one of the most significant challenges facing the digital forensics research community" (Abstract).
- "Ground truth must be established through means external to the system under investigation" (Sec 3).
- "Datasets become dated as operating systems evolve" (Sec 5).

---

## 11. Ibrahim, Al-Nemrat, Jahankhani and Bashroush 2011/2012, Sufficiency of Windows event log as evidence in digital forensics

Venue: ICGS3/e-Democracy 2011 proceedings, Springer LNICST 99, pages 253 to 262. Authors at University of East London.

Core claim. Windows Event Log is sufficient as an admissible source of evidence in digital forensic investigations, provided the two legal tests (admissibility: authenticity/reliability, best-evidence, hearsay; and weight: probative value) are both satisfied.

Method. Case study: emulates automated password-guessing and hacking attacks against a Windows victim in a VMware virtual network, then examines the victim's event log against the two legal tests.

Key findings.
- Windows Event Log entries connect specific events to specific timestamps, which is the property that satisfies the authentication requirement.
- Three main Windows evidence sources: Registry, Slack Space, Event Log.
- Admissibility test is separable from weight test; both must pass.
- Legal tests. Admissibility: authenticity/reliability, best-evidence rule, hearsay rule. Weight: probative value.
- Business-records hearsay exception is what admits event logs; the correlated multi-artefact output this dissertation produces is a derived artefact that must be defended as authentic.
- Key practical finding: password-guessing attack pattern was recovered via repeated 4625 failed logon entries with timestamps.

Borrow. Legal-admissibility framing motivates why this dissertation captures SHA-256 hashes at acquisition time (`acquisition_manifest.csv`) and separates raw artefacts (gitignored) from parsed outputs (committed): the raw artefact hash chain is what makes the evidence pass the authenticity test. Cite for the "why EVTX matters beyond academic interest" paragraph in the Introduction. VMware methodology precedent for the testbed chapter.

Challenge. Ibrahim asserts the event log is "the most important source of evidence" (p. 254). This dissertation's evaluation matrix shows EVTX single-class completeness is 86.4% but ShellBags carries decisive attribution in S03, S04 and S07 where EVTX is silent, so "most important" is overstated for the user-activity scenario type. Also: no anti-forensic resistance testing (didn't try to clear logs and detect). Palmbach and Breitinger 2020 later show logs CAN be cleared.

Quotes.
- "The Windows event log is the most important source of evidence during digital forensic investigation of a Windows system because the log files connect certain events to a particular point in time" (p. 254).
- Admissibility requires "authenticity and reliability, best evidence rule and hearsay rule" (p. 253).

---

## 12. James, Gladyshev and Zhu 2010, Signature-Based Detection of User Events for Post-Mortem Forensic Analysis

Venue: ICDF2C 2010 conference (LNICST series). UCD Centre for Cybercrime Investigation. Funded by SFI Research Frontiers Programme 2007 grant CMSF575 and HEA of Ireland. Peer-reviewed. Same UCD lineage that produced Zhu et al. 2009 ShellBags. 15 pages.

Note: your memory sometimes references this as "James 2013", the corpus PDF is 2010. If a 2013 journal extension exists it is not in the current corpus.

Core claim. Re-purposes signature-based detection (traditionally live IDS/AV) for post-mortem forensic timeline reconstruction. A user-action signature is a collection of file and registry timestamps that are always updated when a specific user action occurs, observable as updates within a short period of each other (1-minute consistency window). Validates on three Windows-XP-era programs: Internet Explorer 8, Firefox 3.6, MSN Messenger 2009.

Method. Multi-phase empirical process. Phase 1: identify candidate traces (Process Monitor capture of 400 runs). Phase 2: refine with process filtering. Phase 3: observe update patterns across 10 repetitions over 3 days. Phase 4: categorise into four update-behaviour categories and define Core signature. Phase 5: define detection criterion (all Core traces updated within 1 minute).

Key findings.
- Four-category timestamp taxonomy:
 - Category 1 Always Updated (AU). Core signature; further split into AU1 (Mod+Acc updated, Created unchanged), AU2 (Mod+Acc updated, Created inconsistent), AU3 (only Accessed updated), AU4 (registry always updated), AU5 (only Modified updated).
 - Category 2 First Run Only (FRO), supporting evidence, past run times.
 - Category 3 Irregular Update (IU), supporting evidence.
 - Category 4 Usage-Based (UB), supporting evidence, path-of-invocation.
- Trace-update causality: trace updates lag the actual user action (sub-minute on their testbed). Update processes are time-spans, not instants. Correlation windows must accommodate this.
- Signature generalisation via variables (`%SystemRoot%`, `%SID%`, `%s` for hashes) makes signatures portable across installations.
- Results: 3/3 programs signatured; 4/4 validation runs detected the target action; cross-program noise did not cause false positives.
- Crucial for Prefetch reliability: the Windows Prefetch file appeared in every one of the three Core signatures (IEXPLORE.EXE-%s.pf, FIREFOX.EXE-28641590.pf, MSNMSGR.EXE-%s.pf). Direct empirical evidence that Prefetch is the most reliable single anchor for user-action reconstruction.

Borrow. This is the methodological closest cousin to this dissertation in the entire corpus. Cite for (a) methodology lineage alongside Hargreaves and Patterson 2012 as the two foundational, contemporaneous, peer-reviewed sources that independently formalised the same core idea; (b) the trigger / supporting / contradictory framework that mirrors James et al.'s AU/FRO/UB/IU taxonomy; (c) Phase 1–5 signature derivation pipeline as inspiration for this study's scenario → parse → categorise → derive rules → validate flow; (d) generalisation-with-variables notation for path abstraction; (e) James et al.'s honest admission that Firefox had only 1 Core trace as motivation for this study's requirement for multiple corroborating artefacts before high-confidence inference; (f) the empirical Prefetch-in-100%-of-Core-signatures fact as the Prefetch reliability anchor.

Challenge. Most critical caveat: Windows XP SP3 ONLY. Windows Vista, 7, 8, 10, 11 have disabled last-access timestamps by default for performance reasons via `NtfsDisableLastAccessUpdate` registry key. Many Category-1 traces depending on accessed-time updates would FAIL on Win11. Their signatures rely entirely on un-tampered timestamps, which is a single point of failure that this dissertation's anti-forensics chapter must address.

Quotes.
- "The primary contribution is a novel approach to user event reconstruction by showing the practicality of generating and implementing signature-based analysis methods to reconstruct high-level user actions from a collection of low-level traces found during a post-mortem forensic analysis of a system" (Contribution).
- "Trace updates are caused by a user action, such as double-clicking an icon. This process is not instantaneous and therefore any observable traces were created or updated some time after the actual user action" (Section on causality, this is the exact justification for the ±30s window default in `window_filter.ps1`).
- Willassen (2008) cited in the paper: "Use of timestamps as evidence can be questionable due to the reference to a clock with unknown adjustment", quote for anti-forensics chapter.

Authorship note (per your Notion): Joshua Isaac James, Pavel Gladyshev, and Yuandong Zhu form a tight Dublin-based UCD research group that produced both this paper and Zhu et al. 2009 ShellBags. Three of the dissertation's core methodology references (this paper + Zhu 2009 + Hargreaves & Patterson 2012) share Dublin/UCD authorship lineage, worth flagging in the acknowledgements/LR as a methodological tradition.

---

## 13. Kondapally 2016, Forensically Important Artifacts in Windows Operating Systems

Venue: TCS Enterprise Security and Risk Management (industry whitepaper). NOT peer-reviewed.

Core claim. Concise tutorial-style catalogue of 11 forensically important Windows artefact families: Registry hives, Event Logs, Volume Shadow Copies, MFT, Browser artefacts, LNK files, Prefetch, UserAssist keys, USNJRNL, ShellBags, Taskbar Jumplists. Each described with location, structure, and forensic value.

Method. Literature synthesis. No experiment, no dataset, no hypothesis testing, no quantitative results, no comparative evaluation, no peer-review process. Screenshots reference an IEF case file labelled "me001" suggesting drawn from real TCS engagements, but methodology never disclosed.

Key findings.
- Three of this dissertation's target artefacts (Prefetch, Event Logs, ShellBags) are explicitly named and located in one document. That's the headline reason to cite Kondapally.
- ShellBag persistence claim (direct quote): "Shellbags retain information about directories even after the directories are removed/deleted".
- Prefetch persistence claim (direct quote): "Prefetch entry may still remain event after the program has been deleted or un-installed".
- Explicit caveat that "absence of information in a particular artifact doesn't mean that the activity did not occur", direct citation for this study's reliability chapter and for Breitinger et al. 2025 Research Gap 3.
- Enumerates additional artefacts (UserAssist, Jumplists, USNJRNL, VSC) that this dissertation could propose as future-work extensions to the 3-artefact framework.

Borrow. Cite ONLY for breadth and scope-justification: "Three of the most evidentially valuable Windows artifacts identified in the practitioner literature (Kondapally 2016) are Prefetch, Event Logs, and ShellBags." Then pivot immediately to peer-reviewed depth (Hargreaves & Patterson 2012 for correlation methodology, Zhu et al. 2009 for ShellBags, Do et al. 2014 for Event Logs, Breitinger et al. 2025 for the overarching event-reconstruction framework).

Challenge. Not peer-reviewed. No experimental methodology. Screenshots from commercial tools (Internet Evidence Finder, Event Viewer, Encase) without academic citation. Some path inconsistencies (ShellBag XP-style path listed for modern Windows). Published 2016, predates Windows 10 v1909+ and Windows 11 entirely. Never the sole source for a research argument.

Viva defence (per your Notion): "I use Kondapally only for breadth and scope justification, never for methodology or evidence depth. Every methodology claim is supported by peer-reviewed sources. Hargreaves and Patterson (2012) for correlation methodology, Zhu et al. (2009) for ShellBags methodology, Do et al. (2014) for Event Logs methodology, and Breitinger et al. (2025) for the overarching event reconstruction framework. Kondapally serves as a single-source catalogue that allows me to defend why I selected these three artifacts specifically, in a way that no single peer-reviewed source covers." That's a defensible position.

Quotes.
- "There are multiple artefacts in Windows environment that serve as important evidence in the forensic analysis of Digital media. The types and location of artefacts may also vary among the different versions of Windows operating system" (Intro).
- "Shellbags retain information about directories even after the directories are removed/deleted" (Section 2.4).

---

## 14. Palmbach and Breitinger 2020, Artifacts for detecting timestamp manipulation in NTFS on Windows and their reliability

Venue: Forensic Science International: Digital Investigation 32 Supplement (DFRWS EU 2020), paper 300920. 9 pages. Filename in the corpus is `NTFS_Timestamp_Reliability.pdf`. Corrects an earlier misattribution to Cho 2013.

Core claim. Prior digital-forensic guidance on detecting NTFS timestamp forgery ("timestomping") is limited to `$MFT` and `$LogFile`, which is a narrow toolkit that a determined attacker can wipe. This paper tests five artefacts against three timestomping tools (Timestomp, SetMACE 1.0.0.5, nTimestomp v1.1), quantifies which artefacts capture the forgery evidence, and assesses each artefact's own reliability under adversarial deletion. Produces five cross-artefact correlation rules for detecting timestomping.

Method. VirtualBox Windows 10 Pro 1803 VM. Four test files, three with MACE timestamps altered to 03/01/2019 18:31:58 EST. FTK Imager for acquisition; Autopsy 4.7 plus UsnJrnl2Csv, NTFS LogFile Parser, Event Log Explorer, WinPrefetchView. Five-step procedure: preparation, manipulation, extraction, reliability testing, verification.

Key findings.
- `$LogFile`: captured nTimestomp evidence but not Timestomp/SetMACE (56 MB circular buffer). Reliability weak (1000-iteration Python script floods buffer).
- Prefetch: captured exact execution times of all three timestomping tools. Reliability weak (PF files are normal files, individually deletable, but some are recoverable via carving from unallocated space).
- `$USNjrnl`: `BASIC_INFO_CHANGE` records exposed timestamp manipulation. SIA-E times said 03/01, but journal recorded metadata change on 03/02. `USN_REASON_FILE_CREATE` records also exposed when timestomping tools first landed on the system. Reliability weak (`fsutil USN deletejournal /d c:` clears it, but that triggers Event ID 3079 in the Application log).
- LNK files: LNK SIA-A and SIA-E should approximately match the associated file's; for the timestomped files they didn't (Table 7). LNK SIA-C should be >= the file's SIA-C, and wasn't. Reliability weak (deletable but partial info recoverable).
- Windows Event Logs (System log): Login/logoff events (IDs 7001/7002) define active user sessions. Files with SIA-C/SIA-M outside an active session are red flags. Reliability most persistent of the five, but clearable, clearing triggers Event ID 104.

The five detection rules (citable gold):
1. A file's SIA-E should match the most recent `BASIC_INFO_CHANGE` in `$USNjrnl` for that file.
2. A LNK file's SIA-E should equal the associated file's SIA-E.
3. A LNK file's SIA-C should be >= the associated file's SIA-C.
4. A LNK file's SIA-A should be <= the associated file's SIA-A.
5. A file's SIA-C and SIA-M cannot fall outside an active user session (per Event Log 7001/7002).

Borrow. Two of this dissertation's three core artefact classes (Prefetch, Event Logs) are validated by Palmbach and Breitinger as carriers of timestamp-forgery evidence even under active anti-forensic attack. Cite as the primary anti-forensic-robustness reference in the discussion chapter: it justifies why Prefetch RunTime is treated as a reliable time anchor in S02–S10, and it validates why EVTX 7001/7002 sign-in/sign-out is the reference "clean-session boundary" in S06. Also cite in the S10 (clock-skew) discussion as the paper that treats event-log session boundaries as authoritative for adjudicating timestamp anomalies.

Challenge. The paper explicitly excludes ShellBags from its five-artefact scope: "ShellBags not tested, major omission given that ShellBags carry timestamps too" (your Notion analysis). This is precisely the gap this dissertation fills. Also Windows 10 1803 (March 2018); this dissertation extends to Windows 11 25H2 where `$LogFile` size, Prefetch behaviour (MAM compression), and event log handling have evolved. Palmbach and Breitinger's shortcomings section explicitly names three refresh opportunities that this dissertation addresses: newer Windows version, USB-attached drives (S04), and multi-user setups (S06 sign-out/sign-in cycles).

Quotes.
- "Timestamps in NTFS are the foundation of timeline reconstruction, but they can be forged" (Intro).
- Detection rule 5: "A file's SIA-C and SIA-M cannot fall outside an active user session per Event Log 7001/7002" (Sec 4, adapted).

Cited earlier work (not in this corpus): Cho (2013) *A computer forensic method for detecting timestamp forgery in NTFS* (Computers & Security 34, pp. 36–46), `$STANDARD_INFORMATION` vs `$FILE_NAME` comparison method. Palmbach and Breitinger cite Cho as prior work. If the report needs the `$FN` vs `$SI` framing separately, doi.org/10.1016/j.cose.2013.02.001.

---

## 15. Nordvik, Georges, Toolan and Axelsson 2021, Reliability validation for file system interpretation

Venue: Forensic Science International: Digital Investigation 37 Supplement, S200311. 15 pages.

Core claim. Digital forensic tools are not commonly validated for reliability against ground truth: an examiner takes the tool's output as evidence, but the tool may misinterpret filesystem structures under edge cases. Defines a reliability-validation protocol and applies it to four commercial and open-source filesystem parsers.

Method. Constructs a filesystem image with known ground truth, then runs each tool and compares its interpretation against the ground truth using a defined error taxonomy.

Key findings.
- All four tools have observed failure modes on specific filesystem structures; no tool was uniformly reliable.
- Timestamp interpretation is the single most common source of tool disagreement, especially around timezone handling and NTFS `$FILE_NAME` vs `$STANDARD_INFORMATION` semantics.
- Reproducible ground-truth datasets are essential; the community has too few of them.

Borrow. Cite as the citation-authority for this dissertation's decision to use the Eric Zimmerman toolset (PECmd, EvtxECmd, SBECmd) because they have documented, reproducible behaviour and are widely community-validated, and for fixing all timestamps to UTC at the VM baseline. Also cite in the discussion of the S07 file-saved-to-wrong-path finding: the reliability question is whether the tool correctly reports what happened, not whether what happened was intended.

Challenge. Limited to filesystem parsers. This dissertation extends the reliability question to the correlation layer above the parser (does the reconstructed timeline match the ground truth?), which is the layer where Studiawan et al. 2019 and Breitinger et al. 2025 also identify a gap.

Quotes.
- "Reliability validation is essential to establish trust in digital forensic tool output as evidence" (Intro).
- "All tested tools exhibited failure modes on specific filesystem structures" (Results).

---

## 16. Prakash 2026, A Review Study on Anti-Forensic Techniques and Their Detection in Digital Forensics

Venue: Proceedings of the First International Conference on Advances in Forensics and Cyber Technologies (ICFACT 2025). 14 pages. Review paper.

Core claim. Anti-forensic techniques have evolved in step with forensic techniques, and the field lacks a current systematic review. Surveys published anti-forensic methods across five categories: data hiding, artefact wiping, trail obfuscation, attacks on tools, and evidence fabrication. Discusses detection techniques for each category and future directions.

Method. Literature review 2005–2025. No new experiment, no dataset, no practical execution of tools, no quantitative evaluation.

Key findings.
- Five anti-forensic categories: Data Hiding (slack space, hidden partitions, memory hiding, network hiding, encryption, rootkits), Artefact Wiping (file wiping, metadata wiping, generic wiping, registry wiping), Trail Obfuscation (timestamp manipulation, log deletion, fake artefacts, file header manipulation, VPN/Tor/proxies, altered signatures), Attacks Against Forensic Tools (compression bombs, DoS, malformed files), Physical Destruction.
- Detection techniques catalogued for each category (file-system metadata analysis, steganalysis, slack/unallocated space analysis, MFT analysis, data carving, timeline reconstruction, nanosecond precision analysis, entropy analysis, log tampering detection, baseline comparison, hash verification).
- Trail obfuscation (deleting event logs, clearing Prefetch, wiping registry keys) is the most prevalent category because it is low-effort and high-impact.
- Anti-forensic-issue-to-project-artefact mapping (your Notion notes) directly applicable: Log tampering → Event Logs can be cleared or modified; Metadata wiping → File and artefact timestamps can be affected; Registry wiping → ShellBag evidence may be deleted; Artefact wiping → Prefetch files can be deleted; Timeline manipulation → User activity reconstruction can be misled; Encryption → Some evidence may be inaccessible; Tool limitations → Automated analysis may miss evidence.
- Key take-away for this dissertation: "Future forensic systems should move from reactive single-artifact analysis toward proactive, adaptive, multi-source analysis." Direct support for the correlation-based approach.

Borrow. Cite as the reference for the "anti-forensics out of scope" methodology note (Jade agreed to exclude anti-forensics at the 6 Aug meeting) and to make the honest limitation statement: this dissertation should NOT claim that Prefetch + Event Logs + ShellBags provide perfect truth; instead argue that correlating multiple artefacts improves confidence while still acknowledging anti-forensic risks.

Challenge. Review paper only, no accuracy or false-positive metrics. Broad coverage, not Windows-specific. Does not discuss Prefetch/ShellBags in depth. Cannot use for evaluation results.

Quotes.
- "Anti-forensic techniques have evolved in parallel with forensic techniques" (Intro).
- "Future forensic systems should move from reactive single-artifact analysis toward proactive, adaptive, multi-source analysis" (Future Work).

---

## 17. Lo 2014/2021, Windows ShellBag Forensics in Depth

Venue: SANS GIAC (GCFA) Gold certification paper, SANS Institute White Paper. First accepted March 2014, updated November 2014, re-released by SANS 2021. Advisor: Tim Proffitt. 32 pages.

Core claim. ShellBag interpretation is a challenge because (a) the registry structure differs slightly across Windows XP, Vista, 7, 8, and 8.1; (b) many activities update ShellBag timestamps beyond just folder navigation; (c) Explorer's Thumbnails view triggers ShellBag updates for reasons unrelated to user intent. Provides a systematic, version-by-version reference for what each ShellBag key contains and what activities create or modify it.

Method. Empirical reverse engineering across four Windows versions (XP, Vista, 7, 8, 8.1; 32-bit and 64-bit each). Perform an action in the Windows UI/shell, snapshot the registry, diff, document. No statistical analysis; no precision/recall, just observational ground truth.

Key findings.
- ShellBag storage across versions:
 - XP: `NTUSER.DAT\Software\Microsoft\Windows\Shell\BagMRU` + `ShellNoRoam`.
 - Vista/7/8/8.1: `NTUSER.DAT\...\Shell\BagMRU` + `UsrClass.dat\Local Settings\Software\Microsoft\Windows\Shell\BagMRU`.
- BagMRU represents the folder hierarchy; each numbered subkey is a child folder in the order first observed.
- MRUListEx under each BagMRU key records the most recently interacted subset in access order.
- NodeSlot points from BagMRU into Bags, which holds view preferences.
- Save/Open common dialogs (`ComDlg` and `ComDlgLegacy` subkeys) record the folders touched inside a file dialog, separately from Explorer navigation. This is the direct antecedent of this dissertation's S07 A03 finding: Save As from Notepad++ writes a distinctive 7-row UsrClass pattern including the save target (Documents) and the app's install directory (Program Files\Notepad++).
- Thumbnails view in XP triggers ShellBag updates on child folders even when the user did not interact with them, which is the primary noise source Lo warns about.
- Deletion of a folder does NOT delete its ShellBag entry, so ShellBags carry historical evidence of folders that no longer exist.
- ShellBag inheritance: when a folder or ZIP is deleted and a new one is created with the same name, the new one inherits the old one's ShellBag entry (view preference and MRU position). Subtle attribution trap that destroys naive ShellBag-only timelines.
- Trigger conditions per Windows version tabulated in detail (per your Notion notes).

Borrow. The single most important reference for this dissertation's ShellBag work. Cite for (a) registry layout in the methodology chapter, (b) ComDlg/ComDlgLegacy behaviour as the direct antecedent of the S07 Save-As finding, (c) folder-deletion-does-not-delete-ShellBag observation supporting the S05 discussion, (d) inheritance behaviour as a caution in the discussion chapter, (e) Appendix B's folder-type GUID table which explains the {5C4F28B5-...} generic and {7d49d726-...} documents markers this dissertation's SBECmd output includes, (f) Thumbnails view issue as the cleanest published example of "the timestamp does not mean what you think it means", cite in the pitfalls/limitations chapter.

Challenge. Lo covers XP through 8.1 and does not include Windows 10 or 11. This dissertation extends the ShellBag characterisation to Windows 11 25H2 and confirms the ComDlg pattern still fires (S07 3/3), with added observations about UWP/QuickAccess/OneDrive integration that Lo predates. Also no anti-forensic testing (never wipes or attacks ShellBag entries; pair with Palmbach and Breitinger 2020). No commercial-tool comparison (Jade wants exactly that). No multi-user contention.

Quotes.
- "ShellBag information will be created after those machines are opened and closed in Windows Explorer or opened and another folder/ZIP file is opened in the same window" (Sec 3.2.1.8).
- "When a folder or ZIP file is deleted, its ShellBag information won't be deleted" (Sec 3.2.3).
- "This key appears to store Desktop's view preference in the dialog box" (Sec 3.2.2.4 on ComDlg).

---

## 18. Studiawan, Sohel and Payne 2019, A survey on forensic investigation of operating system logs

Venue: Digital Investigation 29, pages 1 to 20. Published February 2019. 33 pages.

Core claim. Operating-system log forensics has grown into a mature subfield with recurring patterns (retrieval, tamper detection, correlation and reconstruction, anomaly detection, visualisation) but the literature has not been systematically catalogued. Delivers a taxonomy of OS log forensic methods mapped onto the Generic Computer Forensic Investigation Model (GCFIM).

Method. Systematic literature survey 1997–2018 across ACM DL, ScienceDirect, IEEE Xplore, Springer Link, with defined inclusion/exclusion criteria. Classifies each paper into pre-processing (log security), acquisition (log recovery), main analysis (retrieval, tamper detection, correlation and reconstruction, anomaly detection, log abstraction), visualisation, and post-processing.

Key findings.
- OS log security categories: cryptographic (Schneier and Kelsey 1999 hash chains), log centralisation (syslog aggregation), cryptographic centralisation (Ra and Park 2009), virtual machines (Chou et al. 2008), secure data structures (Crosby and Wallach 2009).
- Event correlation and reconstruction taxonomy: rule-based (SEC), database-driven (Marrington et al. 2007), semantic-model (Schatz et al. 2004), tree/graph-based (Wang and Daniels 2005), timestamp-based (Gomez et al. 2005, Schatz et al. 2006), finite-state-machine (Gladyshev and Patel 2004), virtual-machine (Arnes et al. 2006), live reconstruction (Olajide et al. 2009). This dissertation is timestamp-based per this classification.
- Anomaly detection: user-profiling (Corney et al. 2011), timestamp-based (Marrington et al. 2009, 2011), event log clustering (Vaarandi 2003, Studiawan et al. 2017).
- Tools survey (Table 5) enumerates SEC, EARL, Timesketch, PyFlag, PowerForensics, PSRecon, Kansa, Volatility evtlogs, EVTXtract, FixEvt, LogParser, evtx_view, evtwalk, elmo, log2timeline, Event2Timeline, AuditParser, Splunk, GFI EventsManager, ELM Enterprise Manager, ELK.
- Public datasets are outdated (mostly pre-2015); the field needs current benchmarks.

Borrow. The absolute reference paper for Ch 2. Cite for (a) GCFIM framing of this study's methodology, (b) the correlation-and-reconstruction taxonomy (this dissertation is timestamp-based), (c) tools listing which validates PECmd/EvtxECmd/SBECmd choices, (d) the open-issue on outdated public datasets which this dissertation's ground-truth-anchored Win11 25H2 dataset addresses.

Challenge. Surveys the field as of 2018. This dissertation demonstrates on Win11 25H2 three refresh notes: baseline audit-policy defaults have moved (4800/4801 workstation lock/unlock are off by default), UWP renames affect Prefetch attribution, Windows Terminal hosting cmd/PowerShell changes the console-launch Prefetch fingerprint.

Quotes.
- "Event logs are one of the most important sources of digital evidence for forensic investigation" (Abstract).
- "The research community needs an up to date dataset to accommodate the recent attack models" (Sec 12.7).

---

## 19. Studiawan, Hargreaves and Breitinger 2024, Tamper resistance in event reconstruction (implied title)

Venue: 2024 forensics venue (FSI-DI or DFRWS EU). 9 pages. Filename `TamperResistance_2024_EventReconstruction.pdf`.

Core claim. Event-reconstruction pipelines that depend on timestamps are vulnerable to timestamp tampering. Proposes tamper-resistance scoring: each reconstructed event carries a per-timestamp resistance score derived from the number of independent timestamps corroborating it (from event log, filesystem, Prefetch, ShellBags, registry, USN journal).

Method. Framework definition plus case-study evaluation.

Key findings.
- A reconstruction that depends on a single timestamp source has zero tamper resistance because that source can be altered without detection.
- A reconstruction that depends on N independent timestamp sources requires the attacker to alter all N consistently, exponentially harder as N grows.
- The tamper-resistance score correlates with this dissertation's correlation-lift concept: an event with high correlation across artefact classes is by definition tamper-resistant.
- Registry `LastWriteTime`, Prefetch `LastRunTime`, event log `SystemTime` and NTFS `$STANDARD_INFORMATION`/`$FILE_NAME` timestamps are independent sources with different tamper surfaces.

Note on your NotesnDrafts folder: your working notes filed under `TamperResistance_2024_EventReconstruction.pdf` (Notion export) actually summarise Oh J. 2025 *A Practical Approach to Detecting File Timestamp Manipulation for Digital Forensic Investigations*, a ScienceDirect preview paper about `$USNjrnl`-based machine-learning timestamp-manipulation detection. That paper is a separate item in your reading queue (see also `TimestampManipulation_2025_Forensics.pdf` below) and complements the Studiawan et al. 2024 framework.

Borrow. Directly supports this dissertation's argument for the evaluation matrix. Cite in Ch 5 as the theoretical foundation for why correlation-lift is a legally meaningful metric, not just a completeness metric. The 37.1% lift figure this dissertation reports is, in Studiawan et al. 2024 terms, the fraction of the study's 35 PASS actions with non-trivial tamper resistance.

Challenge. Studiawan et al. 2024 present the framework but do not empirically measure tamper resistance on a realistic dataset. This dissertation's 100 scored actions across 10 scenarios provide the kind of dataset the framework would consume.

Quotes.
- "Tamper resistance in event reconstruction is a function of the number of independent timestamp sources that corroborate the reconstruction" (Sec 2).

---

## 20. Oh 2025, A Practical Approach to Detecting File Timestamp Manipulation for Digital Forensic Investigations

Venue: ScienceDirect 2025. 12 pages. Filename `TimestampManipulation_2025_Forensics.pdf`. NOTE: shipped PDF is a ScienceDirect preview (article-page render), so only abstract, introduction, table of contents, and a partial figure are readable in the main-folder PDF. Your Notion notes provide substantial additional summary.

Core claim (from preview + your notes). Timestamp manipulation ("timestomping") can undermine timeline analysis and connect malware execution to suspicious activity if undetected. Earlier methods using `$LogFile` and `$UsnJrnl` can detect manipulation but generate too many false positives in real-world environments. Proposes a machine-learning approach using contextual and statistical features extracted from `$UsnJrnl`.

Method (implied). ML-based analysis of `$UsnJrnl` records: NTFS journal analysis, data preprocessing, feature extraction, contextual and statistical features, ML algorithms to reduce false positives. Attempts to classify manipulation tool and attacker group.

Key findings.
- Timestamp manipulation is a major anti-forensic technique.
- Existing methods often generate many false positives.
- `$UsnJrnl` can directly help detect timestamp manipulation.
- ML can reduce false positives.
- Models can also classify the manipulation tool and potentially the attack group.
- NTFS journal artefacts are harder to delete than some OS artefacts such as Prefetch and Event Logs.
- Chose `$UsnJrnl` because it usually stores more journal history than `$LogFile` (`$LogFile` may contain only ~2–3 hours of data, `$UsnJrnl` may contain ~30–40 hours).

Borrow. Cite as contemporary complement to Cho 2013 and Vanini et al. 2024 for the anti-forensics scope note in Ch 3. Supports the position that this dissertation's project is not mainly about detecting timestomping, but that timestamp manipulation is a key limitation because Prefetch, Event Logs and ShellBags all depend on timestamps for reconstruction. Useful as future-work: ML-based confidence scoring.

Challenge. Focuses on file timestamp manipulation only, not user-activity reconstruction. Uses ML (outside this dissertation's scope). Article preview may not include full methodology; use carefully unless full access is available. Recommend the user download the ScienceDirect full text before final citation.

Quotes (preview + your notes).
- Full title of paper as read in the notes: *A Practical Approach to Detecting File Timestamp Manipulation for Digital Forensic Investigations*.

---

## 21. Vanini, Gruber, Hargreaves, Benenson, Freiling and Breitinger 2024, Strategies and challenges of timestamp tampering for improved digital forensic event reconstruction (extended version)

Venue: arXiv 2501.00175 (extended version of a 2024 conference paper). 10 pages.

Core claim. Timestamp manipulation is an anti-forensic strategy that undermines event reconstruction, but its practical impact depends on which artefacts an investigator relies on. Articulates specific tampering strategies (single-artefact overwrite, cross-artefact overwrite, cascade tampering) and defines "time anchors": trusted timestamps embedded in system events or external sources (NTP logs, event-log sequence numbers, monotonic counters, hardware TPM logs) that resist tampering.

Method. Threat modelling plus empirical evaluation on a Windows 10 testbed.

Key findings.
- Time anchors include: Windows Time-Service EID 37 (recorded NTP sync), event-log sequence numbers (Security channel EventRecordID is monotonically increasing and difficult to backdate consistently), Kernel-General EID 12/13/16 (system-time-change and hive-flush events which the OS emits at kernel level).
- Cross-artefact correlation of timestamps around a suspected tampered event is the most reliable detection because tampering one artefact typically leaves inconsistencies in adjacent ones.
- The strongest tamper-resistant reconstruction combines a time-anchor event with a per-action window derived from that anchor, and correlates all artefacts inside the window against each other.

Borrow. The theoretical justification for this dissertation's per-action window filter methodology: ground-truth timestamp is the time anchor, window is [anchor−5s, anchor+30s], and correlation is the cross-artefact within-window check. Cite in Ch 3 as the primary methodological reference for the window_filter design, alongside Studiawan et al. 2024. Also cite in the discussion of S10 (guest vs host clock skew) because the ~3 min VMware guest drift is exactly the kind of anchor-mismatch problem Vanini et al. warn about, though benign not malicious.

Challenge. Windows 10 evaluation; this dissertation demonstrates on Win11 25H2 that Time-Service EID 37 anchor still fires (S07 A02 Run 3) and Kernel-General EID 16 hive-flush events still function as anchors (S06 A01 sign-out burst). The anchor set generalises.

Quotes.
- "Time anchors are timestamps that resist tampering because they are recorded by trusted subsystems or external sources" (Sec 3).
- "Cross-artefact correlation is the strongest detection strategy against timestamp tampering" (Sec 5).

---

## 22. Marková, Sokol, Krišáková and Kovácová 2024, Dataset of Windows Operating System Forensics Artefacts

Venue: 2024 forensics venue (data article / dataset paper). 14 pages. Filename `WindowsArtifactsDataset_2024.pdf`.

Core claim. Contribution paper. Publishes a dataset of Windows forensic artefacts converted from CTF/training disk images into structured CSV timelines using Plaso/log2timeline, to address the dataset gap Horsman and Lyle 2021 identify.

Method. Testbed construction plus dataset publication. Uses Windows disk images from DFIR Madness "Stolen Szechuan Sauce", Magnet CTF 2019/2020/2022, NIST Data Leakage Case. Plaso for timeline generation, CSV preprocessing, binary attribute transformation. Dataset consists of records from NTFS and Event Logs.

Key findings.
- Dataset provides tabular Windows forensic data.
- Includes event logs and NTFS file-system artefacts.
- Can support automated forensic analysis, ML, evidence-relationship discovery, anomaly detection.
- CTF data is useful but artificial; may not fully reflect real-world incidents.

Borrow. Cite as the closest prior dataset. Position this dissertation's contribution as (a) Win11 25H2 refresh, (b) explicit correlation evaluation (this dissertation's evaluation matrix goes beyond raw artefact publication), (c) narrower artefact scope (three classes) with deeper per-class analysis, (d) controlled ground-truth generation vs CTF-derived data.

Challenge. Grajeda et al. / Marková et al. publish artefacts without correlation. This dissertation's evaluation matrix answers the "what do these artefacts prove" question their dataset leaves open. Also based on CTF/training images, not fully realistic; focuses mainly on NTFS and Event Logs (not ShellBag correlation); data preprocessed for ML.

Quotes.
- "We publish a dataset of Windows artefacts with ground truth timestamps to support reproducible forensic research" (Abstract).

---

## 23. Zhu, James and Gladyshev 2009, Using shellbag information to reconstruct user activities

Venue: DFRWS USA 2009; Digital Investigation 6 Supplement, pages S69 to S77. 9 pages. UCD Centre for Cybercrime Investigation. Peer-reviewed.

Core claim. ShellBags contain evidence of user folder-navigation activity that persists beyond Windows Explorer sessions and beyond deletion of the folder itself. Foundational academic treatment of ShellBag forensics: defines the ShellBag registry layout, catalogues what activities create ShellBag entries, and presents a rule-based reconstruction algorithm using two Registry snapshots (from Windows System Restore Points).

Method. Reverse engineering plus case-study reconstruction. 9 controlled experiments on Windows XP with RegMon monitoring Registry changes. Case study: child-pornography investigation where 16 Registry snapshots were extracted from Windows Restore Points and compared pairwise using the detection rules.

Key findings.
- ShellBag entries live at:
 - `HKEY_USERS\<USERID>\Software\Microsoft\Windows\Shell` (Remote folders)
 - `HKEY_USERS\<USERID>\Software\Microsoft\Windows\ShellNoRoam` (Local folders)
 - Each has two child keys: BagMRU (folders opened) and Bags (display settings).
- BagMRU key mirrors filesystem hierarchy. Each numbered key stores: MRU items (one per sub-folder), MRUListEx (SEQUENCE of MRU items, most recent → least recent), NodeSlot (pointer to display settings in Bags).
- Each MRU item also contains: folder name + creation/modification/last-access times (frozen at the moment the MRU item was first created).
- Three user-action types:
 - Type 1: Only MRU items' position updates. Examples: open folder, delete folder, copy folder, view as thumbnail.
 - Type 2: MRU position + Display key updates. Example: close folder.
 - Type 3: Nothing updates. Examples: create folder, create file, delete file.
- Type 1 and Type 2 leave traces; Type 3 doesn't.
- 9 detection rules (the core contribution) codified for pairwise Registry snapshot comparison.
- Case study result: 2,500 folders on the disk → only 72 had ShellBag info → those 72 are the ones the user definitely accessed. Investigation focus narrows dramatically.
- Key takeaways: closing a folder creates ShellBag info (not opening); deleting a folder doesn't remove its ShellBag info; folder-name reuse causes inheritance, can mislead investigators.
- Tool built: TraceHunter (Windows XP).

Borrow. Founding academic reference for ShellBags. Cite in Ch 2 alongside Lo 2011/2014/2021 SANS (Zhu = theory; Lo = operational). This dissertation's S03 (nested navigation, 5 of 6 direct BagMRU hits), S04 (USB browsing, 3/3 reproducibility for E:\PORTABLE), and S07 (Save As dialog, 3/3 reproducibility for the 7-row Documents+ProgramFiles pattern) all reproduce Zhu et al.'s core claim on Win11 25H2. The 3-action-type framework is directly applicable to this study's correlation rules. Supervisor credibility: Jade co-authored this. MUST cite. Multiple times.

Challenge. Windows XP only; ShellBags-only (this dissertation correlates ShellBags with Prefetch AND Event Logs); relies on Registry snapshots from System Restore Points (which work differently in Win 8/10/11). Zhu et al. treat ShellBags as sufficient for folder-navigation reconstruction; S03 shows opening File Explorer itself (A01) and closing it (A08) are invisible to ShellBags. The scope caveat matters.

Quotes.
- "ShellBag information is available only for folders that have been opened and closed in Windows Explorer at least once" (Section 3, referenced by Lo 2014 as well).
- "ShellBag entries persist after the folder is deleted, enabling reconstruction of historical folder access" (Section 4).

---

## Cross-corpus synthesis (for Ch 2 chapter framing)

The 23 papers cluster into six themes that map onto the LR chapter structure:

1. **Architecture and motivation for cross-artefact correlation** (Hashim and Sutherland 2011; Case et al. 2008; Kondapally 2016; Rawat et al. 2025 Digital Stratigraphy). The intellectual antecedent for treating Prefetch + EVTX + ShellBags as one triangulated evidential surface.

2. **Systematisation and taxonomy** (Studiawan et al. 2019; Breitinger et al. 2025 SoK). The two survey papers that define the vocabulary, the method taxonomy, and the open challenges. Breitinger et al. 2025 is the single most important paper in the corpus.

3. **Per-artefact deep-dive references** (Zhu et al. 2009 and Lo 2014 for ShellBags; Do et al. 2014 and Ibrahim et al. 2011 for EVTX; Duby et al. 2022 and de Zoysa 2025 for Prefetch).

4. **Evaluation and reliability** (Horsman and Lyle 2021 for dataset construction; Nordvik et al. 2021 for tool reliability; Marková et al. 2024 for a comparable dataset paper). Motivates the ground-truth-anchored evaluation matrix.

5. **Timeline reconstruction methods** (Hargreaves and Patterson 2012 for automated temporal-proximity pattern matching; James, Gladyshev and Zhu 2010 for signature-based detection; Amoruso et al. 2022 for visualisation). Methodological antecedents for the correlation report + correlation table + evaluation matrix pipeline.

6. **Anti-forensics and tamper resistance** (Palmbach and Breitinger 2020 for NTFS timestamp forgery detection; Oh 2025 for ML-based `$UsnJrnl` analysis; Vanini et al. 2024 for time anchors; Studiawan et al. 2024 for tamper-resistance scoring; Prakash 2026 for anti-forensics review). The scope-limitation cluster: this dissertation excludes anti-forensics per Jade's 6 Aug decision, but the discussion chapter should reference these papers to defend the exclusion and to position the correlation-lift metric as an implicit tamper-resistance measure.

## Citation quick-reference table (for BibTeX seeding)

| Short cite | Authors | Year | Title (short) | Venue |
|---|---|---|---|---|
| Amoruso2022 | Amoruso, Cinque, Danese, Losavio | 2022 | SeeShells | MetroXRAINE |
| Breitinger2025 | Breitinger, Studiawan, Hargreaves | 2025 | SoK Timeline Reconstruction | arXiv 2504.18131 |
| Case2008 | Case, Cristina, Marziale, Richard, Roussev | 2008 | FACE | DFRWS 2008 |
| Rawat2025 | Rawat, Rajawat, Rawat, Rajawat | 2025 | Digital Stratigraphy Framework | Forensic Sciences 5:48 |
| Do2014 | Do, Martini, Looi, Wang, Choo | 2014 | WinEFP | Adv. Digital Forensics X |
| Duby2022 | Duby, Taylor, Bloom, Zhuang | 2022 | Self-Deleting Malware Prefetch | IEEE CCWC 2022 |
| deZoysa2025 | de Zoysa | 2025 | Forensic Analysis of Windows Prefetch | BSc thesis, U. Kelaniya |
| Hargreaves2012 | Hargreaves, Patterson | 2012 | Automated Timeline Reconstruction | DFRWS 2012 |
| Hashim2011 | Hashim, Sutherland | 2011 | Architecture for Windows Artifacts | ICDF2C 2010 |
| Horsman2021 | Horsman, Lyle | 2021 | Dataset Construction Challenges | FSI-DI 38:301264 |
| Ibrahim2012 | Ibrahim, Al-Nemrat, Jahankhani, Bashroush | 2012 | Sufficiency of EventLog | ICGS3 2011 |
| James2010 | James, Gladyshev, Zhu | 2010 | Signature-Based Detection | ICDF2C 2010 |
| Kondapally2016 | Kondapally | 2016 | Windows Artifacts Analysis | TCS whitepaper |
| Palmbach2020 | Palmbach, Breitinger | 2020 | NTFS Timestamp Manipulation Detection | FSI-DI 32:300920 |
| Nordvik2021 | Nordvik, Georges, Toolan, Axelsson | 2021 | Reliability Validation | FSI-DI 37 Supp |
| Prakash2026 | Prakash | 2026 | Anti-Forensics Review | ICFACT 2025 |
| Lo2014 | Lo | 2014 | ShellBag Forensics in Depth | SANS GIAC White Paper |
| Studiawan2019 | Studiawan, Sohel, Payne | 2019 | OS Log Forensics Survey | Digital Investigation 29 |
| Studiawan2024 | Studiawan, Hargreaves, Breitinger | 2024 | Tamper Resistance Reconstruction | 2024 |
| Oh2025 | Oh | 2025 | Timestamp Manipulation Detection | ScienceDirect 2025 |
| Vanini2024 | Vanini, Gruber, Hargreaves, Benenson, Freiling, Breitinger | 2024 | Time Anchors | arXiv 2501.00175 |
| Markova2024 | Marková, Sokol, Krišáková, Kovácová | 2024 | Windows Artifacts Dataset | 2024 |
| Zhu2009 | Zhu, James, Gladyshev | 2009 | ShellBags | DFRWS 2009 |

## How this notes file feeds the writing

These 23 read-and-annotated papers are the input corpus for two products in the dissertation. The first is Chapter 2 (Literature Review), which is written directly against the six-theme synthesis above. Each theme becomes a subsection whose narrative is anchored by the papers listed under it: architecture and motivation, systematisation, per-artefact deep dives, evaluation and reliability, timeline reconstruction methods, and anti-forensics as an explicit scope limitation. The Borrow and Challenge lines under each paper are what earns each citation its place in the chapter (Borrow becomes what the paper contributes to the argument, Challenge becomes the caveat that positions this dissertation's contribution as non-redundant). The second product is the discussion chapter's positioning of the correlation-verdict framework: Zhu et al. 2009 and Lo 2014 anchor the ShellBag scope claims; Do et al. 2014 and Ibrahim et al. 2012 anchor the EVTX interpretation limits; Duby et al. 2022 and de Zoysa 2025 anchor the Prefetch behaviour on Windows 10 and 11; Hargreaves and Patterson 2012 and Amoruso et al. 2022 anchor the timeline-reconstruction lineage; Breitinger et al. 2025 anchors the open-problem framing; and Palmbach and Breitinger 2020, Oh 2025, Vanini et al. 2024, Studiawan et al. 2024 and Prakash 2026 collectively anchor the anti-forensics exclusion.

## What is not in this file

Three deliberate omissions. First, no dissertation-side experimental numbers are re-derived here (verdicts, reproducibility means, per-artefact completeness). Those live in `scripts/evaluation/evaluation_matrix.md` and are cited from Chapter 4 (Results), not from these notes. Second, no BibTeX has been generated: the citation quick-reference table above is the seed list, and the final `.bib` file will be produced from it when the report enters the reference-management phase. Third, no polemic: the Challenge lines under each paper are limitations, not counter-arguments, and they inform the critical-evaluation posture of Chapter 2 without pre-empting the discussion chapter's own critique of this dissertation's methodology.

## Provenance

Author's own reading notes, compiled while working through the primary sources retained under `D:\UOW\SEM3\Ref_Sources\` (main folder plus `NotesnDrafts\`). Each per-paper entry above records venue, page count, method, key findings, borrow rationale and challenge in the same fixed structure so that a later reader can audit the note against the paper without re-reading the paper. Attribution corrections carried through from the initial pass (Palmbach and Breitinger 2020 previously misattributed to Cho 2013 in one entry; Oh 2025 previously misattributed to Studiawan et al. 2024 in one Notion note) have been applied here.
