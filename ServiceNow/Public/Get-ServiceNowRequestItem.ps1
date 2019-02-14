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
    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
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

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
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
        Table         = 'sc_req_item'
        Query         = $Query
        Fields        = $Properties
        DisplayValues = $DisplayValues
    }

    # Update the Table Splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection) {
        $getServiceNowTableSplat.Add('Connection', $Connection)
    }
    elseif ($null -ne $PSBoundParameters.Credential -and $null -ne $PSBoundParameters.ServiceNowURL) {
        $getServiceNowTableSplat.Add('Credential', $Credential)
        $getServiceNowTableSplat.Add('ServiceNowURL', $ServiceNowURL)
    }

    # Only add the Limit parameter if it was explicitly provided
    if ($PSBoundParameters.ContainsKey('Limit')) {
        $getServiceNowTableSplat.Add('Limit', $Limit)
    }

    # Add all provided paging parameters
    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | Foreach-Object {
        $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
    }

    # Perform query and return each object in the format.ps1xml format
    $Result = Get-ServiceNowTable @getServiceNowTableSplat
    If (-not $Properties) {
        $Result | ForEach-Object {$_.PSObject.TypeNames.Insert(0,'ServiceNow.RequestItem')}
    }
    $Result
}
