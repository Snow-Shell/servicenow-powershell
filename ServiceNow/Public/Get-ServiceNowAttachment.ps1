
Function Get-ServiceNowAttachment {
    <#

    .SYNOPSIS
    Retrieve attachment details

    .DESCRIPTION
    Retrieve attachment details via table record or by advanced filtering.

    .PARAMETER Table
    Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
    You can also provide any table name ad hoc.
    If using pipeline and not getting the expected response, most likely the table name and class do not match.
    In this case, provide this value directly.

    .PARAMETER Id
    Either the record sys_id or number.
    If providing just an Id, not with Table, the Id prefix will be looked up to find the table name.

    .PARAMETER FileName
    Filter for a specific file name or part of a file name.

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

    .PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

    .PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

    .EXAMPLE
    Get-ServiceNowAttachment -Id 'INC1234567'

    Get attachment details for a specific record

    .EXAMPLE
    Get-ServiceNowAttachment -Id 'INC1234567' -FileName image.jpg

    Get attachment details for a specific record where file names match all or part of image.jpg

    .EXAMPLE
    Get-ServiceNowAttachment -Filter @('size_bytes', '-gt', '1000000')

    Get attachment details where size is greater than 1M.

    .EXAMPLE
    Get-ServiceNowRecord -table incident -first 5 | Get-ServiceNowAttachment

    Get attachment details from multiple records

    .INPUTS
    Table, ID

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(SupportsPaging)]

    Param(
        [Parameter(ParameterSetName = 'Table', Mandatory)]
        [Parameter(ParameterSetName = 'TableId', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        # validation not needed as Invoke-TableIdLookup will handle it with -AsSysId
        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipeline, Position = 0)]
        [Parameter(ParameterSetName = 'TableId', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $ID,

        [parameter()]
        [string] $FileName,

        [Parameter()]
        [object[]] $Filter,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [object[]] $Sort,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {
        $params = @{
            UriLeaf           = '/attachment'
            First             = $PSCmdlet.PagingParameters.First
            Skip              = $PSCmdlet.PagingParameters.Skip
            IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }
    }

    process	{

        $thisTable, $thisID = Invoke-TableIdLookup -T $Table -I $ID -AsSysId -C $Connection -S $ServiceNowSession

        $params.Filter = @('table_name', '-eq', $thisTable.Name), 'and', @('table_sys_id', '-eq', $thisID)

        if ( $PSBoundParameters.ContainsKey('FileName') ) {
            $params.Filter += 'and', @('file_name', '-like', $FileName)
        }

        if ( $PSBoundParameters.ContainsKey('Filter') ) {
            $params.Filter += 'and', $Filter
        }

        $response = Invoke-ServiceNowRestMethod @params

        if ( $response ) {
            $response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'ServiceNow.Attachment') }
            $response
        }

    }
}
