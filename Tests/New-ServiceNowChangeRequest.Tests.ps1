$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowChangeRequest' {

    Context 'Creating a change request directly' {

        It 'Maps parameters to the correct field names' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'CHG0010001' }
            }

            New-ServiceNowChangeRequest -Caller 'Greg' -ShortDescription 'test change' -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'change_request' -and $Values.caller_id -eq 'Greg' -and $Values.short_description -eq 'test change'
            }
        }
    }

    Context 'Creating from a change model' {

        It 'Sets the chg_model field' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' } }

            New-ServiceNowChangeRequest -ModelID 'Normal' -ShortDescription 'test' -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Values.chg_model -eq 'Normal'
            }
        }
    }

    Context 'Creating from a standard change template' {

        It 'Sets the template and type fields' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' } }

            New-ServiceNowChangeRequest -TemplateID 'Change VLAN' -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Values.std_change_producer_version -eq 'Change VLAN' -and $Values.type -eq 'Standard'
            }
        }
    }

    Context 'Duplicate fields' {

        It 'Throws when a custom field duplicates a built-in field' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{} }

            { New-ServiceNowChangeRequest -ShortDescription 'test' -CustomField @{ short_description = 'dup' } -Confirm:$false } | Should -Throw
        }
    }

    Context 'PassThru' {

        It 'Returns the created record typed as a ChangeRequest' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'CHG0010001' }
            }

            $result = New-ServiceNowChangeRequest -ShortDescription 'test' -PassThru -Confirm:$false

            $result.number | Should -Be 'CHG0010001'
            $result.PSObject.TypeNames | Should -Contain 'ServiceNow.ChangeRequest'
        }
    }
}
