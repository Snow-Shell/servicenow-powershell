function Get-ServiceNowTableEntry {
    <#
    .SYNOPSIS
        Wraps Get-ServiceNowQuery & Get-ServiceNowTable for easier custom table queries
    .DESCRIPTION
        Wraps Get-ServiceNowQuery & Get-ServiceNowTable for easier custom table queries.  No formatting is provided on output.  Every property is returned by default.
    .EXAMPLE
        Get-ServiceNowTableEntry -Table sc_req_item -Limit 1

        Returns one request item (RITM) from the sc_req_item table
    .EXAMPLE
        $Record = Get-ServiceNowTableEntry -Table u_customtable -MatchExact @{number=$Number}
        Update-ServiceNowTableEntry -SysID $Record.sys_id -Table u_customtable -Values @{comments='Ticket updated'}

        Utilize the returned object data with to provide the sys_id property required for updates and removals
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES

    #>

    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
    param(
        # Table containing the entry we're deleting
        [parameter(Mandatory)]
        [string]$Table,

        # Machine name of the field to order by
        [parameter()]
        [string]$OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [parameter()]
        [ValidateSet('Desc', 'Asc')]
        [string]$OrderDirection = 'Desc',

        # Maximum number of records to return
        [parameter()]
        [int]$Limit,

        # Fields to return
        [Parameter()]
        [Alias('Fields')]
        [string[]]$Properties,

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter()]
        [hashtable]$MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter()]
        [hashtable]$MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [parameter()]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    Get-ServiceNowTable @PSBoundParameters -Table $Table
}
