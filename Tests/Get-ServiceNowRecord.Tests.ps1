$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Get-ServiceNowRecord' {

    Context 'Retrieve by ID' {

        It 'Filters by sys_id when a 32 character id is provided along with a table' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'INC0010001' }
            }

            $result = Get-ServiceNowRecord -Table 'incident' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'

            $result.number | Should -Be 'INC0010001'
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly
        }

        It 'Determines the table from a numbered id prefix' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ number = 'INC0010001' }
            }

            Get-ServiceNowRecord -ID 'INC0010001' | Out-Null

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'incident'
            }
        }
    }

    Context 'Retrieve by table and filter' {

        It 'Passes the table through to the rest method' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            Get-ServiceNowRecord -Table 'incident' -Filter @('state', '-eq', '1') | Out-Null

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'incident'
            }
        }
    }

    Context 'Retrieve using ParentID' {

        It 'Queries successfully when no table is specified' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            Get-ServiceNowRecord -ParentID 'RITM0010001' | Out-Null

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly
        }
    }

    Context 'AsValue' {

        It 'Returns the raw property value instead of a full object' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            $result = Get-ServiceNowRecord -Table 'incident' -Property sys_id -AsValue -Filter @('state', '-eq', '1')

            $result | Should -Be 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
        }
    }

    Context 'Alias' {

        It 'Is available via the gsnr alias' {
            (Get-Alias gsnr).ResolvedCommand.Name | Should -Be 'Get-ServiceNowRecord'
        }
    }
}
