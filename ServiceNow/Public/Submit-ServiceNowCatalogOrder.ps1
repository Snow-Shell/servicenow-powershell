<#
.SYNOPSIS
    Submit a catalog request using Service Catalog API

.DESCRIPTION
    Checks out the user cart, based on the current check-out type (one-step or two-step). Reference: https://developer.servicenow.com/dev.do#!/reference/api/zurich/rest/c_ServiceCatalogAPI#servicecat-POST-cart-sub_order?navFilter=serv

.PARAMETER PassThru
    If provided, the new record will be returned

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Submit-ServiceNowCatalogOrder

    Checks out the user cart, based on the current check-out type (one-step or two-step).

.EXAMPLE
    Submit-ServiceNowCatalogOrder -PassThru

    Checks out the user cart, based on the current check-out type (one-step or two-step) and returns the request numbers as an object.

.INPUTS
    InputData

.OUTPUTS
    PSCustomObject if PassThru provided
#>
function Submit-ServiceNowCatalogOrder {
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter()][Hashtable]$Connection,
        [Parameter()][hashtable]$ServiceNowSession = $script:ServiceNowSession,
        [Parameter()][switch]$PassThru
    )

    process {

        if ( $PSCmdlet.ShouldProcess('POST cart to Submit_Order API') ) {
            $SubmitOrder = @{
                Method            = 'Post'
                UriLeaf           = "/servicecatalog/cart/submit_order"
                Namespace         = 'sn_sc'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            $SubmitOrderResponse = Invoke-ServiceNowRestMethod @SubmitOrder

            if ($PassThru) {
                $SubmitOrderResponse | Select-Object @{'n' = 'number'; 'e' = { $_.request_number } }, request_id
            }

        } else {
            Write-Output "Checks out the user cart, based on the current check-out type (one-step or two-step).`n`nIf one-step checkout, the method checks out (saves) the cart and returns the request number and the request order ID. If two-step checkout, the method returns the cart order status and all the information required for two-step checkout."
        }
    }
}