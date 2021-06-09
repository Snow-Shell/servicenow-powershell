<#
.SYNOPSIS
    Retrieves records for the specified table

.DESCRIPTION
    Retrieve records from any table with the option to filter, sort, and choose fields.
    Given you know the table name, you shouldn't need any other 'Get-' function.
    Paging is supported with -First, -Skip, and -IncludeTotalCount.

.PARAMETER Table
    Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
    You can also provide any table name ad hoc.

.PARAMETER Property
    Limit the fields returned to this list

.PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @(field, comparison operator, value) separated by a join, either 'and', 'or', or 'group'.
    For a complete list of comparison operators, see $script:ServiceNowOperator and use Name in your filter.
    See the examples.
    Also, see https://docs.servicenow.com/bundle/quebec-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html
    for how to represent date values with javascript.

.PARAMETER Sort
    Array or multidimensional array of fields to sort on.
    Each array should be of the format @(field, asc/desc).

.PARAMETER DisplayValue
    Option to display values for reference fields.
    'false' will only retrieve the reference
    'true' will only retrieve the underlying value
    'all' will retrieve both.  This is helpful when trying to translate values for a query.

.PARAMETER IncludeCustomVariable
    Include custom variables in the return object.

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Get-ServiceNowRecord -Table incident -Filter @('state', '-eq', '1'), 'or', @('short_description','-like', 'powershell')
    Get incident records where state equals New or short description contains the word powershell

.EXAMPLE
    $filter = @('state', '-eq', '1'),
                '-and',
              @('short_description','-like', 'powershell'),
                '-group',
              @('state', '-eq', '2')
    PS > Get-ServiceNowRecord -Table incident -Filter $filter
    Get incident records where state equals New and short description contains the word powershell or state equals In Progress.
    The first 2 filters are combined and then or'd against the last.

.EXAMPLE
    Get-ServiceNowRecord -Table incident -Filter @('state', '-eq', '1') -Sort @('opened_at', 'desc'), @('state')
    Get incident records where state equals New and first sort by the field opened_at descending and then sort by the field state ascending

.EXAMPLE
    Get-ServiceNowRecord -Table 'change request' -Filter @('opened_at', '-ge', 'javascript:gs.daysAgoEnd(30)')
    Get change requests opened in the last 30 days.  Use class name as opposed to table name.

.EXAMPLE
    Get-ServiceNowRecord -Table 'change request' -First 100 -IncludeTotalCount
    Get all change requests, paging 100 at a time.

.EXAMPLE
    Get-ServiceNowRecord -Table 'change request' -IncludeCustomVariable -First 5
    Get the first 5 change requests and retrieve custom variable info

.INPUTS
    None

.OUTPUTS
    System.Management.Automation.PSCustomObject

.LINK
    https://docs.servicenow.com/bundle/quebec-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html
#>
function Get-ServiceNowRecord {

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'SessionFilter', SupportsPaging)]

    Param (
        [parameter(Mandatory)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter()]
        [Alias('Fields', 'Properties')]
        [string[]] $Property,

        [parameter(ParameterSetName = 'AutomationFilter')]
        [parameter(ParameterSetName = 'SessionFilter')]
        [System.Collections.ArrayList] $Filter,

        [parameter(ParameterSetName = 'AutomationFilter')]
        [parameter(ParameterSetName = 'SessionFilter')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList] $Sort,

        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [Alias('DisplayValues')]
        [string] $DisplayValue = 'true',

        [Parameter()]
        [switch] $IncludeCustomVariable,

        [Parameter(Mandatory, ParameterSetName = 'AutomationQuery')]
        [parameter(Mandatory, ParameterSetName = 'AutomationFilter')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Connection,

        [Parameter(ParameterSetName = 'SessionQuery')]
        [Parameter(ParameterSetName = 'SessionFilter')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    $invokeParams = @{
        Table             = $Table
        Properties        = $Property
        Filter            = $Filter
        Sort              = $Sort
        DisplayValues     = $DisplayValue
        Connection        = $Connection
        ServiceNowSession = $ServiceNowSession
    }

    $addedSysIdProp = $false

    # we need the sys_id value in order to get custom var data
    # add it in if specific properties were requested and not part of the list
    if ( $IncludeCustomVariable.IsPresent ) {
        if ( $Property -and 'sys_id' -notin $Property ) {
            $invokeParams.Properties += 'sys_id'
            $addedSysIdProp = $true
        }
    }

    $result = Invoke-ServiceNowRestMethod @invokeParams

    if ( $result ) {
        if ( $IncludeCustomVariable.IsPresent ) {
            # for each record, get the variable names and then get the variable values
            foreach ($record in $result) {
                $customVarParams = @{
                    Table      = 'sc_item_option_mtom'
                    Properties = 'sc_item_option.item_option_new.name', 'sc_item_option.item_option_new.sys_name', 'sc_item_option.item_option_new.type'
                    Filter     = @('request_item', '-eq', $record.sys_id), 'and', @('sc_item_option.item_option_new.type', '-in', '1,2,3,4,5,6,7,8,9,10,16,18,21,22')
                    First      = 1000 # hopefully there isn't more custom vars than this...
                }
                $customVars = Get-ServiceNowRecord @customVarParams

                if ( $customVars ) {
                    $customValues = Get-ServiceNowRecord -Table $Table -Filter @('sys_id', '-eq', $record.sys_id) -Properties ('variables.' + ($customVars.'sc_item_option.item_option_new.name' -join ',variables.'))
                    $customValues | Get-Member -MemberType NoteProperty | ForEach-Object {
                        $record | Add-Member @{
                            $_.Name = $customValues."$($_.Name)"
                        }
                    }
                }

                if ( $addedSysIdProp ) {
                    $record | Select-Object -Property * -ExcludeProperty sys_id
                }
                else {
                    $record
                }
            }
        }
        else {

            if ( -not $Property ) {
                $type = $script:ServiceNowTable | Where-Object { $_.Name -eq $Table -or $_.ClassName -eq $Table } | Select-Object -ExpandProperty Type
                if ($type) {
                    $result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $type) }
                }
            }
            $result
        }
    }

}
