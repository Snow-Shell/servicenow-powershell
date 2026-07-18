$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowQuery Filter Operators' {

    Context '-startswith' {

        It 'Builds a query using the STARTSWITH operator' {
            New-ServiceNowQuery -Filter @('short_description', '-startswith', 'powershell') | Should -Be 'short_descriptionSTARTSWITHpowershell'
        }
    }

    Context '-endswith' {

        It 'Builds a query using the ENDSWITH operator' {
            New-ServiceNowQuery -Filter @('short_description', '-endswith', 'powershell') | Should -Be 'short_descriptionENDSWITHpowershell'
        }
    }

    Context '-startswith and -endswith combined' {

        It 'Builds a query joining both operators with and' {
            $filter = @('short_description', '-startswith', 'foo'),
                        'and',
                      @('short_description', '-endswith', 'bar')

            New-ServiceNowQuery -Filter $filter | Should -Be 'short_descriptionSTARTSWITHfoo^short_descriptionENDSWITHbar'
        }
    }
}
