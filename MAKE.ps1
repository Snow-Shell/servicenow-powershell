function ZipFiles
{
    param( $zipfilename, $sourcedir )
    Add-Type -Assembly System.IO.Compression.FileSystem 
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
        $zipfilename, $compressionLevel, $true) 
}

function New-MakePackage{
    param(
        [string[]]$PackageFilePatternExclusions,
        [string]$PackageName,
        [string]$ModuleName
    )
    @($FilePatternExclusions | %{"MAKE.zip" -match $_}).contains($true)

    $FilesToInclude = Get-ChildItem -Path $here | ?{
        $File=$_;
        !$_.PSIsContainer -and 
            !($PackageFilePatternExclusions | %{$File.Name -match $_}).contains($true)
     }

     # Create temporary folder and copy the files we want into it
     New-Item $here\$ModuleName -ItemType Container -Force | Out-Null
     $FilesToInclude | %{Copy-Item -Path $_.FullName -Destination $here\$ModuleName\$_ -Force}

     # Create a zip based on that folder (overwriting it if it already exists)
     $ZipFile = "$here\$PackageName"
     Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue | Out-Null
     ZipFiles $ZipFile $here\$ModuleName
     Remove-Item $here\$ModuleName -Recurse| Out-Null
}

Function Update-CodeCoveragePercent{
    param(
        [int]$CodeCoverage=0,
        [string]$TextFilePath="$here\Readme.md"
    )
    $ReadmeContent = Get-Content $TextFilePath
    $ReadmeContent = $ReadmeContent | %{$_-replace "!\[Test Coverage\].+\)", "![Test Coverage](https://img.shields.io/badge/coverage-$CodeCoverage%25-yellowgreen.svg)"}
    Set-Content -Path $TextFilePath -Value $ReadmeContent
}

Function UpdateManifest{
    param(
        [string]$ManifestPath,
        [string]$Version
    )

    Write-Verbose "Updating $ManifestPath to version $Version"
    $ManifestContent = Get-Content $ManifestPath 
    $ManifestContent = $ManifestContent | %{$_ -replace "ModuleVersion = '(\d|\.)+'", "ModuleVersion = '$Version'"}
    Set-Content -path $ManifestPath -Value $ManifestContent
}

$PackageFilePatternExclusions = @(
    "MAKE\.ps1",
    ".+\.zip",
    ".+\.md"
    ".+\.Tests\.ps1",
    "\.gitignore",
    "LICENSE",
    ".+\.Pester.Defaults.json"
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$Version = "0.1.12"
$ModuleName = "PSServiceNow"
$PackageName = "$ModuleName-v$($version).zip";

# Perform Pester tests
$TestResult = Invoke-Pester -CodeCoverage '*.psm1' -PassThru
$CoveragePercent = 100-(($testResult.CodeCoverage.NumberOfCommandsMissed/$testResult.CodeCoverage.NumberOfCommandsAnalyzed)*100)

# Update/Create the package and 
if($TestResult.FailedCount -eq 0){
    New-MakePackage -PackageFilePatternExclusions $PackageFilePatternExclusions -PackageName $PackageName -ModuleName $ModuleName
    Update-CodeCoveragePercent -CodeCoverage $CoveragePercent
    UpdateManifest -ManifestPath "$here\$ModuleName.psd1" -Version $Version
}
 