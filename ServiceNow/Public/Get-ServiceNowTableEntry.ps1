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
        $Record = Get-ServiceNowTableEntry -Table u_customtable -MatchExact {number=$Number}
        Update-ServiceNowTableEntry -SysID $Record.sys_id -Table u_customtable -Values {comments='Ticket updated'}

        Utilize the returned object data with to provide the sys_id property required for updates and removals
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES

    #>
    param(
        # Table containing the entry we're deleting
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,

        # Machine name of the field to order by
        [parameter(mandatory = $false)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [string]$OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [parameter(mandatory = $false)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection = 'Desc',

        # Maximum number of records to return
        [parameter(mandatory = $false)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [int]$Limit = 10,

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory = $false)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [hashtable]$MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory = $false)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [hashtable]$MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [parameter(mandatory = $false)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [ValidateSet("true", "false", "all")]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $ServiceNowCredential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection
    )

    # Query Splat
    $newServiceNowQuerySplat = @{
        OrderBy        = $OrderBy
        MatchExact     = $MatchExact
        OrderDirection = $OrderDirection
        MatchContains  = $MatchContains
    }
    $Query = New-ServiceNowQuery @newServiceNowQuerySplat

    # Table Splat
    $getServiceNowTableSplat = @{
        Table         = $Table
        Query         = $Query
        Limit         = $Limit
        DisplayValues = $DisplayValues
    }

    # Update the Table Splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection) {
        $getServiceNowTableSplat.Add('Connection', $Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL) {
        $getServiceNowTableSplat.Add('ServiceNowCredential', $ServiceNowCredential)
        $getServiceNowTableSplat.Add('ServiceNowURL', $ServiceNowURL)
    }

    # Perform table query and return each object.  No fancy formatting here as this can pull tables with unknown default properties
    Get-ServiceNowTable @getServiceNowTableSplat
}
