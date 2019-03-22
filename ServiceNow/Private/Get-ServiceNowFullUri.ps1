function Get-ServiceNowFullUri {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Table
    )
    'https://{0}/api/now/v1/table/{1}' -f $Uri, $Table
}