<#
.SYNOPSIS
    Retrieves records for the specified table

.DESCRIPTION
    Retrieve records from any table with the option to filter, sort, and choose fields.
    Given you know the table name, you shouldn't need any other 'Get-' function.

.PARAMETER Table
    Name of the table to be queried, by either table name or class name

.PARAMETER Properties
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

.PARAMETER DisplayValues
    Option to display values for reference fields.
    'false' will only retrieve the reference
    'true' will only retrieve the underlying value
    'all' will retrieve both.  This is helpful when trying to translate values for a query.

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Get-ServiceNowRecord -Table incident -Filter @('state', '-eq', '1'), 'or', @('short_description','-like', 'powershell')
    Get incident records where state equals New or short description contains the word powershell

.EXAMPLE
    $filter = @('state', '-eq', '1'),
                'and',
              @('short_description','-like', 'powershell'),
                'group',
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
        [ValidateNotNullOrEmpty()]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter()]
        [Alias('Fields')]
        [string[]] $Properties,

        [parameter(ParameterSetName = 'AutomationFilter')]
        [parameter(ParameterSetName = 'SessionFilter')]
        [System.Collections.ArrayList] $Filter,

        [parameter(ParameterSetName = 'AutomationFilter')]
        [parameter(ParameterSetName = 'SessionFilter')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList] $Sort,

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

    $result = Invoke-ServiceNowRestMethod @PSBoundParameters

    If ( $result -and -not $Properties) {
        $type = $script:ServiceNowTable | Where-Object {$_.Name -eq $Table -or $_.ClassName -eq $Table} | Select-Object -ExpandProperty Type
        if ($type) {
            $result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $type) }
        }
    }

    $result
}
