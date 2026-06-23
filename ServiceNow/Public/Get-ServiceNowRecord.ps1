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

.PARAMETER ParentId
    The sys_id or number of the parent record.
    For example, to get catalog tasks for a requested item, provide the RITM number as ParentId and catalog task as the Table.

.PARAMETER Description
    Filter results based on the 'description' field.  The field will be different for each table.
    For many tables it will be short_description, but, for instance, the User table will be 'Name'.
    For unknown tables, the field will be 'short_description'.
    The comparison performed is a 'like'.

.PARAMETER Property
    Return one or more specific fields otherwise all fields will be returned.
    Field names are case sensitive.

.PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @(field, comparison operator, value) separated by a join, either 'and', 'or', or 'group'.
    For a complete list of comparison operators, see $script:ServiceNowOperator and use Name in your filter.
    See the examples.

.PARAMETER FilterString
    A string representation of the filter.  This is useful when the filter is complex and hard to specify as an array.
    Retrieve the filter string from the ServiceNow UI via right click on the filter and selecting 'Copy query'.

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
    You can get the value with $return.CustomVariable.CustomVarName.Value.

.PARAMETER AsValue
    Return the underlying value instead of pscustomobject.
    Only valid when the Property parameter is set to 1 item.
    Helpful when retrieving sys_id for example.

.PARAMETER EnableDotWalking
    Returns an pscustomobject that supports dot-walking for reference fields.
    This option will automatically add getter methods for refrence fields.
    When you access the property, a call will be made to ServiceNow to retrieve the referenced record.

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

    Get catalog tasks for the parent requested item

.EXAMPLE
    Get-ServiceNowRecord -ParentId 'RITM0010001'

    Get all tasks of all types for the parent requested item

.EXAMPLE
    Get-ServiceNowRecord -Table incident -Filter @('state', '-eq', '1') -Description 'powershell'

    Get incident records where state equals New and short description contains the word powershell

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

.EXAMPLE
    Get-ServiceNowRecord -Table 'change request' -Filter @('opened_at', '-ge', (Get-Date).AddDays(-30))

    Get change requests opened in the last 30 days.  Use class name as opposed to table name.

.EXAMPLE
    Get-ServiceNowRecord -Table 'change request' -First 100 -IncludeTotalCount

    Get all change requests, paging 100 at a time.

.EXAMPLE
    Get-ServiceNowRecord -Table 'change request' -IncludeCustomVariable -First 5

    Get the first 5 change requests and retrieve custom variable info

.EXAMPLE
    Get-ServiceNowRecord -Table 'user' -Filter @{'name', '-like', 'Greg'}

    Find results from tables where there is no number field.
    In this case, get a list of users whose name has 'Greg' in it.

.EXAMPLE
    Get-ServiceNowRecord -Table 'cmdb_ci' -Property sys_id -First 1 -AsValue

    Get the underlying value for a property instead of a pscustomobject where the value needs to be extracted
 
.EXAMPLE
    $incident=Get-ServiceNowRecord -Table 'incident' -First 1 -EnableDotWalking
    $incident.caller_id.manager.email
 
    Get the email address of the manager of the caller for an incident using dot-walking

.EXAMPLE
    gsnr RITM0010001

    Get a specific record by number using the function alias

.EXAMPLE
    Get-ServiceNowRecord -Table 'incident' -FilterString 'active=true^state=1'

    Provide a filter string from the UI to get records where active is true and state is 1

.INPUTS
    ID

.OUTPUTS
    PSCustomObject.  If -AsValue is used, the type will be the selected field.

.LINK
    https://docs.servicenow.com/bundle/quebec-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html

.LINK
    https://developer.servicenow.com/dev.do#!/reference/api/sandiego/rest/c_TableAPI#table-GET
