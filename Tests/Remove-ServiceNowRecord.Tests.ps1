$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Remove-ServiceNowRecord' {

    Context 'Removing a record by table and sys_id' {

        It 'Uses DELETE method with the resolved table and id' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}

            Remove-ServiceNowRecord -Table 'incident' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Delete' -and $Table -eq 'incident' -and $SysId -eq 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
            }
        }
    }

    Context 'Removing a record by number only' {

        It 'Looks up the sys_id from the number prefix before deleting' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            Remove-ServiceNowRecord -ID 'INC0010001' -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 2 -Exactly
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -ParameterFilter {
                $Method -eq 'Delete' -and $SysId -eq 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
            }
        }
    }

    Context 'Pipeline input' {

        It 'Removes multiple records from the pipeline' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}

            [PSCustomObject]@{ sys_class_name = 'incident'; sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' },
            [PSCustomObject]@{ sys_class_name = 'incident'; sys_id = 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7' } | Remove-ServiceNowRecord -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 2 -Exactly
        }
    }
}
