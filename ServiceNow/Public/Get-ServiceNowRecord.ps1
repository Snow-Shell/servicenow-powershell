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

.PARAMETER Id
    Either the record sys_id or number.
    If providing just an Id, not with Table, the Id prefix will be looked up to find the table name.

.PARAMETER Name

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
    Some records may have associated custom variables, some may not.
    For instance, an RITM may have custom variables, but the associated tasks may not.
    A property named 'CustomVariable' will be added to the return object.

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
]
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
    [CmdletBinding(DefaultParameterSetName = 'Id', SupportsPaging)]
    [Alias('gsnr')]

    Param (
        [Parameter(ParameterSetName = 'Table', Mandatory)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'Table')]
        [Alias('sys_id', 'number')]
        [string] $Id,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [Alias('Fields', 'Properties')]
        [string[]] $Property,

        [Parameter()]
        [System.Collections.ArrayList] $Filter,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList] $Sort,

        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [Alias('DisplayValues')]
        [string] $DisplayValue = 'true',

        [Parameter()]
        [switch] $IncludeCustomVariable,

        [Parameter()]
        [hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    # it's easier this way to pass everything to invoke-servicenowrestmethod given paging params, etc
    $invokeParams = $PSBoundParameters
    $invokeParams.Remove('IncludeCustomVariable') | Out-Null
    $invokeParams.Remove('Id') | Out-Null
    $invokeParams.Remove('Name') | Out-Null

    if ( $Id ) {
        if ( $Id -match '[a-zA-Z0-9]{32}' ) {
            if ( $PSCmdlet.ParameterSetName -like '*Id' ) {
                throw 'Providing sys_id for -Id requires a value for -Table.  Alternatively, provide an Id with a prefix, eg. INC1234567.'
            }

            $idFilter = @('sys_id', '-eq', $Id)
        }
        else {
            if ( $PSCmdlet.ParameterSetName -like '*Id' ) {
                # get table name from prefix if only Id was provided
                $thisTable = $script:ServiceNowTable | Where-Object { $_.NumberPrefix -and $Id.ToLower().StartsWith($_.NumberPrefix) } | Select-Object -ExpandProperty Name
                if ( $thisTable ) {
                    $invokeParams.Table = $thisTable
                }
                else {
                    throw ('Prefix not found for Id ''{0}''.  Known prefixes are {1}.' -f $Id, ($ServiceNowTable.NumberPrefix.Where( { $_ }) -join ', '))
                }
            }
            $idFilter = @('number', '-eq', $Id)
        }

        if ( $invokeParmas.Filter ) {
            $invokeParams.Filter = $invokeParams.Filter, 'and', $idFilter
        }
        else {
            $invokeParams.Filter = $idFilter
        }
    }
    
    if ( $Name ) {
        # determine the field we should compare for 'name' and add the filter
        $thisNameField = $script:ServiceNowTable | Where-Object { $_.Name.ToLower() -eq $Table.ToLower() -or $_.ClassName.ToLower() -eq $Table.ToLower() } | Select-Object -ExpandProperty TableNameField
        if ( $thisNameField ) {
            if ( $invokeParmas.Filter ) {
                $invokeParams.Filter = $invokeParams.Filter, 'and', @($thisNameField, '-like', $Name)
            }
            else {
                $invokeParams.Filter = @($thisNameField, '-like', $Name)
            }
        }
    }

    $addedSysIdProp = $false
    # we need the sys_id value in order to get custom var data
    # add it in if specific properties were requested and not part of the list
    if ( $IncludeCustomVariable.IsPresent ) {
        if ( $Property -and 'sys_id' -notin $Property ) {
            $invokeParams.Property += 'sys_id'
            $addedSysIdProp = $true
        }
    }

    if ( $Table -eq 'attachment' ) {
        $invokeParams.Remove('Table') | Out-Null
        $invokeParams.UriLeaf = '/attachment'
    }
    
    $result = Invoke-ServiceNowRestMethod @invokeParams

    if ( $result ) {
        if ( $IncludeCustomVariable.IsPresent ) {
            # for each record, get the variable names and then get the variable values
            foreach ($record in $result) {
                $customVarParams = @{
                    Table    = 'sc_item_option_mtom'
                    Property = 'sc_item_option.item_option_new.name', 'sc_item_option.item_option_new.sys_name', 'sc_item_option.item_option_new.type'
                    Filter   = @('request_item', '-eq', $record.sys_id), 'and', @('sc_item_option.item_option_new.type', '-in', '1,2,3,4,5,6,7,8,9,10,16,18,21,22')
                    First    = 1000 # hopefully there isn't more custom vars than this, but we need to overwrite the default of 10
                }
                $customVars = Get-ServiceNowRecord @customVarParams

                if ( $customVars ) {
                    $customValueParams = @{
                        Table    = $Table
                        Filter   = @('sys_id', '-eq', $record.sys_id)
                        Property = $customVars.'sc_item_option.item_option_new.name' | ForEach-Object { "variables.$_" }
                    }
                    $customValues = Get-ServiceNowRecord @customValueParams

                    # custom vars will be a separate property on the return object
                    $customVarsOut = $customVars | ForEach-Object {
                        $varName = $_.'sc_item_option.item_option_new.name'
                        [pscustomobject] @{
                            Name        = 'variables.{0}' -f $varName
                            DisplayName = $_.'sc_item_option.item_option_new.sys_name'
                            Value       = $customValues."variables.$varName"
                        }
                    }
                    $record | Add-Member @{
                        'CustomVariable' = $customVarsOut
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

            # format the results
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
