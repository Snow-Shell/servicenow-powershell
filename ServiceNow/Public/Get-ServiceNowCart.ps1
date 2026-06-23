<#
.SYNOPSIS
    Get the cart of the current user
.DESCRIPTION
    Get the cart of the current user
.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.
.EXAMPLE
    Get-ServiceNowCart
    Get the cart of the current user
.INPUTS
    None
.OUTPUTS
    PSCustomObject representing the cart
#>
function Get-ServiceNowCart {
    param
    (
        [Parameter()]
        [hashtable]$ServiceNowSession = $script:ServiceNowSession
    )

    $params = @{
        Method            = 'Get'
        UriLeaf           = "/servicecatalog/cart"
        Namespace         = 'sn_sc'
        ServiceNowSession = $ServiceNowSession
    }
    Invoke-ServiceNowRestMethod @params | Select-Object @{n = 'sys_id'; e = { $_.cart_id } }, * -ExcludeProperty cart_id
}