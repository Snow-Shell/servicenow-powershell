$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'Get-ServiceNowCart' {

    It 'Retrieves the current cart and renames cart_id to sys_id' {
        Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
            [PSCustomObject]@{ cart_id = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'; subtotal = '100.00' }
        }

        $result = Get-ServiceNowCart

        $result.sys_id | Should -Be 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
        $result.subtotal | Should -Be '100.00'
        $result.PSObject.Properties.Name | Should -Not -Contain 'cart_id'

        Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Get' -and $UriLeaf -eq '/servicecatalog/cart' -and $Namespace -eq 'sn_sc'
        }
    }
}
