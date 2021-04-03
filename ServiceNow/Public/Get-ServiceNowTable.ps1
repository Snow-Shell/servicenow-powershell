function Get-ServiceNowTable {
    <#
    .SYNOPSIS
        Retrieves records for the specified table
    .DESCRIPTION
        The Get-ServiceNowTable function retrieves records for the specified table
    .INPUTS
        None
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .LINK
        Service-Now Kingston REST Table API: https://docs.servicenow.com/bundle/kingston-application-development/page/integrate/inbound-rest/concept/c_TableAPI.html
        Service-Now Table API FAQ: https://hi.service-now.com/kb_view.do?sysparm_article=KB0534905
#>

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsPaging)]
    Param (
        # Name of the table we're querying (e.g. incidents)
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Table,

        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [Parameter()]
        [string] $Query,

        # Maximum number of records to return
        [Parameter()]
        [int] $Limit,

        # Fields to return
        [Parameter()]
        [Alias('Fields')]
        [string[]] $Properties,

        # Whether or not to show human readable display values instead of machine values
        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [string] $DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential] $Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    # Table Splat
    $getServiceNowTableSplat = @{
        Table             = $Table
        Query             = $Query
        Fields            = $Properties
        DisplayValues     = $DisplayValues
        Connection        = $Connection
        Credential        = $Credential
        ServiceNowUrl     = $ServiceNowURL
        ServiceNowSession = $ServiceNowSession
    }

    # # Only add the Limit parameter if it was explicitly provided
    if ($PSBoundParameters.ContainsKey('Limit')) {
        $getServiceNowTableSplat.Add('Limit', $Limit)
    }

    # # Add all provided paging parameters
    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
        $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
    }

    Invoke-ServiceNowRestMethod @getServiceNowTableSplat
}