#>
function Get-ServiceNowRecord {

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'Id', SupportsPaging)]
    [Alias('gsnr')]

    Param (
        [Parameter(ParameterSetName = 'Table', Mandatory)]
        [Parameter(ParameterSetName = 'TableId', Mandatory)]
        [Parameter(ParameterSetName = 'TableParentId')]
        [Parameter(ParameterSetName = 'FilterString', Mandatory)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Parameter(ParameterSetName = 'TableId', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'Id must either be a SysId 32 character alphanumeric or Number with prefix and id.'
                }
            })]
        [Alias('sys_id', 'number')]
        [string] $ID,

        [Parameter(ParameterSetName = 'TableParentId', Mandatory)]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'ParentId must either be a SysId 32 character alphanumeric or Number with prefix and id.'
                }
            })]
        [string] $ParentID,

        [Parameter(ParameterSetName = 'Table')]
        [Parameter(ParameterSetName = 'TableParentId')]
        [string] $Description,

        [Parameter()]
        [Alias('Fields', 'Properties')]
        [string[]] $Property,

        [Parameter(ParameterSetName = 'Table')]
        [Parameter(ParameterSetName = 'TableParentId')]
        [object[]] $Filter = @(),

        [Parameter(ParameterSetName = 'FilterString', Mandatory)]
        [Alias('fs')]
        [string] $FilterString,

        [Parameter(ParameterSetName = 'Table')]
        [Parameter(ParameterSetName = 'TableParentId')]
        [ValidateNotNullOrEmpty()]
        [object[]] $Sort,

        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [Alias('DisplayValues')]
        [string] $DisplayValue = 'true',

        [Parameter()]
        [switch] $IncludeCustomVariable,

        [Parameter()]
        [switch] $AsValue,
 
        [Parameter()]
        [switch] $EnableDotWalking,

        [Parameter()]
        [hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {

    }

    process {

        $thisParams = @{
            Property          = $Property
            Sort              = $Sort
            DisplayValue      = $DisplayValue
            First             = $PSCmdlet.PagingParameters.First
            Skip              = $PSCmdlet.PagingParameters.Skip
            IncludeTotalCount = $PSCmdlet.PagingParameters.IncludeTotalCount
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ( $PSBoundParameters.ContainsKey('Filter') ) {
            $thisParams.Filter = $Filter
            #     # we always want the filter to be arrays separated by joins
            if ( $Filter[0].GetType().Name -ne 'Object[]' ) {
                #
                $thisParams.Filter = , $Filter
            }
        }

        if ( $FilterString ) {
            $thisParams.FilterString = $FilterString
        }

        $addedSysIdProp = $false
        # we need the sys_id value in order to get custom var data
        # add it in if specific properties were requested and not part of the list
        if ( $IncludeCustomVariable ) {
            if ( $Property -and 'sys_id' -notin $Property ) {
                $thisParams.Property += 'sys_id'
                $addedSysIdProp = $true
            }
        }

        $thisTable, $thisID = Invoke-TableIdLookup -T $Table -I $ID

        if ( $thisID ) {

            if ( $thisID -match '^[a-zA-Z0-9]{32}$' ) {
                $thisParams.Filter += , @('sys_id', '-eq', $thisID)
            } else {
                $thisParams.Filter += , @('number', '-eq', $thisID)
            }
        }

        if ( $ParentID ) {

            if ( $thisParams.Filter ) {
                $thisParams.Filter += , 'and'
            }

            if ( $ParentID -match '^[a-zA-Z0-9]{32}$' ) {
                $thisParams.Filter += , @('parent.sys_id', '-eq', $ParentID)
            } else {
                $thisParams.Filter += , @('parent.number', '-eq', $ParentID)
            }

            if ( -not $PSBoundParameters.ContainsKey('Table') ) {
                $thisTable, $null = Invoke-TableIdLookup -T 'Task' -I $null
            }
        }

        if ( $Description ) {
            # determine the field we should compare for 'description' and add the filter
            if ( -not $thisTable.DescriptionField ) {
                Write-Warning ('We do not have table ''{0}'' in the config; short_description will be used as the description field' -f $thisTable.Name)
                $thisTable.DescriptionField = 'short_description'
            }

            if ( $thisParams.Filter ) {
                $thisParams.Filter += 'and'
                # $null = $thisParams.Filter.Add('and')
            }
            $thisParams.Filter += , @($thisTable.DescriptionField, '-like', $Description)
            # $null = $thisParams.Filter.Add(@($thisTable.DescriptionField, '-like', $Description))
        }

        $thisParams.Table = $thisTable.Name

        # should use Get-ServiceNowAttachment, but put this here for ease of access
        if ( $thisTable.Name -eq 'attachment' ) {
            Write-Warning 'For attachments, use Get-ServiceNowAttachment'
            $null = $thisParams.Remove('Table')
            $thisParams.UriLeaf = '/attachment'
        }

        [array]$result = Invoke-ServiceNowRestMethod @thisParams

        if ( -not $result ) {
            return
        }

        # custom tables do not have a sys_class_name property, add it
        if ( -not $Property -and $result[0].PSObject.Properties.name -notcontains 'sys_class_name' ) {
            $result | Add-Member @{'sys_class_name' = $Table }
        }
        
        if ($EnableDotWalking) {
            foreach ($record in $result) {
                $newObj = New-Object PSCustomObject
                foreach ($key in $record.PSObject.Properties.Name) {
                    $value = $record.$key
                    # if the value is a reference
                    if ($value -and ($value.GetType().Name -eq "PSCustomObject") -and ($value.link -ne $null)) {
                        $refTable = $value.link.split("/")[6]
                        $refId = $value.link.split("/")[7]
 
                        # there are some fields that seem to be references, but are different
                        if ($refId -notmatch '^[a-zA-Z0-9]{32}$') {
                            $newObj | Add-Member -MemberType NoteProperty -Name $key -Value $value
                            continue
                        }
                       
                        $newObj | Add-Member -MemberType ScriptProperty -Name $key -Value {
                            Get-ServiceNowRecord -Table $refTable -ID $refId -ServiceNowSession $ServiceNowSession -EnableDotWalking
                        }.GetNewClosure()
                    }
                    else {
                        $newObj | Add-Member -MemberType NoteProperty -Name $key -Value $value
                    }
                }
            }
            $result = $newObj
        }

        if ( $IncludeCustomVariable ) {

            # for each record, get the variable names and then get the variable values
            foreach ($record in $result) {

                $recordSysId = if ($DisplayValue -eq 'all') { $record.sys_id.value } else { $record.sys_id }

                # YES_NO = 1; MULTI_LINE_TEXT = 2; MULTIPLE_CHOICE = 3; NUMERIC_SCALE = 4; SELECT_BOX = 5; SINGLE_LINE_TEXT = 6; CHECKBOX = 7; REFERENCE = 8; DATE = 9; DATE_TIME = 10; LABEL = 11; BREAK = 12; MACRO = 14; UI_PAGE = 15; WIDE_SINGLE_LINE_TEXT = 16; MACRO_WITH_LABEL = 17; LOOKUP_SELECT_BOX = 18; CONTAINER_START = 19; CONTAINER_END = 20; LIST_COLLECTOR = 21; LOOKUP_MULTIPLE_CHOICE = 22; HTML = 23; SPLIT = 24; MASKED = 25;

                $customVarParams = @{
                    Table             = 'sc_item_option_mtom'
                    Filter            = @('request_item', '-eq', $recordSysId), 'and', @('sc_item_option.item_option_new.type', '-in', '1,2,3,4,5,6,7,8,9,10,16,18,21,22,26')
                    Property          = 'sc_item_option.item_option_new.sys_name', 'sc_item_option.item_option_new.name', 'sc_item_option.value', 'sc_item_option.sys_id', 'sc_item_option.item_option_new.type', 'sc_item_option.item_option_new.question_text', 'sc_item_option.item_option_new.reference'
                    IncludeTotalCount = $true
                    ServiceNowSession = $ServiceNowSession
                }

                # suppress warning when getting total count
                $customVarsOut = Get-ServiceNowRecord @customVarParams -WarningAction SilentlyContinue

                $record | Add-Member @{
                    'CustomVariable' = [pscustomobject]@{}
                }

                foreach ($var in $customVarsOut) {
                    $newVar = [pscustomobject] @{
                        Name        = if ($var.'sc_item_option.item_option_new.name') { $var.'sc_item_option.item_option_new.name' } else { $var.'sc_item_option.item_option_new.sys_name' }
                        Value       = $var.'sc_item_option.value'
                        DisplayName = $var.'sc_item_option.item_option_new.question_text'
                        Type        = $var.'sc_item_option.item_option_new.type'
                        SysId       = $var.'sc_item_option.sys_id'
                    }

                    # show the underlying value if the option is a reference type
                    if ( $newVar.Type -eq 'Reference' ) {
                        #do not do any further lookup when the value is blank or null
                        #resolves #234 and 262
                        if ($var.'sc_item_option.value' -eq "" -or $null -eq $var.'sc_item_option.value') {
                            continue
                        }
                        $sysidPattern = "[0-9a-fA-F]{32}"
                        $sysid = [Regex]::Matches($var.'sc_item_option.value', $sysidPattern).Value
                        if ($sysid) {
                            Write-Verbose "Custom variable lookup for $($newvar.name) from table '$($var.'sc_item_option.item_option_new.reference')' sysid:'$($var.'sc_item_option.value')'"
                            $newVar | Add-Member @{'ReferenceTable' = $var.'sc_item_option.item_option_new.reference' }
                            $newVar | Add-Member @{'ReferenceID' = $var.'sc_item_option.value' }
                            # issue 234.  ID might not be sysid or number for reference...odd
                            $refValue = Get-ServiceNowRecord -Table $var.'sc_item_option.item_option_new.reference' -ID $var.'sc_item_option.value' -Property name -AsValue -ServiceNowSession $ServiceNowSession -ErrorAction SilentlyContinue
                           if ( $refValue ) {
                               $newVar.Value = $refValue
                           }
                   }
                        
                    }

                    if ( $var.'sc_item_option.item_option_new.name' ) {
                        $record.CustomVariable | Add-Member @{ $var.'sc_item_option.item_option_new.name' = $newVar }
                    } else {
                        $record.CustomVariable | Add-Member @{ $var.'sc_item_option.item_option_new.question_text' = $newVar }
                    }
                }

                if ( $addedSysIdProp ) {
                    $record | Select-Object -Property * -ExcludeProperty sys_id
                } else {
                    $record
                }
            }
        } else {

            # format the results
            if ( $Property ) {
                if ( $Property.Count -eq 1 -and $AsValue ) {
                    $propName = $result | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | Select-Object -ExpandProperty Name
                    $result.$propName
                } else {
                    $result
                }
            } else {
                if ($thisTable.Type) {
                    $result | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $thisTable.Type) }
                }
                $result
            }
        }
    }
}
