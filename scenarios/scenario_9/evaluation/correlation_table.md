# Scenario 9 correlation table

Scenario: web-browsing session with download (appendix). Chrome launched, three web destinations visited, sample PDF downloaded and opened, Chrome closed, Downloads folder opened. Artefact classes in matrix: Prefetch, EVTX, ShellBags.

Windowed inputs used:
- Prefetch, EVTX, ShellBags: `artefacts/analysis/windowed/`
- Machine-generated evidence dump: `artefacts/analysis/windowed/correlation_report.txt`

**Precondition:** VM reverted to `scenario1_post` snapshot, so Chrome and Adobe Reader are preinstalled from Scenario 1.

Verdict rules and column definitions: see `scripts/evaluation/evaluation_matrix.md`.

## Rows

| Action | GT Time (UTC) | Note | Prefetch evidence | EVTX evidence | ShellBag evidence | Verdict | Analyst notes |
|---|---|---|---|---|---|---|---|
| A01 | 09:03:38 | Launch Chrome from Start | CHROME.EXE runtime x11 across 09:03:45 to 09:03:58; ELEVATION_SERVICE.EXE 09:03:46; DLLHOST.EXE 09:03:45 | Security 4688 x51 (parent svchost.exe reflects protocol-handler chain), 4689 x42, 5379 x4 credential reads, 5058/5061 KeyContainer create (Chrome key material), VSS EID 8224 | no match | CONFIRMED | Prefetch cluster of chrome.exe plus elevation_service.exe with matching Security 4688 burst independently attribute the Chrome launch. Chrome's multi-process architecture reliably produces this fingerprint. |
| A02 | 09:04:39 | Navigate to UoW website | CHROME.EXE x5 (helper spawns for the new navigation); TASKHOSTW.EXE (background) | Security 4688 x80 with parent services.exe, 4689 x74, CAPI2 EID 4097 naming CN=GlobalSign Root CA R3 (the westminster.ac.uk TLS chain) | no match | CONFIRMED | CAPI2 4097 identifies the TLS certificate chain for the UoW navigation (GlobalSign is UoW's issuer), and Prefetch of chrome.exe helper spawns corroborates browser activity in the window. Two classes attribute. |
| A03 | 09:06:05 | Navigate to bbc and open first headline | SEARCHPROTOCOLHOST.EXE 09:06:46 (Windows Search indexing browser data) | Security 4688 x55, 4689 x52 (Chrome helper-process churn) | no match | PARTIAL | Chrome helper-process churn is consistent with active browsing but does not identify the destination. No CAPI2 event fired for bbc.co.uk in this window (the TLS session was already validated in-memory from a prior visit or the OS cache). Single-class attribution. |
| A04 | 09:08:06 | Open Wikipedia digital forensics article and scroll | COMPATTELRUNNER, COMPPKGSRV, DLLHOST, MICROSOFTEDGEUPDATE x3, MOUSOCOREWORKER, SOFTLANDINGTASK x2, SVCHOST x3, TRUSTEDINSTALLER (mostly background OS activity) | Security 4688 x63 with parent chrome.exe, 4689 x43, 4624 SYSTEM logon x7, WER EID 1001 Application Crash x1 (a Chrome helper crashed during the scroll session) | no match | PARTIAL | Chrome-parented 4688 events attribute browser activity in the window but not the specific Wikipedia navigation; the WER 1001 crash is an incidental finding. Prefetch entries are OS background noise. Single-class weak attribution. |
| A05 | 09:11:32 | Download a sample PDF from File Examples | ACROBAT.EXE x7 across 09:12:04 to 09:12:38; ACROCEF.EXE x3; ADNOTIFICATIONMANAGER 09:12:19; ADOBEARM 09:12:18; CHROME.EXE x4 (helper spawns for the download); MSEDGEWEBVIEW2 x3 (Adobe's embedded Edge for PDF rendering); SEARCHFILTERHOST.EXE (Windows Search indexing the PDF) | Security 4688 x41 with parent chrome.exe (Adobe reader spawned by Chrome as external handler for the PDF), 4689 x21, 4696 process-integrity change x3, DistributedCOM 10016 x4 | no match | CONFIRMED | The launch of Acrobat.exe and its supporting AcroCEF and MSEdgeWebView2 processes shortly after the download second is direct evidence the PDF was saved and opened; Chrome-parented 4688 events attribute the download itself. Two artefact classes with strong specific attribution. |
| A06 | 09:12:58 | Close Chrome | UPDATER.EXE x4 at 09:13:03 (Chrome Updater fires on Chrome exit to check for updates) | Security 4689 x27 exit burst (Chrome helper-process teardown), 4688 x6, 5379 x1 | no match | CONFIRMED | 27-process exit burst is a definitive Chrome-shutdown signature (Chrome's process-per-tab architecture produces the largest 4689 burst per second on the system when it exits), and the Chrome Updater firing on exit is a documented on-exit hook. Two artefact classes concur. |
| A07 | 09:13:40 | Open Downloads using File Explorer | BACKGROUNDTASKHOST 09:13:43; FILECOAUTH.EXE 09:13:47; RUNDLL32.EXE 09:13:47 (Explorer namespace); DLLHOST 09:13:46; MSEDGEWEBVIEW2 09:13:49 | Security 4688 x5 with parent svchost.exe, 4689 x5, 4663 x4 object access on Downloads folder | UsrClass BagMRU at 09:13:47: `Desktop\Win11 21H2`, `Desktop\This PC`, `Desktop\Desktop`, `Desktop\Downloads` | CONFIRMED | ShellBag directly attributes the navigation to Desktop\Downloads with per-folder LastInteracted timestamp; EVTX 4663 object-access events on the Downloads path corroborate. Two artefact classes with direct attribution. |
| A08 | 09:14:53 | Close File Explorer | no match | Security 4689 exits only (thin) | no match | MISSED | Closing a File Explorer window while explorer.exe remains the shell produces no distinctive trace; same pattern as Scenario 3 A08. |

## Coverage summary

- CONFIRMED: 5 of 8 (A01, A02, A05, A06, A07)
- PARTIAL: 2 of 8 (A03, A04)
- MISSED: 1 of 8 (A08)
- Per-class hits: Prefetch 7 of 8 (strong for A01/A05/A06/A07), EVTX 8 of 8 (distinctive attribution for A01/A02/A05/A06/A07), ShellBags 1 of 8 (A07 only)

## Interpretive observations

1. This scenario is the study's strongest cross-artefact demonstration of a "browse plus download plus open" chain: A05 (download PDF) is attributed by the Acrobat.exe and AcroCEF.exe Prefetch cluster firing seconds after the download, plus Chrome-parented Security 4688 events for the download itself. This is the clearest example of provenance across artefact classes.
2. CAPI2 EID 4097 continues to be the only per-destination attribution signal for browser navigation, and only for the first TLS handshake to a host (subsequent visits reuse cached chains). This limits its usefulness for correlating a browsing timeline; only first-visits are attributable via certificate issuer.
3. The Chrome shutdown signature (A06) reproduces the pattern from Scenario 1 A08 (Edge close): a large 4689 exit burst plus the browser's own updater firing on exit is a reliable browser-close fingerprint that generalises across Chrome and Edge.
