$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowRecord' {

    Context 'Creating a record' {

        It 'Uses POST method with the provided table and values' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'INC0010001' }
            }

            New-ServiceNowRecord -Table 'incident' -InputData @{ short_description = 'test issue' } -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and $Table -eq 'incident' -and $Values.short_description -eq 'test issue'
            }
        }

        It 'Does not return output without PassThru' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            $result = New-ServiceNowRecord -Table 'incident' -InputData @{ short_description = 'test' } -Confirm:$false
            $result | Should -BeNullOrEmpty
        }

        It 'Returns the created record typed with PassThru' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'INC0010001' }
            }

            $result = New-ServiceNowRecord -Table 'incident' -InputData @{ short_description = 'test' } -PassThru -Confirm:$false

            $result.number | Should -Be 'INC0010001'
            $result.PSObject.TypeNames | Should -Contain 'ServiceNow.Incident'
        }
    }

    Context 'Pipeline input' {

        It 'Creates multiple records from the pipeline' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            @{ short_description = 'issue 1' }, @{ short_description = 'issue 2' } | New-ServiceNowRecord -Table 'incident' -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 2 -Exactly
        }
    }
}
