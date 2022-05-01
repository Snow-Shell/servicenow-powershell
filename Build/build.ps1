<#
.Description
    Installs and loads all the required modules for the build.
.Author
    Warren F. (RamblingCookieMonster)
#>

[CmdletBinding()]

param (
    $Task = 'Default',

    [ValidateSet('Build', 'Minor', 'Major')]
    $StepVersionBy = 'Build'
)

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

$Modules = @('Psake', 'PSDeploy', 'BuildHelpers', 'PSScriptAnalyzer', 'Pester')

foreach ($Module in $Modules) {
    if (-not (Get-Module -Name $Module -ListAvailable)) {
        switch ($Module) {
            Pester { Install-Module $Module -Force -SkipPublisherCheck }
            default { Install-Module $Module -Force }
        }
    }
    Import-Module $Module
}

$Path = (Resolve-Path $PSScriptRoot\..).Path
Set-BuildEnvironment -Path $Path -Force

$InvokepsakeSplat = @{
    buildFile  = "$PSScriptRoot\psake.ps1"
    taskList   = $Task
    properties = @{'StepVersionBy' = $StepVersionBy }
    nologo     = $true
}
Invoke-psake @InvokepsakeSplat

exit ([int](-not $psake.build_success))
