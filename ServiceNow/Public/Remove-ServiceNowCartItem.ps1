<#
.SYNOPSIS
    Remove cart items

.DESCRIPTION
    Removes a specific catalog item from the cart or empties the entire cart.

.PARAMETER CartItemId
    SysId of the cart item to be removed from the current user.
    Must be a 32 character alphanumeric string.

.PARAMETER All
    Remove all items from the cart (empty the cart).

.PARAMETER CartId
    SysId of the cart to be emptied.  If not provided, the current user's cart will be looked up.
    Must be a 32 character alphanumeric string.

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Remove-ServiceNowCartItem -CartItemId "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"

    Remove a specific item from the cart

.EXAMPLE
    Remove-ServiceNowCartItem -All

    Remove all items from the current user's cart

.EXAMPLE
    Remove-ServiceNowCartItem -All -CartId "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6"

    Remove all items from the specified cart

.INPUTS
    CartItemId

.OUTPUTS
    None
#>
function Remove-ServiceNowCartItem {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByCatalogItemId')]
        [ValidateScript( {
                if ($_ | Test-ServiceNowSysId) {
                    $true
                }
                else {
                    throw 'CartItemId must be a SysId 32 character alphanumeric'
                }
            })]
        [string] $CartItemId,
        
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch] $All,
        
        [Parameter(ParameterSetName = 'All')]
        [ValidateScript( {
                if ($_ | Test-ServiceNowSysId) {
                    $true
                }
                else {
                    throw 'CartId must be a SysId 32 character alphanumeric'
                }
            })]
        [string] $CartId,

        [Parameter()]
        [hashtable]$ServiceNowSession = $script:ServiceNowSession
    )

    process {

        $params = @{
            Method            = 'Delete'
            Namespace         = 'sn_sc'
            ServiceNowSession = $ServiceNowSession
        }

        if ( $CartItemId ) {
            $params.UriLeaf = "/servicecatalog/cart/{0}" -f $CartItemId
        }
        else {
            # remove a cart and its items
            # we need the cart id so if we don't have it, look up the current user's cart
            if ( -not $CartId ) {
                $cart = Get-ServiceNowCart -ServiceNowSession $ServiceNowSession
                $cartId = $cart.sys_id
            }
            Write-Verbose "Emptying cart with sys_id $cartId"
            $params.UriLeaf = "/servicecatalog/cart/$cartId/empty"
        }

        $target = if ($CartItemId) { "Remove item $CartItemId from current cart" } else { "Remove cart $cartId completely" }
        if ( $PSCmdlet.ShouldProcess($target) ) {
            Invoke-ServiceNowRestMethod @params
        }
    }
}