<#
.SYNOPSIS
    Export table records to a file

.DESCRIPTION
    Export table records in csv, xml, xls, xlsx, or pdf format.
    You can filter, sort, and choose specific properties to include in the report.
    Only basic authentication is supported.
    Export configurations, eg. row limit, can be found at System Properties->Import Export.

.PARAMETER Table
    Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
    You can also provide any table name ad hoc.

.PARAMETER Id
    Either the record sys_id or number.
    If providing just an Id, not with Table, the Id prefix will be looked up to find the table name.

.PARAMETER Property
    Return one or more specific fields otherwise all fields will be returned

.PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @(field, comparison operator, value) separated by a join, either 'and', 'or', or 'group'.
    For a complete list of comparison operators, see $script:ServiceNowOperator and use Name in your filter.
    See the examples.

.PARAMETER Sort
    Array or multidimensional array of fields to sort on.
    Each array should be of the format @(field, asc/desc).

.PARAMETER Path
    Path to output file including the file name.
    File extension must be either .csv, .xml, .xls, .xlsx, or .pdf.

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Export-ServiceNowRecord -Id RITM0010001 -Path .\out.pdf
    Export a specific record by number

.EXAMPLE
    Export-ServiceNowRecord -Table incident -Filter @('assigned_to.name', '-like', 'greg') -Path .\out.xlsx
    Export incident records where the assigned to user's name contains greg

.EXAMPLE
    $filter = @('state', '-eq', '1'),
                '-and',
              @('short_description','-like', 'powershell'),
                '-group',
              @('state', '-eq', '2')
    PS > Export-ServiceNowRecord -Table incident -Filter $filter -Path .\out.pdf
    Export incident records where state is New and short description contains the word powershell or state is In Progress.
    The first 2 filters are combined and then or'd against the last.

.EXAMPLE
    Export-ServiceNowRecord -Table 'Incident' -Filter @('opened_at', '-between', (Get-Date).AddMonths(-24), (get-date).AddMonths(-12)) -Path .\out.pdf
    Export incident records that were opened between 1 and 2 years ago

.EXAMPLE
    Export-ServiceNowRecord -Table incident -Filter @('state', '-eq', '1') -Sort @('opened_at', 'desc') -Path .\out.pdf
    Export incident records where state equals New and sort by the field opened_at descending

.LINK
    https://docs.servicenow.com/bundle/rome-platform-user-interface/page/use/navigation/task/navigate-using-url.html

.LINK
    https://docs.servicenow.com/bundle/sandiego-platform-administration/page/administer/exporting-data/task/t_ExportDirectlyFromTheURL.html#t_ExportDirectlyFromTheURL
#>
function Export-ServiceNowRecord {

    [CmdletBinding(DefaultParameterSetName = 'Id')]

    Param (
        [Parameter(ParameterSetName = 'Table', Mandatory)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'Table')]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'Id must be either a 32 character alphanumeric, ServiceNow sysid, or prefix/id, ServiceNow number.'
                }
            })]
        [Alias('sys_id', 'number')]
        [string] $Id,

        [Parameter()]
        [Alias('Fields', 'Properties')]
        [string[]] $Property,

        [Parameter()]
        [System.Collections.ArrayList] $Filter,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ArrayList] $Sort,

        [Parameter(Mandatory)]
        [ValidateScript({
                $allowedExts = '.csv', '.xml', '.pdf', '.xls', '.xlsx'
                if ([System.IO.Path]::GetExtension($_).ToLower() -in $allowedExts ) {
                    $true
                } else {
                    throw ('File extension must be one of {0}' -f ($allowedExts -join ', '))
                }
            })]
        [string] $Path,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    process {

        $newFilter = $Filter

        if ( $Table ) {
            $thisTable = $Table
        }

        if ( $Id ) {
            if ( $Id -match '^[a-zA-Z0-9]{32}$' ) {
                if ( -not $thisTable ) {
                    throw 'Providing sys_id for -Id requires a value for -Table.  Alternatively, provide an Id with a prefix, eg. INC1234567, and the table will be automatically determined.'
                }

                $newFilter = @('sys_id', '-eq', $Id)
            } else {
                if ( -not $thisTable ) {
                    # get table name from prefix if only Id was provided
                    $idPrefix = ($Id | Select-String -Pattern '^([a-zA-Z]+)([0-9]+$)').Matches.Groups[1].Value.ToLower()
                    Write-Debug "Id prefix is $idPrefix"
                    $thisTable = $script:ServiceNowTable | Where-Object { $_.NumberPrefix -and $idPrefix -eq $_.NumberPrefix } | Select-Object -ExpandProperty Name
                    if ( -not $thisTable ) {
                        throw ('The prefix for Id ''{0}'' was not found and the appropriate table cannot be determined.  Known prefixes are {1}.  Please provide a value for -Table.' -f $Id, ($ServiceNowTable.NumberPrefix.Where( { $_ }) -join ', '))
                    }
                }
                $newFilter = @('number', '-eq', $Id)
            }
        }

        $params = Get-ServiceNowAuth -S $ServiceNowSession
        $params.Body = @{
            'sysparm_query' = (New-ServiceNowQuery -Filter $newFilter -Sort $Sort)
        }

        if ($Property) {
            $params.Body.sysparm_fields = ($Property -join ',').ToLower()
        }

        $params.OutFile = $Path

        # need to tell SN the format
        $format = [System.IO.Path]::GetExtension($Path).Replace('.', '').ToUpper()

        # only exception to extension is the format rule
        if ( $format -eq 'XLS' ) { $format = 'EXCEL' }

        $params.Uri = 'https://{0}/{1}_list.do?{2}' -f $ServiceNowSession.Domain, $thisTable, $format

        Write-Verbose ($params | ConvertTo-Json)
        Invoke-RestMethod @params

    }
}
