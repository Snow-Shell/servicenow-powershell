$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Export-ServiceNowRecord' {

    Context 'Export by ID' {

        It 'Filters by number and uses the correct export format from the file extension' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{} }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            $path = Join-Path $TestDrive 'out.csv'
            Export-ServiceNowRecord -ID 'INC0010001' -Path $path -ServiceNowSession @{ Domain = 'test.service-now.com' }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://test.service-now.com/incident_list.do?CSV' -and
                $Body.sysparm_query -eq 'number=INC0010001' -and
                $OutFile -eq $path
            }
        }
    }

    Context 'Export by table and filter' {

        It 'Builds the query string from the filter and uses PDF format' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{} }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            $path = Join-Path $TestDrive 'out.pdf'
            Export-ServiceNowRecord -Table 'incident' -Filter @('state', '-eq', '1') -Path $path -ServiceNowSession @{ Domain = 'test.service-now.com' }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://test.service-now.com/incident_list.do?PDF' -and
                $Body.sysparm_query -eq 'state=1'
            }
        }

        It 'Converts XLS extension to the EXCEL export format' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{} }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            $path = Join-Path $TestDrive 'out.xls'
            Export-ServiceNowRecord -Table 'incident' -Filter @('state', '-eq', '1') -Path $path -ServiceNowSession @{ Domain = 'test.service-now.com' }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://test.service-now.com/incident_list.do?EXCEL'
            }
        }

        It 'Passes requested properties as lower case sysparm_fields' {
            Mock Get-ServiceNowAuth -ModuleName 'ServiceNow' { @{} }
            Mock Invoke-RestMethod -ModuleName 'ServiceNow' {}

            $path = Join-Path $TestDrive 'out.csv'
            Export-ServiceNowRecord -Table 'incident' -Filter @('state', '-eq', '1') -Property 'Number', 'ShortDescription' -Path $path -ServiceNowSession @{ Domain = 'test.service-now.com' }

            Should -Invoke Invoke-RestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Body.sysparm_fields -eq 'number,shortdescription'
            }
        }

        It 'Throws for an unsupported file extension' {
            $path = Join-Path $TestDrive 'out.txt'
            { Export-ServiceNowRecord -Table 'incident' -Filter @('state', '-eq', '1') -Path $path } | Should -Throw
        }
    }
}
