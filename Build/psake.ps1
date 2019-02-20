# PSake makes variables declared here available in other scriptblocks
Properties {
    # Find the build folder based on build system
    $ProjectRoot = Resolve-Path $ENV:BHProjectPath
    if(-not $ProjectRoot)
    {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
    }

    $StepVersionBy = $null

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if ($ENV:BHCommitMessage -match "!verbose") {
        $Verbose = @{Verbose = $True}
    }
}

Task Default -Depends Deploy

# Init some things
Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH* | Format-List
    "`n"
}

Task Analyze -Depends Init {
    $saResults = Invoke-ScriptAnalyzer -Path $ENV:BHModulePath -Severity @('Error', 'Warning') -Recurse -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table
        # Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

Task UnitTests -Depends Init {
    $lines
    'Running quick unit tests to fail early if there is an error'
    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests\*unit* -PassThru -Tag Build

    if($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Test -Depends UnitTests  {
    $lines
    "`nSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $TestFilePath = Join-Path $ProjectRoot $TestFile
    $CodeFiles = Get-ChildItem $ENV:BHModulePath -Recurse -Include "*.psm1","*.ps1"
    $CodeCoverage = New-Object System.Collections.ArrayList
    $CodeCoverage.AddRange($CodeFiles.FullName)
    $Credential = Get-Credential
    $invokePesterScript = @{
        Path       = "$ProjectRoot\Tests"
        Parameters = @{
            Credential = $Credential
        }
    }
    $invokePesterSplat = @{
        Script       = $invokePesterScript
        CodeCoverage = $CodeCoverage
        OutputFile   = $TestFilePath
        OutputFormat = 'NUnitXml'
        PassThru     = $true
    }
    $Script:TestResults = Invoke-Pester @invokePesterSplat

    [xml]$content = Get-Content $TestFilePath
    $content.'test-results'.'test-suite'.type = "Powershell"
    $content.Save($TestFilePath)

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    If($ENV:BHBuildSystem -eq 'AppVeyor') {
        "Uploading $ProjectRoot\$TestFile to AppVeyor"
        "JobID: $env:APPVEYOR_JOB_ID"
        (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $TestFilePath))
    }

    Remove-Item $TestFilePath -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends Test {
    $lines

    $functions = Get-ChildItem "$ENV:BHModulePath\Public\*.ps1" |
        Where-Object {$_.name -notmatch 'Tests'} |
        Select-Object -ExpandProperty basename

    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    Set-ModuleFunctions -Name $env:BHPSModuleManifest -FunctionsToExport $functions

    # Bump the module version
    $stepVersionSplat = @{
        Version = (Get-Metadata -Path $env:BHPSModuleManifest)
    }
    If ($null -ne $StepVersionBy) {
        $stepVersionSplat.Add('By',$StepVersionBy)
    }
    $version = [version](Step-Version @stepVersionSplat)
    $galleryVersion = Get-NextPSGalleryVersion -Name $env:BHProjectName
    if($version -lt $galleryVersion)
    {
        $version = $galleryVersion
    }
    $Script:version = [version]::New($version.Major,$version.Minor,$version.Build)
    Write-Host "Using version: $version"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $version

    # Update Code Coverage
    Function Update-CodeCoveragePercent {
        param(
            [int]$CodeCoverage=0,
            [string]$TextFilePath="$Env:BHProjectPath\Readme.md"
        )

        $BadgeColor = Switch ($CodeCoverage) {
            100                     {"brightgreen"}
            {95..99 -contains $_}   {"green"}
            {85..94 -contains $_}   {"yellowgreengreen"}
            {75..84 -contains $_}   {"yellow"}
            {65..74 -contains $_}   {"orange"}
            default                 {"red"}
        }

        $ReadmeContent = Get-Content $TextFilePath
        $ReadmeContent = $ReadmeContent | ForEach-Object {$_-replace "!\[Test Coverage\].+\)", "![Test Coverage](https://img.shields.io/badge/coverage-$CodeCoverage%25-$BadgeColor.svg)"}
        Set-Content -Path $TextFilePath -Value $ReadmeContent
    }

    $CoveragePercent = 100-(($Script:TestResults.CodeCoverage.NumberOfCommandsMissed/$Script:TestResults.CodeCoverage.NumberOfCommandsAnalyzed)*100)
    "Running Update-CodeCoveragePercent with percentage $CoveragePercent"
    Update-CodeCoveragePercent -CodeCoverage $CoveragePercent
    "`n"
}

Task MakePackage -Depends Build,Test {
    $lines

    function ZipFiles {
        param( $zipfilename, $sourcedir )
        Add-Type -Assembly System.IO.Compression.FileSystem
        $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
            $zipfilename, $compressionLevel, $true)
    }

    function New-MakePackage {
        param(
            [string]$PackageName,
            [string]$PackagePath,
            [string]$ModuleName
        )

        $ZipFile = "$PackagePath\$PackageName"
        Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue | Out-Null
        ZipFiles $ZipFile $ModuleName
    }

    # Update/Create the package
    $PackageName = "$($Env:BHProjectName)-v$($Script:version).zip"
    "Creating package $PackageName"
    New-MakePackage -PackageName $PackageName -PackagePath $ProjectRoot -ModuleName $ENV:BHModulePath

    "`n"
}

Task Deploy -Depends Build,MakePackage {
    $lines

    # Gate deployment
    if (
        $ENV:BHBuildSystem -ne 'Unknown' -and
        $ENV:BHBranchName -eq "master" -and
        $ENV:BHCommitMessage -match '!deploy'
    ) {
        $Params = @{
            Path = $ProjectRoot
            Force = $true
        }

        Invoke-PSDeploy @Verbose @Params
    } else {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
        "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)"
    }
}
