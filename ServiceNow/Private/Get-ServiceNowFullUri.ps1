function Get-ServiceNowFullUri {
    param (
        [Parameter(Mandatory = $true)]
        [Alias('ServiceNowUrl')]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Table,

        [Parameter()]
        $SysId
    )
    if ($SysId) {
        'https://{0}/api/now/v1/table/{1}/{2}' -f $Uri, $Table, $SysId
    }
    else {
        'https://{0}/api/now/v1/table/{1}' -f $Uri, $Table
    }
}