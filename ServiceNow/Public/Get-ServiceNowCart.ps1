<#
.SYNOPSIS
    Get the cart of the current user

.DESCRIPTION
    Get the cart of the current user

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