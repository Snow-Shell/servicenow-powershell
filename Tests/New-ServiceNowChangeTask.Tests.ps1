$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowChangeTask' {

    Context 'Creating a change task' {

        It 'Maps parameters to the correct field names' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'CTASK0010001' }
            }

            New-ServiceNowChangeTask -ChangeRequest 'CHG0010001' -ShortDescription 'New task' -Description 'Longer description' -AssignmentGroup 'ServiceDesk' -AssignedTo 'Greg' -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Table -eq 'change_task' -and
                $Values.parent -eq 'CHG0010001' -and
                $Values.change_request -eq 'CHG0010001' -and
                $Values.short_description -eq 'New task' -and
                $Values.description -eq 'Longer description' -and
                $Values.assignment_group -eq 'ServiceDesk' -and
                $Values.assigned_to -eq 'Greg'
            }
        }

        It 'Warns when a custom field duplicates a built-in field' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' { [PSCustomObject]@{} }
            Mock Write-Warning -ModuleName 'ServiceNow' {}

            New-ServiceNowChangeTask -ShortDescription 'test' -Description 'desc' -CustomField @{ short_description = 'dup' } -Confirm:$false

            Should -Invoke Write-Warning -ModuleName 'ServiceNow' -Times 1 -Exactly
        }

        It 'Returns the created task with PassThru' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ sys_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; number = 'CTASK0010001' }
            }

            $result = New-ServiceNowChangeTask -ShortDescription 'test' -Description 'desc' -PassThru -Confirm:$false

            $result.number | Should -Be 'CTASK0010001'
            $result.PSObject.TypeNames | Should -Contain 'ServiceNow.ChangeTask'
        }
    }
}
