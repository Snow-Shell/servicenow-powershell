$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psd1")
$ModuleName = Split-Path $ModuleRoot -Leaf
$ModulePath = (Join-Path $ModuleRoot "$ModuleName.psd1")

Write-Host "ProjectRoot:  $ProjectRoot" -f cyan
Write-Host "ModuleRoot:  $ModuleRoot" -f cyan
Write-Host "ModuleName:  $ModuleName" -f cyan
Write-Host "ModulePath:  $ModulePath" -f cyan

$ModuleManifestContent = Get-Content $ModulePath

Describe 'Generic Module Tests' -Tag UnitTest, Build {
    # Unload the module so it's loaded fresh for testing
    Remove-Module $ModuleName -ErrorAction SilentlyContinue

    # Import Module
    $ModuleInformation = Import-Module $ModulePath -Force -PassThru
    It 'Module imported successfully' {
        $ModuleInformation.Name | Should -Be $ModuleName
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
        $FunctionsToExportString = $ModuleManifestContent | Where-Object { $_ -match 'FunctionsToExport' }
        $DeclaredFunctions = $FunctionsToExportString.Split(',') |
        ForEach-Object { if ($_ -match '\w+-\w+') { $Matches[0] } }

        It 'FunctionsToExport should not be a wildcard' {
            $FunctionsToExportString | Should -Not -Match "\'\*\'"
        }

        $PublishedFunctions = $ModuleInformation.ExportedFunctions.Values.name
        foreach ($PublicFunction in $DeclaredFunctions) {
            It "Function  Available: $PublicFunction " {
                $PublishedFunctions -contains $PublicFunction | Should -Be $True
            }
        }
    }

    # Other Manifest Properties
    Context 'Other Manifest Properties' {
        It 'RootModule property has value' {
            $ModuleInformation.RootModule | Should -Not -BeNullOrEmpty
        }
        It 'Author property has value' {
            $ModuleInformation.Author | Should -Not -BeNullOrEmpty
        }
        It 'Company Name property has value' {
            $ModuleInformation.CompanyName | Should -Not -BeNullOrEmpty
        }
        It 'Description property has value' {
            $ModuleInformation.Description | Should -Not -BeNullOrEmpty
        }
        It 'Copyright property has value' {
            $ModuleInformation.Copyright | Should -Not -BeNullOrEmpty
        }
        It 'License property has value' {
            $ModuleInformation.LicenseURI | Should -Not -BeNullOrEmpty
        }
        It 'Project Link property has value' {
            $ModuleInformation.ProjectURI | Should -Not -BeNullOrEmpty
        }
        It 'Tags (For the PSGallery) property has value' {
            $ModuleInformation.Tags.count | Should -Not -BeNullOrEmpty
        }
        It 'PSGallery Tags Should Not Contain Spaces' {
            foreach ($Tag in $ModuleInformation.PrivateData.Values.Tags) {
                $Tag | Should -Not -Match '\s'
            }
        }
    }
}
