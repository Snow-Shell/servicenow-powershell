$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowIncident' {

    Context 'Creating an incident' {

        It 'Maps parameters to the correct field names' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'INC0010001' }
            }

            New-ServiceNowIncident -Caller 'Greg' -ShortDescription 'test' -Description 'long desc' -AssignmentGroup 'ServiceDesk' -Comment 'a comment' -Category 'Office' -Subcategory 'Outlook' -ConfigurationItem 'PC1' -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'incident' -and
                $Values.caller_id -eq 'Greg' -and
                $Values.short_description -eq 'test' -and
                $Values.description -eq 'long desc' -and
                $Values.assignment_group -eq 'ServiceDesk' -and
                $Values.comments -eq 'a comment' -and
                $Values.category -eq 'Office' -and
                $Values.subcategory -eq 'Outlook' -and
                $Values.cmdb_ci -eq 'PC1'
            }
        }

        It 'Adds custom fields' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' } }

            New-ServiceNowIncident -Caller 'Greg' -ShortDescription 'test' -CustomField @{ u_custom1 = 'value1' } -Confirm:$false

            Should -Invoke New-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Values.u_custom1 -eq 'value1'
            }
        }

        It 'Throws when a custom field duplicates a built-in field' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' { [PSCustomObject]@{} }

            { New-ServiceNowIncident -Caller 'Greg' -ShortDescription 'test' -CustomField @{ caller_id = 'Someone' } -Confirm:$false } | Should -Throw
        }

        It 'Returns the created incident with PassThru' {
            Mock New-ServiceNowRecord -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'INC0010001' }
            }

            $result = New-ServiceNowIncident -Caller 'Greg' -ShortDescription 'test' -PassThru -Confirm:$false

            $result.number | Should -Be 'INC0010001'
            $result.PSObject.TypeNames | Should -Contain 'ServiceNow.Incident'
        }
    }
}
