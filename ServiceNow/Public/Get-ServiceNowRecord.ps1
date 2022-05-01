function Get-ServiceNowRecord { 
    <#
    .SYNOPSIS
        Retrieves records for any and all tables

    .DESCRIPTION
        Retrieve records from any table with the option to filter, sort, choose fields, and more.
        Paging is supported with -First, -Skip, and -IncludeTotalCount.

    .PARAMETER Table
        Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
        You can also provide any table name ad hoc.

    .PARAMETER Id
        Either the record sys_id or number.
        If providing just an Id, not with Table, the Id prefix will be looked up to find the table name.

    .PARAMETER ParentID
        The sys_id or number of the parent record.
        For example, to get catalog tasks for a requested item, provide the RITM number as ParentID and catalog task as the Table.

    .PARAMETER Description
        Filter results based on the 'description' field.  The field will be different for each table.
        For many tables it will be short_description, but, for instance, the User table will be 'Name'.
        For unknown tables, the field will be 'short_description'.
        The comparison performed is a 'like'.

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

    .PARAMETER AsValue
        Return the underlying value instead of pscustomobject.
        Only valid when the Property parameter is set to 1 item.
        Helpful when retrieving sys_id for example.

    .PARAMETER Connection
        Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

    .PARAMETER ServiceNowSession
        ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

    .EXAMPLE
        Get-ServiceNowRecord RITM0010001
        Get a specific record by number

    .EXAMPLE
        Get-ServiceNowRecord -Id RITM0010001 -Property 'short_description','sys_id'
        Get specific properties for a record

    .EXAMPLE
        Get-ServiceNowRecord -Table 'Catalog Task' -ParentId 'RITM0010001'
        Get tasks for the parent requested item

    .EXAMPLE
        Get-ServiceNowRecord -Table incident -Filter @('state', '-eq', '1') -Description 'powershell'
        Get incident records where state equals New or short description contains the word powershell

    .EXAMPLE
        Get-ServiceNowRecord -Table incident -Filter @('assigned_to.name', '-like', 'greg')
        Get incident records where the assigned to user's name contains greg

    .EXAMPLE
        $filter = @('state', '-eq', '1'),
                    '-and',
                  @('short_description','-like', 'powershell'),
                    '-group',
                  @('state', '-eq', '2')
        PS > Get-ServiceNowRecord -Table incident -Filter $filter
        Get incident records where state is New and short description contains the word powershell or state is In Progress.
        The first 2 filters are combined and then or'd against the last.

    .EXAMPLE
        Get-ServiceNowRecord -Table 'Incident' -Filter @('opened_at', '-between', (Get-Date).AddMonths(-24), (get-date).AddMonths(-12)) -IncludeTotalCount
        Get all incident records that were opened between 1 and 2 years ago

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

    .EXAMPLE
        Get-ServiceNowRecord -Table 'cmdb_ci' -Property sys_id -First 1 -AsValue
        Get the underlying value for a property instead of a pscustomobject where the value needs to be extracted

    .EXAMPLE
        gsnr RITM0010001
        Get a specific record by number using the function alias

    .INPUTS
        Id

    .OUTPUTS
        PSCustomObject.  If -AsValue is used, the type will be the selected field.

    .LINK
        https://docs.servicenow.com/bundle/quebec-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html

    .LINK
        https://developer.servicenow.com/dev.do#!/reference/api/sandiego/rest/c_TableAPI#table-GET
    #>


    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'Id', SupportsPaging)]
    [Alias('gsnr')]

    param (
        [Parameter(ParameterSetName = 'Table', Mandatory)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Parameter(ParameterSetName = 'Table', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'Id must be either a 32 character alphanumeric, ServiceNow sysid, or prefix/id, ServiceNow number.'
                }
            })]
        [Alias('sys_id', 'number')]
        [string] $ID,

        [Parameter()]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'ParentID must be either a 32 character alphanumeric, ServiceNow sysid, or prefix/id, ServiceNow number.'
                }
            })]
        [string] $ParentID,

        [Parameter()]
        [string] $Description,

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
        [switch] $AsValue,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {

        $InvokeParams = @{
            Filter            = $Filter
            Property          = $Property
            Sort              = $Sort
            DisplayValue      = $DisplayValue
            First             = $PSCmdlet.PagingParameters.First
            Skip              = $PSCmdlet.PagingParameters.Skip
            IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ( $Table ) {
            $ThisTable = $script:ServiceNowTable | Where-Object { $_.Name.ToLower() -eq $Table.ToLower() -or $_.ClassName.ToLower() -eq $Table.ToLower() }
            if ( -not $ThisTable ) {
                # we aren't aware of this table, create default config
                $ThisTable = @{
                    Name             = $Table
                    ClassName        = $null
                    Type             = $null
                    NumberPrefix     = $null
                    DescriptionField = $null
                }
            }
        }
    }

    process {

        if ( $ID ) {
            if ( $ID -match '^[a-zA-Z0-9]{32}$' ) {
                if ( -not $ThisTable ) {
                    throw 'Providing sys_id for -Id requires a value for -Table.  Alternatively, provide an Id with a prefix, eg. INC1234567, and the table will be automatically determined.'
                }

                $IDFilter = @('sys_id', '-eq', $ID)
            } else {
                if ( -not $ThisTable ) {
                    # get table name from prefix if only Id was provided
                    $IDPrefix = ($ID | Select-String -Pattern '^([a-zA-Z]+)([0-9]+$)').Matches.Groups[1].Value.ToLower()
                    Write-Debug "Id prefix is $IDPrefix"
                    $ThisTable = $script:ServiceNowTable | Where-Object { $_.NumberPrefix -and $IDPrefix -eq $_.NumberPrefix }
                    if ( -not $ThisTable ) {
                        throw ('The prefix for Id ''{0}'' was not found and the appropriate table cannot be determined.  Known prefixes are {1}.  Please provide a value for -Table.' -f $ID, ($ServiceNowTable.NumberPrefix.Where( { $_ }) -join ', '))
                    }
                }
                $IDFilter = @('number', '-eq', $ID)
            }

            if ( $InvokeParams.Filter ) {
                $InvokeParams.Filter = $InvokeParams.Filter, 'and', $IDFilter
            } else {
                $InvokeParams.Filter = $IDFilter
            }

        }

        # we have the table, update the params
        $InvokeParams.Table = $ThisTable.Name

        if ( $ParentID ) {
            if ( $ParentID -match '^[a-zA-Z0-9]{32}$' ) {
                $ParentIDFilter = @('parent.sys_id', '-eq', $ParentID)
            } else {
                $ParentIDFilter = @('parent.number', '-eq', $ParentID)
            }

            if ( $InvokeParams.Filter ) {
                $InvokeParams.Filter = $InvokeParams.Filter, 'and', $ParentIDFilter
            } else {
                $InvokeParams.Filter = $ParentIDFilter
            }
        }

        if ( $Description ) {
            # determine the field we should compare for 'description' and add the filter
            if ( -not $ThisTable.DescriptionField ) {
                Write-Warning ('We do not have table ''{0}'' in the config; short_description will be used as the description field' -f $ThisTable.Name)
                $ThisTable.DescriptionField = 'short_description'
            }

            if ( $InvokeParams.Filter ) {
                $InvokeParams.Filter = $InvokeParams.Filter, 'and', @($ThisTable.DescriptionField, '-like', $Description)
            } else {
                $InvokeParams.Filter = @($ThisTable.DescriptionField, '-like', $Description)
            }
        }

        $AddedSysIDProp = $false
        # we need the sys_id value in order to get custom var data
        # add it in if specific properties were requested and not part of the list
        if ( $IncludeCustomVariable ) {
            if ( $Property -and 'sys_id' -notin $Property ) {
                $InvokeParams.Property += 'sys_id'
                $AddedSysIDProp = $true
            }
        }

        # should use Get-ServiceNowAttachment, but put this here for ease of access
        if ( $ThisTable.Name -eq 'attachment' ) {
            Write-Warning 'For attachments, use Get-ServiceNowAttachment'
            $InvokeParams.Remove('Table') | Out-Null
            $InvokeParams.UriLeaf = '/attachment'
        }

        $Result = Invoke-ServiceNowRestMethod @InvokeParams

        if ( $IncludeCustomVariable ) {

            # suppress warning when getting total count
            $ExistingWarning = $WarningPreference
            $WarningPreference = 'SilentlyContinue'

            # for each record, get the variable names and then get the variable values
            foreach ($Record in $Result) {

                $CustomVarParams = @{
                    Table             = 'sc_item_option_mtom'
                    Filter            = @('request_item', '-eq', $Record.sys_id), 'and', @('sc_item_option.item_option_new.type', '-in', '1,2,3,4,5,6,7,8,9,10,16,18,21,22,26')
                    Property          = 'sc_item_option.item_option_new.name', 'sc_item_option.value', 'sc_item_option.item_option_new.type', 'sc_item_option.item_option_new.question_text'
                    IncludeTotalCount = $true
                }

                $CustomVarsOut = Get-ServiceNowRecord @CustomVarParams

                $Record | Add-Member @{
                    'CustomVariable' = $CustomVarsOut | Select-Object -Property `
                    @{
                        'n' = 'Name'
                        'e' = { $_.'sc_item_option.item_option_new.name' }
                    },
                    @{
                        'n' = 'Value'
                        'e' = { $_.'sc_item_option.value' }
                    },
                    @{
                        'n' = 'DisplayName'
                        'e' = { $_.'sc_item_option.item_option_new.question_text' }
                    },
                    @{
                        'n' = 'Type'
                        'e' = { $_.'sc_item_option.item_option_new.type' }
                    }
                }

                if ( $AddedSysIDProp ) {
                    $Record | Select-Object -Property * -ExcludeProperty sys_id
                } else {
                    $Record
                }
            }

            $WarningPreference = $ExistingWarning

        } else {

            # format the results
            if ( $Property ) {
                if ( $Property.Count -eq 1 -and $AsValue ) {
                    $PropName = $Result | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | Select-Object -exp Name
                    $Result | Select-Object -ExpandProperty $PropName
                } else {
                    $Result
                }
            } else {
                if ($ThisTable.Type) {
                    $Result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $ThisTable.Type) }
                }
                $Result
            }
        }
    }
}
