<#
    Install the host-side parsers used by the dissertation.

    This script never runs inside the evidence VM. It downloads the three
    required command-line tools from Eric Zimmerman's official distribution
    site, extracts them with 7-Zip, verifies their Authenticode signatures,
    and records hashes and versions for reproducibility.

    Run in an elevated host PowerShell:
        powershell.exe -ExecutionPolicy Bypass -File .\01-install-host-parsers-HOST.ps1
#>

[CmdletBinding()]
param(
    [string]$DestinationRoot = 'C:\ForensicTools',

    [ValidateSet(4, 9)]
    [int]$NetVersion = 9,

    [string]$ManifestPath = 'D:\UOW\SEM3\msc-diss-7csef001w\testbed\evidence\Host-Parser-Manifest.csv'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sevenZip = 'C:\Program Files\7-Zip\7z.exe'
if (-not (Test-Path -LiteralPath $sevenZip -PathType Leaf)) {
    throw "7-Zip is required at $sevenZip. Install 7-Zip before continuing."
}

if ($NetVersion -eq 9) {
    $dotnet = Get-Command dotnet.exe -ErrorAction SilentlyContinue
    if (-not $dotnet) {
        throw 'The .NET 9 runtime is not available. Install it or rerun with -NetVersion 4.'
    }

    $hasNet9 = & $dotnet.Source --list-runtimes | Where-Object { $_ -match '^Microsoft\.NETCore\.App 9\.' }
    if (-not $hasNet9) {
        throw 'The .NET 9 runtime is not available. Install it or rerun with -NetVersion 4.'
    }
}

$tools = @(
    [pscustomobject]@{ Name = 'PECmd';    Exe = 'PECmd.exe' },
    [pscustomobject]@{ Name = 'EvtxECmd'; Exe = 'EvtxECmd.exe' },
    [pscustomobject]@{ Name = 'SBECmd';   Exe = 'SBECmd.exe' }
)

[System.IO.Directory]::CreateDirectory($DestinationRoot) | Out-Null
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("DISS-EZTools-{0}" -f [guid]::NewGuid())
[System.IO.Directory]::CreateDirectory($tempRoot) | Out-Null

$manifestRows = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($tool in $tools) {
        $toolDirectory = Join-Path $DestinationRoot $tool.Name
        if (Test-Path -LiteralPath $toolDirectory) {
            $existingItems = @(Get-ChildItem -LiteralPath $toolDirectory -Force -ErrorAction SilentlyContinue)
            if ($existingItems.Count -gt 0) {
                throw "Refusing to overwrite the non-empty tool directory: $toolDirectory"
            }
        }
        else {
            [System.IO.Directory]::CreateDirectory($toolDirectory) | Out-Null
        }

        $archive = Join-Path $tempRoot ("{0}.zip" -f $tool.Name)
        $url = "https://download.ericzimmermanstools.com/net$NetVersion/$($tool.Name).zip"

        Write-Host "Downloading $($tool.Name) from the official distribution site" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
        $archiveHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash

        Write-Host "Extracting $($tool.Name) with 7-Zip" -ForegroundColor Cyan
        & $sevenZip x $archive "-o$toolDirectory" -y | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "7-Zip failed while extracting $archive (exit code $LASTEXITCODE)."
        }

        $executable = Get-ChildItem -LiteralPath $toolDirectory -Recurse -File -Filter $tool.Exe |
            Select-Object -First 1
        if (-not $executable) {
            throw "The expected executable $($tool.Exe) was not found after extraction."
        }

        $signature = Get-AuthenticodeSignature -LiteralPath $executable.FullName
        if ($signature.Status -ne 'Valid') {
            throw "Authenticode verification failed for $($executable.FullName): $($signature.Status)"
        }

        $exeHash = (Get-FileHash -LiteralPath $executable.FullName -Algorithm SHA256).Hash
        $version = $executable.VersionInfo.FileVersion

        $manifestRows.Add([pscustomobject]@{
            CapturedUtc       = [DateTime]::UtcNow.ToString('o')
            Tool              = $tool.Name
            FileVersion       = $version
            FrameworkBuild    = "net$NetVersion"
            DownloadUrl       = $url
            ArchiveSHA256     = $archiveHash
            ExecutablePath    = $executable.FullName
            ExecutableSHA256  = $exeHash
            SignatureStatus   = $signature.Status.ToString()
            SignerSubject     = $signature.SignerCertificate.Subject
        })
    }

    $manifestDirectory = Split-Path -Parent $ManifestPath
    [System.IO.Directory]::CreateDirectory($manifestDirectory) | Out-Null
    $manifestRows | Export-Csv -LiteralPath $ManifestPath -NoTypeInformation -Encoding utf8

    Write-Host ''
    Write-Host 'Host parser installation complete.' -ForegroundColor Green
    $manifestRows | Format-Table Tool, FileVersion, FrameworkBuild, SignatureStatus, ExecutablePath -AutoSize
    Write-Host "Manifest: $ManifestPath"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
