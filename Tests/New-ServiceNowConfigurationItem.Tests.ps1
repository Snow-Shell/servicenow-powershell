$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowConfigurationItem' {

    Context 'Creating a configuration item' {

        It 'Maps parameters to the correct field names' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; name = 'MyServer' }
            }

            New-ServiceNowConfigurationItem -Name 'MyServer' -Class 'cmdb_ci_server' -Description 'a server' -OperationalStatus '1' -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'cmdb_ci' -and
                $Values.name -eq 'MyServer' -and
                $Values.sys_class_name -eq 'cmdb_ci_server' -and
                $Values.description -eq 'a server' -and
                $Values.operational_status -eq '1'
            }
        }

        It 'Adds custom fields' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' } }

            New-ServiceNowConfigurationItem -Name 'MyServer' -CustomField @{ ip_address = '1.2.3.4' } -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Values.ip_address -eq '1.2.3.4'
            }
        }

        It 'Throws when a custom field duplicates a built-in field' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{} }

            { New-ServiceNowConfigurationItem -Name 'MyServer' -CustomField @{ name = 'dup' } -Confirm:$false } | Should -Throw
        }

        It 'Returns the created CI with PassThru' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; name = 'MyServer' }
            }

            $result = New-ServiceNowConfigurationItem -Name 'MyServer' -PassThru -Confirm:$false

            $result.name | Should -Be 'MyServer'
            $result.PSObject.TypeNames | Should -Contain 'ServiceNow.ConfigurationItem'
        }
    }
}
