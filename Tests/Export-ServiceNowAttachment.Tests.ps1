$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Export-ServiceNowAttachment' {

    Context 'Saving to a file' {

        It 'Saves the attachment using the provided file name' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            Export-ServiceNowAttachment -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -FileName 'myfile.txt' -Destination $TestDrive -Confirm:$false

            $expectedPath = Join-Path $TestDrive 'myfile.txt'
            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://test.service-now.com/api/now/attachment/a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6/file' -and
                $OutFile -eq $expectedPath
            }
        }

        It 'Appends the sys_id to the file name when AppendNameWithSysId is specified' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            Export-ServiceNowAttachment -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -FileName 'myfile.txt' -Destination $TestDrive -AppendNameWithSysId -Confirm:$false

            $expectedPath = Join-Path $TestDrive 'myfile_a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6.txt'
            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $OutFile -eq $expectedPath
            }
        }

        It 'Throws when the destination file exists and AllowOverwrite is not specified' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            $existingPath = Join-Path $TestDrive 'existing.txt'
            Set-Content -Path $existingPath -Value 'placeholder'

            { Export-ServiceNowAttachment -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -FileName 'existing.txt' -Destination $TestDrive -Confirm:$false } | Should -Throw
        }

        It 'Overwrites the destination file when AllowOverwrite is specified' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            $existingPath = Join-Path $TestDrive 'existing2.txt'
            Set-Content -Path $existingPath -Value 'placeholder'

            { Export-ServiceNowAttachment -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -FileName 'existing2.txt' -Destination $TestDrive -AllowOverwrite -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'AsValue' {

        It 'Returns the attachment content instead of writing a file' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' { 'file contents' }

            $result = Export-ServiceNowAttachment -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -AsValue -Confirm:$false

            $result | Should -Be 'file contents'
        }
    }
}
