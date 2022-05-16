
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

    .INPUTS
    Table, ID

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(SupportsPaging)]

    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'Id must be either a 32 character alphanumeric, ServiceNow sysid, or prefix/id, ServiceNow number.'
                }
            })]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $ID,

        [parameter()]
        [string] $FileName,

        [Parameter()]
        [System.Collections.ArrayList] $Filter,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList] $Sort,

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

        if ( $Table ) {
            $thisTableName = $ServiceNowTable.Where{ $_.Name -eq $Table -or $_.ClassName -eq $Table } | Select-Object -ExpandProperty Name
            if ( -not $thisTableName ) {
                $thisTableName = $Table
            }
        }

        if ( $ID -match '^[a-zA-Z0-9]{32}$' ) {
            if ( -not $thisTableName ) {
                Write-Error 'Providing sys_id for -Id requires a value for -Table.  Alternatively, provide an -Id with a prefix, eg. INC1234567, and the table will be automatically determined.'
                Continue
            }

            $thisSysId = $ID

        } else {
            if ( -not $thisTableName ) {
                $thisTable = $ServiceNowTable.Where{ $_.NumberPrefix -and $ID.ToLower().StartsWith($_.NumberPrefix) }
                if ( $thisTable ) {
                    $thisTableName = $thisTable.Name
                } else {
                    Write-Error ('The prefix for Id ''{0}'' was not found and the appropriate table cannot be determined.  Known prefixes are {1}.  Please provide a value for -Table.' -f $ID, ($ServiceNowTable.NumberPrefix.Where( { $_ }) -join ', '))
                    Continue
                }
            }

            $getParams = @{
                Table             = $thisTableName
                Id                = $ID
                Property          = 'sys_id'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            $tableRecord = Get-ServiceNowRecord @getParams

            if ( -not $tableRecord ) {
                Write-Error "Record not found for ID '$ID'"
                continue
            }

            $thisSysId = $tableRecord.sys_id
        }

        $params.Filter = @(@('table_name', '-eq', $thisTableName), 'and', @('table_sys_id', '-eq', $thisSysId))

        if ( $FileName ) {
            if ( $params.Filter ) {
                $params.Filter += 'and', @('file_name', '-like', $FileName)
            } else {
                $params.Filter = @('file_name', '-like', $FileName)
            }
        }

        if ( $Filter ) {
            if ( $params.Filter ) {
                $params.Filter += 'and', $Filter
            } else {
                $params.Filter = $Filter
            }
        }

        $response = Invoke-ServiceNowRestMethod @params

        if ( $response ) {
            $response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'ServiceNow.Attachment') }
            $response
        }

    }
}
