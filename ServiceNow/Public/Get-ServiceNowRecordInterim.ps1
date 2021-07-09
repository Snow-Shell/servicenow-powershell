function Get-ServiceNowRecordInterim {
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(SupportsPaging)]
    Param(
        # Machine name of the field to order by
        [Parameter()]
        [string] $OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [Parameter()]
        [ValidateSet('Desc', 'Asc')]
        [string] $OrderDirection = 'Desc',

        # Fields to return
        [Parameter()]
        [Alias('Fields', 'Properties')]
        [string[]] $Property,

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [Parameter()]
        [hashtable] $MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [Parameter()]
        [hashtable] $MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [Alias('DisplayValues')]
        [string] $DisplayValue = 'true',

        [Parameter()]
        [hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    Write-Warning ('{0} will be deprecated in the near future.  Please use Get-ServiceNowRecord instead.' -f $PSCmdlet.MyInvocation.InvocationName)

    $table = $ServiceNowTable | Where-Object { $PSCmdlet.MyInvocation.InvocationName.ToLower().Replace('get-servicenow', '') -eq $_.ClassName.Replace(' ', '').ToLower() }

    $newServiceNowQuerySplat = @{
        OrderBy        = $OrderBy
        MatchExact     = $MatchExact
        OrderDirection = $OrderDirection
        MatchContains  = $MatchContains
    }

    $params = @{
        Table             = $table.Name
        Query             = (New-ServiceNowQuery @newServiceNowQuerySplat)
        DisplayValue      = $DisplayValue
        First             = $PSCmdlet.PagingParameters.First
        Skip              = $PSCmdlet.PagingParameters.Skip
        IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
        Connection        = $Connection
        ServiceNowSession = $ServiceNowSession
    }
    $result = Invoke-ServiceNowRestMethod @params

    If ( $result -and -not $Properties) {
        $result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $table.Type) }
    }
    $result
}