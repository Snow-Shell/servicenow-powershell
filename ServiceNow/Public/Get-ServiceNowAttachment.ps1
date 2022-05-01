
Function Get-ServiceNowAttachment {
    <#
    .SYNOPSIS
        Retrieve attachment details

    .DESCRIPTION
        Retrieve attachment details via table record or by advanced filtering.

    .PARAMETER Table
        Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
        You can also provide any table name ad hoc.

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
        Table, Id

    .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName = 'Filter', SupportsPaging)]

    param(
        [Parameter(ParameterSetName = 'Table', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Table', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $Id,

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

    begin {}

    process	{
        $Params = @{
            UriLeaf           = '/attachment'
            First             = $PSCmdlet.PagingParameters.First
            Skip              = $PSCmdlet.PagingParameters.Skip
            IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ( $PSCmdlet.ParameterSetName -in 'Table', 'Id' ) {
            $GetParams = @{
                Id                = $Id
                Property          = 'sys_class_name', 'sys_id'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }
            if ( $Table ) {
                $GetParams.Table = $Table
            }
            $TableRecord = Get-ServiceNowRecord @GetParams

            if ( -not $TableRecord ) {
                Write-Error "Record not found for Id '$Id'"
                continue
            }

            # perform lookup for known table names which might be different than sys_class_name
            $TableName = $script:ServiceNowTable | Where-Object { $_.Name.ToLower() -eq $TableRecord.sys_class_name.ToLower() -or $_.ClassName.ToLower() -eq $TableRecord.sys_class_name.ToLower() } | Select-Object -ExpandProperty Name
            if ( $TableName ) {
                $Params.Filter = @(@('table_name', '-eq', $TableName), 'and', @('table_sys_id', '-eq', $TableRecord.sys_id))
            } else {
                $Params.Filter = @(@('table_name', '-eq', $TableRecord.sys_class_name), 'and', @('table_sys_id', '-eq', $TableRecord.sys_id))
            }
        }

        if ( $FileName ) {
            if ( $Params.Filter ) {
                $Params.Filter += 'and', @('file_name', '-like', $FileName)
            } else {
                $Params.Filter = @('file_name', '-like', $FileName)
            }
        }

        if ( $Filter ) {
            if ( $Params.Filter ) {
                $Params.Filter += 'and', $Filter
            } else {
                $Params.Filter = $Filter
            }
        }

        $Response = Invoke-ServiceNowRestMethod @Params

        if ( $Response ) {
            $Response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'ServiceNow.Attachment') }
            $Response
        }

    }

    end {}
}
