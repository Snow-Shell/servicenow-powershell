function Get-ServiceNowConfigurationItem {
    param(
        # Machine name of the field to order by
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$OrderBy='name',

        # Direction of ordering (Desc/Asc)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection='Desc',

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$MatchExact=@{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$MatchContains=@{},

        # Whether to return manipulated display values rather than actual database values.
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [ValidateSet("true","false", "all")]
        [string]$DisplayValues='true',

        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $ServiceNowCredential,

        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceNowURL,

        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection
    )

    # Query Splat
    $newServiceNowQuerySplat = @{
        OrderBy         = $OrderBy
        MatchExact      = $MatchExact
        OrderDirection  = $OrderDirection
        MatchContains   = $MatchContains
    }
    $Query = New-ServiceNowQuery @newServiceNowQuerySplat

    # Table Splat
    $getServiceNowTableSplat = @{
        Table           = 'cmdb_ci'
        Query           = $Query
        Limit           = $Limit
        DisplayValues   = $DisplayValues
    }

    # Update the Table Splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection)
    {
        $getServiceNowTableSplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL)
    {
         $getServiceNowTableSplat.Add('ServiceNowCredential',$ServiceNowCredential)
         $getServiceNowTableSplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    # Add all provided paging parameters
    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | Foreach-Object {
        $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
    }

    # Perform query and return each object in the format.ps1xml format
    $Result = Get-ServiceNowTable @getServiceNowTableSplat
    $Result | ForEach-Object{$_.PSObject.TypeNames.Insert(0,"ServiceNow.ConfigurationItem")}
    $Result
}
