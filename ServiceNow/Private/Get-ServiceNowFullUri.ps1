function Get-ServiceNowFullUri {
    param (
        [Parameter(Mandatory = $true)]
        [Alias('ServiceNowUrl')]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Table
    )
    'https://{0}/api/now/v1/table/{1}' -f $Uri, $Table
}