<#
.SYNOPSIS
    Submit the user cart for checkout

.DESCRIPTION
    Checks out the user cart, based on the current check-out type (one-step or two-step)

.PARAMETER PassThru
    If provided, the new record id will be returned

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Submit-ServiceNowCart

    Checks out the user cart, based on the current check-out type (one-step or two-step).

.EXAMPLE
    Submit-ServiceNowCart -PassThru

    Checks out the user cart, based on the current check-out type (one-step or two-step) and returns the request number and request ID.

.LINK
    https://developer.servicenow.com/dev.do#!/reference/api/zurich/rest/c_ServiceCatalogAPI#servicecat-POST-cart-sub_order?navFilter=serv

.OUTPUTS
    PSCustomObject if PassThru provided
#>
function Submit-ServiceNowCart {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter()]
        [switch]$PassThru,

        [Parameter()]
        [hashtable]$ServiceNowSession = $script:ServiceNowSession
    )

    process {

        if ( $PSCmdlet.ShouldProcess('Checkout current user cart') ) {
            $submitOrder = @{
                Method            = 'Post'
                UriLeaf           = "/servicecatalog/cart/submit_order"
                Namespace         = 'sn_sc'
                ServiceNowSession = $ServiceNowSession
            }

            $submitOrderResponse = Invoke-ServiceNowRestMethod @submitOrder

            if ($PassThru) {
                if ( $submitOrderResponse.request_number ) {
                    $submitOrderResponse | Select-Object @{'n' = 'number'; 'e' = { $_.request_number } }, request_id
                }
                else {
                    $submitOrderResponse
                }
            }

        }
    }
}