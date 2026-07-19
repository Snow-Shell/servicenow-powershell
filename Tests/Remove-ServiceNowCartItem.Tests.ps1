$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Remove-ServiceNowCartItem' {

    Context 'Removing a specific cart item' {

        It 'Deletes the cart item by id' {
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}

            Remove-ServiceNowCartItem -CartItemId 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -Confirm:$false

            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Delete' -and $UriLeaf -eq '/servicecatalog/cart/a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -and $Namespace -eq 'sn_sc'
            }
        }
    }

    Context 'Emptying the cart with a provided CartId' {

        It 'Empties the specified cart without looking up the current cart' {
            Mock Get-ServiceNowCart -ModuleName 'ServiceNow' {}
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}

            Remove-ServiceNowCartItem -All -CartId 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7' -Confirm:$false

            Should -Invoke Get-ServiceNowCart -ModuleName 'ServiceNow' -Times 0
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $UriLeaf -eq '/servicecatalog/cart/b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7/empty'
            }
        }
    }

    Context 'Emptying the current cart' {

        It 'Looks up the current cart when CartId is not provided' {
            Mock Get-ServiceNowCart -ModuleName 'ServiceNow' { [PSCustomObject]@{ sys_id = 'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8' } }
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {}

            Remove-ServiceNowCartItem -All -Confirm:$false

            Should -Invoke Get-ServiceNowCart -ModuleName 'ServiceNow' -Times 1 -Exactly
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $UriLeaf -eq '/servicecatalog/cart/c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8/empty'
            }
        }
    }
}
