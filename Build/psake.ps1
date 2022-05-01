# PSake makes variables declared here available in other scriptblocks
Properties {
    # Find the build folder based on build system
    $ProjectRoot = Resolve-Path $Env:BHProjectPath
    if (-not $ProjectRoot) {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
    }

    $StepVersionBy = $null

    $Timestamp = Get-Date -UFormat '%Y%m%d-%H%M%S'
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $Lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if ($Env:BHCommitMessage -match '!verbose') {
        $Verbose = @{Verbose = $True }
    }
}

Task default -Depends Deploy

# Init some things
Task Init {
    $Lines
    Set-Location $ProjectRoot
    'Build System Details:'
    Get-Item ENV:BH* | Format-List
    "`n"
}

Task Analyze -Depends Init {
    $SAResults = Invoke-ScriptAnalyzer -Path $Env:BHModulePath -Severity @('Error', 'Warning') -Recurse -Verbose:$false
    if ($SAResults) {
        $SAResults | Format-Table
        # Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

Task UnitTests -Depends Init {
    $Lines
    'Running quick unit tests to fail early if there is an error'
    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests\*unit* -PassThru -Tag Build

    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Test -Depends UnitTests {
    $Lines
    "`nSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $TestFilePath = Join-Path $ProjectRoot $TestFile
    $CodeFiles = Get-ChildItem $Env:BHModulePath -Recurse -Include '*.psm1', '*.ps1'
    $CodeCoverage = New-Object System.Collections.ArrayList
    $CodeCoverage.AddRange($CodeFiles.FullName)
    $Credential = Get-Credential
    $InvokePesterScript = @{
        Path       = "$ProjectRoot\Tests"
        Parameters = @{
            Credential = $Credential
        }
    }
    $InvokePesterSplat = @{
        Script       = $InvokePesterScript
        CodeCoverage = $CodeCoverage
        OutputFile   = $TestFilePath
        OutputFormat = 'NUnitXml'
        PassThru     = $true
    }
    $Script:TestResults = Invoke-Pester @InvokePesterSplat

    [xml]$Content = Get-Content $TestFilePath
    $Content.'test-results'.'test-suite'.type = 'Powershell'
    $Content.Save($TestFilePath)

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    if ($Env:BHBuildSystem -eq 'AppVeyor') {
        "Uploading $ProjectRoot\$TestFile to AppVeyor"
        "JobID: $Env:APPVEYOR_JOB_ID"
        (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($Env:APPVEYOR_JOB_ID)", (Resolve-Path $TestFilePath))
    }

    Remove-Item $TestFilePath -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends Test {
    $Lines

    $Functions = Get-ChildItem "$Env:BHModulePath\Public\*.ps1" |
    Where-Object { $_.name -notmatch 'Tests' } |
    Select-Object -ExpandProperty basename

    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    Set-ModuleFunctions -Name $env:BHPSModuleManifest -FunctionsToExport $Functions

    # Bump the module version
    $StepVersionSplat = @{
        Version = (Get-Metadata -Path $env:BHPSModuleManifest)
    }
    if ($null -ne $StepVersionBy) {
        $StepVersionSplat.Add('By', $StepVersionBy)
    }
    $Version = [version](Step-Version @StepVersionSplat)
    $GalleryVersion = Get-NextPSGalleryVersion -Name $env:BHProjectName
    if ($Version -lt $GalleryVersion) {
        $Version = $GalleryVersion
    }
    $script:Version = [version]::New($Version.Major, $Version.Minor, $Version.Build)
    Write-Host "Using version: $Version"

    Update-Metadata -Path $Env:BHPSModuleManifest -PropertyName ModuleVersion -Value $Version

    # Update Code Coverage
    function Update-CodeCoveragePercent {
        param(
            [int] $CodeCoverage = 0,
            [string] $TextFilePath = "$Env:BHProjectPath\Readme.md"
        )

        $BadgeColor = switch ($CodeCoverage) {
            100 { 'brightgreen' }
            { 95..99 -contains $_ } { 'green' }
            { 85..94 -contains $_ } { 'yellowgreengreen' }
            { 75..84 -contains $_ } { 'yellow' }
            { 65..74 -contains $_ } { 'orange' }
            default { 'red' }
        }

        $ReadmeContent = Get-Content $TextFilePath
        $ReadmeContent = $ReadmeContent | ForEach-Object { $_ -replace '!\[Test Coverage\].+\)', "![Test Coverage](https://img.shields.io/badge/coverage-$CodeCoverage%25-$BadgeColor.svg)" }
        Set-Content -Path $TextFilePath -Value $ReadmeContent
    }

    $CoveragePercent = 100 - (($script:TestResults.CodeCoverage.NumberOfCommandsMissed / $script:TestResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    "Running Update-CodeCoveragePercent with percentage $CoveragePercent"
    Update-CodeCoveragePercent -CodeCoverage $CoveragePercent
    "`n"
}

Task MakePackage -Depends Build, Test {
    $Lines

    function ZipFiles {
        param( 
            $ZipFileName, 
            $SourceDir 
        )
        Add-Type -Assembly System.IO.Compression.FileSystem
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir,
            $ZipFileName, $CompressionLevel, $true)
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
    $PackageName = "$($Env:BHProjectName)-v$($script:Version).zip"
    "Creating package $PackageName"
    New-MakePackage -PackageName $PackageName -PackagePath $ProjectRoot -ModuleName $Env:BHModulePath

    "`n"
}

Task Deploy -Depends Build, MakePackage {
    $Lines

    # Gate deployment
    if ($Env:BHBuildSystem -ne 'Unknown' -and $Env:BHBranchName -eq 'master' -and $Env:BHCommitMessage -match '!deploy') {
        $Params = @{
            Path  = $ProjectRoot
            Force = $true
        }

        Invoke-PSDeploy @Verbose @Params
    } else {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* You are in a known build system (Current: $Env:BHBuildSystem)`n" +
        "`t* You are committing to the master branch (Current: $Env:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $Env:BHCommitMessage)"
    }
}
