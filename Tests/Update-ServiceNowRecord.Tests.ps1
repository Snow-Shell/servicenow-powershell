$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Update-ServiceNowRecord' {

    Context 'Updating with InputData' {

        It 'Uses PATCH method with the provided table, id, and values' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            Update-ServiceNowRecord -Table 'incident' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -InputData @{ state = '2' } -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Patch' -and $Table -eq 'incident' -and $SysId -eq 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -and $Values.state -eq '2'
            }
        }

        It 'Joins array values with a comma before sending' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            Update-ServiceNowRecord -Table 'incident' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -InputData @{ watch_list = @('user1', 'user2') } -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Values.watch_list -eq 'user1,user2'
            }
        }

        It 'Returns the updated record with PassThru' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; state = '2' }
            }

            $result = Update-ServiceNowRecord -Table 'incident' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -InputData @{ state = '2' } -PassThru -Confirm:$false

            $result.state | Should -Be '2'
            $result.PSObject.TypeNames | Should -Contain 'ServiceNow.Incident'
        }
    }

    Context 'Updating custom variable data' {

        It 'Warns when the custom variable cannot be found' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{ CustomVariable = [PSCustomObject]@{} } }
            Mock Write-Warning -ModuleName 'ServiceNow' {}

            Update-ServiceNowRecord -Table 'sc_req_item' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -CustomVariableData @{ 'unknown_var' = 'value' } -Confirm:$false

            Should -Invoke Write-Warning -ModuleName 'ServiceNow' -Times 1 -Exactly
        }

        It 'Updates the custom variable when found' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{
                    CustomVariable = [PSCustomObject]@{
                        my_var = [PSCustomObject]@{ Name = 'my_var'; SysId = 'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8' }
                    }
                }
            }

            Update-ServiceNowRecord -Table 'sc_req_item' -ID 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -CustomVariableData @{ 'my_var' = 'yes' } -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'sc_item_option' -and $SysId -eq 'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8' -and $Values.value -eq 'yes'
            }
        }
    }
}
