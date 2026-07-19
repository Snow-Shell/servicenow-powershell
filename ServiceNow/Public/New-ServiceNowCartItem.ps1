<#
.SYNOPSIS
    Add item to the cart of the current user

.DESCRIPTION
    Adds a catalog item to the cart of the current user and optionally checks out the cart to create the order.

.PARAMETER CatalogItem
    Name or ID of the catalog item that will be created.
    Use Tab or Menu Completion to see available catalog items.

.PARAMETER Quantity
    Quantity of the catalog item to request.  Default is 1.

.PARAMETER ItemValues
    Key/value pairs of variable names and their values

.PARAMETER Checkout
    Checkout the cart after adding the item to create the order.
    If not checking out, you can use Submit-ServiceNowCatalogOrder to checkout later.

.PARAMETER PassThru
    If provided, the new record, either cart addition or checked out order, will be returned

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    New-ServiceNowCartItem -CatalogItem "Standard Laptop"

    Add 1 of the catalog item to the cart without checking out

.EXAMPLE
    New-ServiceNowCartItem -CatalogItem "Standard Laptop" -Quantity 3

    Add 3 of the catalog item to the cart without checking out

.EXAMPLE
    New-ServiceNowCartItem -CatalogItem "Standard Laptop" -Quantity 3 -Checkout

    Add 3 of the catalog item to the cart and checkout to create the order

.EXAMPLE
    'Standard Laptop', 'Adobe Acrobat Pro' | New-ServiceNowCartItem

    Add multiple catalog items to the cart

.EXAMPLE
    New-ServiceNowCartItem -CatalogItem "Standard Laptop" -PassThru

    Add a catalog item to the cart and return the cart details

.EXAMPLE
    New-ServiceNowCartItem -CatalogItem "Standard Laptop" -PassThru -Checkout

    Add a catalog item to the cart, checkout to create the order, and return the order details

.EXAMPLE
    'Packaging and Shipping' | New-ServiceNowCartItem -ItemValues @{'type'='Inter-office';'parcel_details'='fragile'}

    Add a catalog item to the cart with mandatory values

.EXAMPLE
    New-ServiceNowCartItem -CatalogItem 'ce40793b53d6ba10295d38e0a0490e86'

    Add a catalog item to the cart using its sys_id

.INPUTS
    CatalogItem

.OUTPUTS
    PSCustomObject if PassThru provided
#>
function New-ServiceNowCartItem {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Add-ServiceNowCartItem')]

    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $CatalogItem,

        [Parameter()]
        [ValidateRange(1, [int32]::MaxValue)]
        [int32] $Quantity = 1,

        [Parameter()]
        [hashtable]$ItemValues,

        [Parameter()]
        [switch]$Checkout,

        [Parameter()]
        [switch]$PassThru,

        [Parameter()]
        [hashtable]$ServiceNowSession = $script:ServiceNowSession
    )

    process {
        if ($CatalogItem | Test-ServiceNowSysId ) {
            #Verify the sys_id of the Catalog Item
            $catalogItemID = Get-ServiceNowRecord -Table sc_cat_item -AsValue -ID $CatalogItem -Property sys_id
        }
        else {
            #Lookup the sys_id of the Catalog Item
            $catalogItemID = Get-ServiceNowRecord -Table sc_cat_item -AsValue -Filter @('name', '-eq', $CatalogItem ) -Property sys_id
        }

        if ([string]::IsNullOrEmpty($catalogItemID)) {
            throw "Unable to find catalog item '$CatalogItem'"
        }
        else {
            Write-Verbose "Found $catalogItemID via lookup from '$CatalogItem'"
        }

        $addItemToCart = @{
            Method            = 'Post'
            UriLeaf           = "/servicecatalog/items/{0}/add_to_cart" -f $catalogItemID
            Values            = @{
                'sysparm_quantity' = $Quantity
            }
            Namespace         = 'sn_sc'
            ServiceNowSession = $ServiceNowSession
        }

        if ( $ItemValues ) {
            $addItemToCart.Values.variables = $ItemValues
        }

        if ( $PSCmdlet.ShouldProcess($catalogItemID, 'Create new catalog item request') ) {

            try {
                $addItemCartResponse = Invoke-ServiceNowRestMethod @addItemToCart
            }
            catch {
                if ( ($_.ErrorDetails.Message | ConvertFrom-Json | Select-Object -ExpandProperty error | Select-Object -ExpandProperty message) -match 'Mandatory Variables are required' ) {
                    $catItem = Invoke-ServiceNowRestMethod -UriLeaf "/servicecatalog/items/$catalogItemID" -Namespace 'sn_sc'
                    $mandatoryVars = $catItem.variables | Where-Object {
                        # the mandatory flag can come back as a plain boolean/string or, for some
                        # instances/api versions, a display-value style object, eg. @{ value = 'true' }
                        $mandatoryValue = $_.mandatory
                        if ( $mandatoryValue -is [System.Management.Automation.PSCustomObject] ) {
                            $mandatoryValue = $mandatoryValue.value
                        }
                        "$mandatoryValue" -eq 'true'
                    } | Select-Object -ExpandProperty name
                    throw ('Failed to add item to cart. The following mandatory variables must be provided: {0}' -f ($mandatoryVars -join ', '))
                }
                else {
                    throw $_
                }
            }

            if ( -not $addItemCartResponse.cart_id ) {
                throw ('Failed to add item to cart. Response: {0}' -f ($addItemCartResponse | ConvertTo-Json))
            }
            else {
                Write-Verbose "Added item to cart with Cart ID: $($addItemCartResponse.cart_id)"
                $out = $addItemCartResponse
            }

            Write-Verbose ("Current cart items:`n{0}" -f ($addItemCartResponse.items | Select-Object item_name, quantity, price | Out-String))
            Write-Verbose ('Cart Total: {0}' -f $addItemCartResponse.subtotal)
        }
    }
    
    end {        
        if ( $Checkout ) {
            $submitResponse = Submit-ServiceNowCart -ServiceNowSession $ServiceNowSession -PassThru
            Write-Verbose 'Order submitted successfully.'
            $out = $submitResponse
        }
        
        if ( $PassThru ) {
            $out
        }
    }
}