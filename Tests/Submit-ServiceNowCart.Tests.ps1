$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Submit-ServiceNowCart' {

    Context 'Checkout with PassThru' {

        It 'Returns the request number and id when available' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ request_number = 'REQ0010001'; request_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            }

            $result = Submit-ServiceNowCart -PassThru -Confirm:$false

            $result.number | Should -Be 'REQ0010001'
            $result.request_id | Should -Be 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and $UriLeaf -eq '/servicecatalog/cart/submit_order' -and $Namespace -eq 'sn_sc'
            }
        }

        It 'Returns the raw response when request_number is not present' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ some_other_field = 'value' }
            }

            $result = Submit-ServiceNowCart -PassThru -Confirm:$false

            $result.some_other_field | Should -Be 'value'
        }
    }

    Context 'Checkout without PassThru' {

        It 'Does not return output' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ request_number = 'REQ0010001' }
            }

            $result = Submit-ServiceNowCart -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }
}
