function Get-ServiceNowIncident{
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'UseConnectionObject', SupportsPaging)]
    Param (
        # Machine name of the field to order by
        [string]$OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [ValidateSet('Desc', 'Asc')]
        [string]$OrderDirection = 'Desc',

        # Maximum number of records to return
        [int]$Limit,

        # Fields to return
        [Alias('Fields')]
        [string[]]$Properties,

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [hashtable]$MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [hashtable]$MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(Mandatory = $true,
            ParameterSetName = 'SpecifyConnectionFields')]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'SpecifyConnectionFields')]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(
            ParameterSetName = 'UseConnectionObject')]
        [hashtable]$Connection = $Script:ConnectionObj
    )

    end {
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
            Table         = 'incident'
            Query         = $Query
            Fields        = $Properties
            DisplayValues = $DisplayValues
        }

        # Only add the Limit parameter if it was explicitly provided
        if ($PSBoundParameters.ContainsKey('Limit')) {
            $getServiceNowTableSplat.Add('Limit', $Limit)
        }

        # Add all provided paging parameters
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | Foreach-Object {
            $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
        }

        if ($PSCmdlet.ParameterSetName -eq 'UseConnectionObject') {
            $getServiceNowTableSplat.Add('Connection', $Connection)
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'SpecifyConnectionFields') {
            $uri = Get-ServiceNowFullUri -$ServiceNowUrl -Table $Table
            $getServiceNowTableSplat.Add('Uri', $uri)
            $getServiceNowTableSplat.Add('Credential',$Credential)
        }

        # Perform query and return each object in the format.ps1xml format
        $Result = Get-ServiceNowTable @getServiceNowTableSplat
        if (-not $Properties) {
            $Result | ForEach-Object{
                $_.PSObject.TypeNames.Insert(0,"ServiceNow.Incident")
            }
        }
        $Result
    }
}
