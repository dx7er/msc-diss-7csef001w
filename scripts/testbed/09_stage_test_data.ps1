<#
    Step 9 - Stage synthetic test data
    Testbed: TB-W11-25H2-01

    Purpose:
        Create all scenario folder structures BEFORE the candidate
        baseline snapshot using PowerShell (never Explorer). Explorer
        navigation creates ShellBag entries and would contaminate the
        experiment before it starts.

        The BROWSED path will be navigated during pilots. The UNBROWSED
        path is a negative control - it must never be opened in Explorer.

    Run:
        Open PowerShell as Administrator inside the guest VM and execute:
            powershell.exe -ExecutionPolicy Bypass -File .\09-stage-test-data.ps1

    Output:
        C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9\ALPHA\BRAVO\CHARLIE\
        C:\DISS_TESTDATA\PILOT\P00R01_UNBROWSED_Q4M2\ALPHA\BRAVO\CHARLIE\
        Synthetic files at each level with unique tokens
        C:\DISS_Config\Test-Data-Manifest.txt
#>

$ErrorActionPreference = 'Continue'
$config = 'C:\DISS_Config'
New-Item -ItemType Directory -Path $config -Force | Out-Null

$browsedRoot   = 'C:\DISS_TESTDATA\PILOT\P00R01_BROWSED_A7K9'
$unbrowsedRoot = 'C:\DISS_TESTDATA\PILOT\P00R01_UNBROWSED_Q4M2'

Write-Host "[Step 9] Creating BROWSED folder tree (will be navigated in pilot)" -ForegroundColor Cyan
New-Item -ItemType Directory -Force "$browsedRoot\ALPHA\BRAVO\CHARLIE" | Out-Null

Write-Host "[Step 9] Creating UNBROWSED folder tree (negative control - never open in Explorer)" -ForegroundColor Cyan
New-Item -ItemType Directory -Force "$unbrowsedRoot\ALPHA\BRAVO\CHARLIE" | Out-Null

Write-Host "[Step 9] Placing synthetic files with unique tokens" -ForegroundColor Cyan
$browsedFiles = @(
    "$browsedRoot\S01_ProjectNotes_A7K9.txt",
    "$browsedRoot\ALPHA\S01_ProjectNotes_A7K9_a.txt",
    "$browsedRoot\ALPHA\BRAVO\S01_ProjectNotes_A7K9_b.txt",
    "$browsedRoot\ALPHA\BRAVO\CHARLIE\S01_ProjectNotes_A7K9_c.txt"
)
foreach ($f in $browsedFiles) {
    "Synthetic test content for MSc dissertation TB-W11-25H2-01, path: $f, token: A7K9" |
        Out-File -FilePath $f -Encoding utf8
}

$unbrowsedFiles = @(
    "$unbrowsedRoot\S01_UNBROWSED_Q4M2.txt",
    "$unbrowsedRoot\ALPHA\S01_UNBROWSED_Q4M2_a.txt",
    "$unbrowsedRoot\ALPHA\BRAVO\S01_UNBROWSED_Q4M2_b.txt",
    "$unbrowsedRoot\ALPHA\BRAVO\CHARLIE\S01_UNBROWSED_Q4M2_c.txt"
)
foreach ($f in $unbrowsedFiles) {
    "Synthetic negative-control content, path: $f, token: Q4M2, MUST NOT be browsed" |
        Out-File -FilePath $f -Encoding utf8
}

Write-Host "[Step 9] Writing test data manifest" -ForegroundColor Cyan
$manifest = Join-Path $config 'Test-Data-Manifest.txt'
"=== Test data manifest ==="              | Out-File $manifest -Encoding utf8
"Created UTC : $([DateTime]::UtcNow.ToString('o'))" | Out-File $manifest -Append -Encoding utf8
""                                         | Out-File $manifest -Append -Encoding utf8
"=== Browsed (positive) tree ==="          | Out-File $manifest -Append -Encoding utf8
Get-ChildItem $browsedRoot -Recurse -File |
    Select-Object FullName, Length, LastWriteTimeUtc |
    Format-Table -AutoSize -Wrap |
    Out-File $manifest -Append -Encoding utf8
""                                         | Out-File $manifest -Append -Encoding utf8
"=== Unbrowsed (negative) tree ==="        | Out-File $manifest -Append -Encoding utf8
Get-ChildItem $unbrowsedRoot -Recurse -File |
    Select-Object FullName, Length, LastWriteTimeUtc |
    Format-Table -AutoSize -Wrap |
    Out-File $manifest -Append -Encoding utf8

Get-Content $manifest

Write-Host ""
Write-Host "[Step 9] Complete." -ForegroundColor Green
Write-Host "  IMPORTANT: Do NOT open $unbrowsedRoot in File Explorer at any point." -ForegroundColor Yellow
Write-Host "             ShellBag entries only appear if a folder is browsed in Explorer." -ForegroundColor Yellow
