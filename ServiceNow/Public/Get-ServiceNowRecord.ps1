function Get-ServiceNowRecord {
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

        [parameter(ParameterSetName = 'AutomationFilter')]
        [parameter(ParameterSetName = 'SessionFilter')]
        [System.Collections.ArrayList] $Filter,

        [parameter(ParameterSetName = 'AutomationFilter')]
        [parameter(ParameterSetName = 'SessionFilter')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList] $Sort,

        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [Parameter(Mandatory, ParameterSetName = 'AutomationQuery')]
        [Parameter(Mandatory, ParameterSetName = 'SessionQuery')]
        [string] $Query,

        # Fields to return
        [Parameter()]
        [Alias('Fields')]
        [string[]] $Properties,

        # Whether or not to show human readable display values instead of machine values
        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [string] $DisplayValues = 'true',

        [Parameter(Mandatory, ParameterSetName = 'AutomationQuery')]
        [parameter(Mandatory, ParameterSetName = 'AutomationFilter')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Connection,

        [Parameter(ParameterSetName = 'SessionQuery')]
        [Parameter(ParameterSetName = 'SessionFilter')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    # $params = $PSBoundParameters

    # Add all provided paging parameters
    # ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
    #     $params.Add($_, $PSCmdlet.PagingParameters.$_)
    # }

    $result = Invoke-ServiceNowRestMethod @PSBoundParameters

    If ( $result -and -not $Properties) {
        $type = $script:ServiceNowTable | Where-Object {$_.DbTableName -eq $Table} | Select-Object -ExpandProperty Type
        if ($type) {
            $result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $type) }
        }
    }

    $result
}
