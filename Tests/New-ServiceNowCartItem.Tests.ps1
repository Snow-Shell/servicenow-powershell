$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

Describe 'New-ServiceNowCartItem' {

    Context 'Adding an item by sys_id' {

        It 'Uses the sys_id directly without a name lookup' {
            Mock Test-ServiceNowSysId -ModuleName 'ServiceNow' { $true }
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ cart_id = 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7' }
            }

            New-ServiceNowCartItem -CatalogItem 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -Confirm:$false

            Should -Invoke Get-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $ID -eq 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
            }
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $UriLeaf -eq '/servicecatalog/items/a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6/add_to_cart' -and $Values.sysparm_quantity -eq 1
            }
        }
    }

    Context 'Adding an item by name' {

        It 'Looks up the sys_id by name' {
            Mock Test-ServiceNowSysId -ModuleName 'ServiceNow' { $false }
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ cart_id = 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7' }
            }

            New-ServiceNowCartItem -CatalogItem 'Standard Laptop' -Quantity 3 -Confirm:$false

            Should -Invoke Get-ServiceNowRecord -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Filter[0] -eq 'name' -and $Filter[1] -eq '-eq' -and $Filter[2] -eq 'Standard Laptop'
            }
            Should -Invoke Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' -Times 1 -Exactly -ParameterFilter {
                $Values.sysparm_quantity -eq 3
            }
        }

        It 'Throws when the catalog item cannot be found' {
            Mock Test-ServiceNowSysId -ModuleName 'ServiceNow' { $false }
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { $null }

            { New-ServiceNowCartItem -CatalogItem 'Unknown Item' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Checkout' {

        It 'Submits the cart when Checkout is specified' {
            Mock Test-ServiceNowSysId -ModuleName 'ServiceNow' { $true }
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }
            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ cart_id = 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7' }
            }
            Mock Submit-ServiceNowCart -ModuleName 'ServiceNow' {
                [PSCustomObject]@{ number = 'REQ0010001' }
            }

            $result = New-ServiceNowCartItem -CatalogItem 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -Checkout -PassThru -Confirm:$false

            Should -Invoke Submit-ServiceNowCart -ModuleName 'ServiceNow' -Times 1 -Exactly
            $result.number | Should -Be 'REQ0010001'
        }
    }

    Context 'Mandatory variable errors' {

        It 'Throws a friendly error listing the missing mandatory variables' {
            Mock Test-ServiceNowSysId -ModuleName 'ServiceNow' { $true }
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }

            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                if ( $UriLeaf -like '*add_to_cart*' ) {
                    $errorDetails = [System.Management.Automation.ErrorRecord]::new(
                        [Exception]::new('Bad Request'),
                        'BadRequest',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $null
                    )
                    $errorDetails.ErrorDetails = [System.Management.Automation.ErrorDetails]::new(
                        (@{ error = @{ message = 'Mandatory Variables are required' } } | ConvertTo-Json)
                    )
                    throw $errorDetails
                }
                else {
                    [PSCustomObject]@{
                        variables = @(
                            [PSCustomObject]@{ name = 'type'; mandatory = $true }
                            [PSCustomObject]@{ name = 'parcel_details'; mandatory = $true }
                            [PSCustomObject]@{ name = 'optional_field'; mandatory = $false }
                        )
                    }
                }
            }

            { New-ServiceNowCartItem -CatalogItem 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -Confirm:$false } | Should -Throw '*type, parcel_details*'
        }

        It 'Handles a display-value style object for the mandatory flag' {
            Mock Test-ServiceNowSysId -ModuleName 'ServiceNow' { $true }
            Mock Get-ServiceNowRecord -ModuleName 'ServiceNow' { 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' }

            Mock Invoke-ServiceNowRestMethod -ModuleName 'ServiceNow' {
                if ( $UriLeaf -like '*add_to_cart*' ) {
                    $errorDetails = [System.Management.Automation.ErrorRecord]::new(
                        [Exception]::new('Bad Request'),
                        'BadRequest',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $null
                    )
                    $errorDetails.ErrorDetails = [System.Management.Automation.ErrorDetails]::new(
                        (@{ error = @{ message = 'Mandatory Variables are required' } } | ConvertTo-Json)
                    )
                    throw $errorDetails
                }
                else {
                    [PSCustomObject]@{
                        variables = @(
                            [PSCustomObject]@{ name = 'type'; mandatory = [PSCustomObject]@{ value = 'true'; displayValue = 'true' } }
                            [PSCustomObject]@{ name = 'optional_field'; mandatory = [PSCustomObject]@{ value = 'false'; displayValue = 'false' } }
                        )
                    }
                }
            }

            { New-ServiceNowCartItem -CatalogItem 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6' -Confirm:$false } | Should -Throw '*type*'
        }
    }
}
