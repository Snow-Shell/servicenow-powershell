$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$modulePath = (Join-Path $moduleRoot "$moduleName.psd1")

Write-Host "projectRoot:  $projectRoot" -f cyan
Write-Host "moduleRoot:  $moduleRoot" -f cyan
Write-Host "moduleName:  $moduleName" -f cyan
Write-Host "ModulePath:  $ModulePath" -f cyan

$script:manifestModuleName = $moduleName
$script:manifestFunctionsToExport = (Import-PowerShellDataFile -Path $modulePath).FunctionsToExport

Describe "Generic Module Tests" -Tag UnitTest,Build {
    BeforeAll {
        # recompute paths locally - Pester's Run phase does not share scope with
        # top-level script code, which only executes during Discovery
        $projectRoot = Resolve-Path "$PSScriptRoot\.."
        $moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
        $moduleName = Split-Path $moduleRoot -Leaf
        $modulePath = Join-Path $moduleRoot "$moduleName.psd1"

        # Unload the module so it's loaded fresh for testing
        Remove-Module $moduleName -ErrorAction SilentlyContinue

        # Import Module
        $ModuleInformation = Import-Module $modulePath -Force -PassThru
    }

    It "Module imported successfully" {
        $ModuleInformation.Name | Should -Be $moduleName
    }

    # Evaluate AliasesToExport
    # Context AliasesToExport {
    #     $AliasesToExportString = $ModuleManifestContent | Where-Object {$_ -match 'AliasesToExport'}
    #     $DeclaredAliases = $AliasesToExportString.Split(',') |
    #         ForEach-Object{If ($_ -match '\w+-\w+'){$Matches[0]}}

    #     It "AliasesToExport should not be a wildcard" {
    #         $AliasesToExportString | Should -Not -Match "\'\*\'"
    #     }

    #     $ExportedAliases = $ModuleInformation.ExportedAliases.Values.Name
    #     ForEach ($Alias in $DeclaredAliases) {
    #         It "Alias Should -Be Available $Alias " {
    #             $ExportedAliases -contains $Alias | Should -Be $True
    #         }
    #     }
    # }

    # Evaluate FunctionsToExport
    Context FunctionsToExport {
        It "FunctionsToExport should not be a wildcard" {
            $script:manifestFunctionsToExport | Should -Not -Contain '*'
        }

        It "Function  Available: <_> " -ForEach $script:manifestFunctionsToExport {
            # use Pester's -ForEach (rather than a plain foreach loop) to generate these
            # dynamic tests - a plain foreach loop variable isn't reliably captured across
            # Pester's Discovery/Run phase boundary and every test ends up seeing the same
            # (final or null) value
            Get-Command -Module $script:manifestModuleName -Name $_ -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    # Other Manifest Properties
    Context 'Other Manifest Properties' {
        It "RootModule property has value"{
            $ModuleInformation.RootModule | Should -Not -BeNullOrEmpty
        }
        It "Author property has value"{
            $ModuleInformation.Author | Should -Not -BeNullOrEmpty
        }
        It "Company Name property has value"{
            $ModuleInformation.CompanyName | Should -Not -BeNullOrEmpty
        }
        It "Description property has value"{
            $ModuleInformation.Description | Should -Not -BeNullOrEmpty
        }
        It "Copyright property has value"{
            $ModuleInformation.Copyright | Should -Not -BeNullOrEmpty
        }
        It "License property has value"{
            $ModuleInformation.LicenseURI | Should -Not -BeNullOrEmpty
        }
        It "Project Link property has value"{
            $ModuleInformation.ProjectURI | Should -Not -BeNullOrEmpty
        }
        It "Tags (For the PSGallery) property has value"{
            $ModuleInformation.Tags.count | Should -Not -BeNullOrEmpty
        }
        It "PSGallery Tags Should Not Contain Spaces" {
            ForEach ($Tag in $ModuleInformation.PrivateData.Values.Tags) {
                $Tag | Should -Not -Match '\s'
            }
        }
    }
}
