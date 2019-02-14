function Get-ServiceNowUserGroup{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName, SupportsPaging)]
    Param(
        # Machine name of the field to order by
        [Parameter(Mandatory = $false)]
        [string]$OrderBy = 'name',

        # Direction of ordering (Desc/Asc)
        [Parameter(Mandatory = $false)]
        [ValidateSet('Desc', 'Asc')]
        [string]$OrderDirection = 'Desc',

        # Maximum number of records to return
        [Parameter(Mandatory = $false)]
        [int]$Limit,

        # Fields to return
        [Parameter(Mandatory = $false)]
        [Alias('Fields')]
        [string[]]$Properties,

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [Parameter(Mandatory = $false)]
        [hashtable]$MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [Parameter(Mandatory = $false)]
        [hashtable]$MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [Parameter(Mandatory = $false)]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    # Query Splat
    $newServiceNowQuerySplat = @{
        OrderBy        = $OrderBy
        OrderDirection = $OrderDirection
        MatchExact     = $MatchExact
        MatchContains  = $MatchContains
    }
    $Query = New-ServiceNowQuery @newServiceNowQuerySplat

    # Table Splat
    $getServiceNowTableSplat = @{
        Table         = 'sys_user_group'
        Query         = $Query
        Fields        = $Properties
        DisplayValues = $DisplayValues
    }

    # Update the splat if the parameters have values
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
        $Result | ForEach-Object{$_.PSObject.TypeNames.Insert(0,"ServiceNow.UserAndUserGroup")}
    }
    $Result
}
