$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Invoke-ServiceNowGraphQL' {

    Context 'Standard query' {

        It 'Builds the full graphql query and parses the result' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now/graphql' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {
                @{ data = @{ myapp = @{ incident = @{ findById = @{ sys_id = @{ value = 'abc123' } } } } } }
            }

            $result = Invoke-ServiceNowGraphQL -Application 'myapp' -Schema 'incident' -Query 'findById (id: "INC0010001") {sys_id {value}}'

            $result.sys_id.value | Should -Be 'abc123'
            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Body -like '*findById*' -and $Method -eq 'Post'
            }
        }
    }

    Context 'Raw' {

        It 'Returns the response as is without parsing' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{ Uri = 'https://test.service-now.com/api/now/graphql' } }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' { @{ data = @{ raw = $true } } }

            $result = Invoke-ServiceNowGraphQL -Application 'myapp' -Schema 'incident' -Query 'query { app { schema { thing { field } } } }' -Raw

            $result.data.raw | Should -Be $true
        }
    }
}
