function Get-ServiceNowRequestItem {
<#
    .SYNOPSIS
        Query for Request Item (RITM) tickets.

    .DESCRIPTION
        Query for Request Item (RITM) tickets from the sc_req_item table.

    .EXAMPLE
        Get-ServiceNowRequestItem -MatchExact @{number='RITM0000001'}

        Return the details for RITM0000001

    .OUTPUTS
        System.Management.Automation.PSCustomObject
#>

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsPaging)]
    param(
        # Machine name of the field to order by
        [parameter(Mandatory = $false)]
        [string]$OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [parameter(Mandatory = $false)]
        [ValidateSet('Desc', 'Asc')]
        [string]$OrderDirection = 'Desc',

        # Maximum number of records to return
        [parameter(Mandatory = $false)]
        [int]$Limit,

        # Fields to return
        [Parameter(Mandatory = $false)]
        [Alias('Fields')]
        [string[]]$Properties,

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(Mandatory = $false)]
        [hashtable]$MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(Mandatory = $false)]
        [hashtable]$MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [parameter(Mandatory = $false)]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    $result = Get-ServiceNowTableEntry @PSBoundParameters -Table 'sc_req_item'

    If (-not $Properties) {
        $result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, "ServiceNow.RequestItem") }
    }
    $result
}
