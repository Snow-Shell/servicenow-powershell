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
    @($FilePatternExclusions | ForEach-Object{"MAKE.zip" -match $_}).contains($true)

    $FilesToInclude = Get-ChildItem -Path $here -Recurse | Where-Object {
        $File=$_;
        !$_.PSIsContainer -and 
            !($PackageFilePatternExclusions | ForEach-Object{$File.Name -match $_}).contains($true)
     }

     # Create temporary folder and copy the files we want into it
     New-Item $here\$ModuleName -ItemType Container -Force | Out-Null
     $FilesToInclude | ForEach-Object {Copy-Item -Path $_.FullName -Destination $here\$ModuleName\$_ -Force}

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
    $ReadmeContent = $ReadmeContent | ForEach-Object {$_-replace "!\[Test Coverage\].+\)", "![Test Coverage](https://img.shields.io/badge/coverage-$CodeCoverage%25-yellowgreen.svg)"}
    Set-Content -Path $TextFilePath -Value $ReadmeContent
}

Function UpdateManifest{
    param(
        [string]$ManifestPath,
        [string]$Version
    )

    Write-Verbose "Updating $ManifestPath to version $Version"
    $ManifestContent = Get-Content $ManifestPath 
    $ManifestContent = $ManifestContent | ForEach-Object{$_ -replace "ModuleVersion = '(\d|\.)+'", "ModuleVersion = '$Version'"}
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
$Here = 'C:\Users\1113193\OneDrive\GitHub\servicenow-powershell'

$Version = "0.1.12"
$ModuleName = "PoshServiceNow"
$PackageName = "$ModuleName-v$($version).zip"

# Perform Pester tests
$CodeCoverage = Join-Path $Here (Join-Path $ModuleName "$($ModuleName).psm1")
$TestResult = Invoke-Pester -Path $Here -CodeCoverage $CodeCoverage -PassThru
$CoveragePercent = 100-(($testResult.CodeCoverage.NumberOfCommandsMissed/$testResult.CodeCoverage.NumberOfCommandsAnalyzed)*100)

# Update/Create the package and 
if($TestResult.FailedCount -eq 0){
    New-MakePackage -PackageFilePatternExclusions $PackageFilePatternExclusions -PackageName $PackageName -ModuleName $ModuleName
    Update-CodeCoveragePercent -CodeCoverage $CoveragePercent
    UpdateManifest -ManifestPath "$here\$ModuleName\$ModuleName.psd1" -Version $Version
}
 