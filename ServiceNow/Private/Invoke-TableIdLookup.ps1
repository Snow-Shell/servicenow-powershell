<#
.SYNOPSIS
    Lookup table and id info
.DESCRIPTION
    Lookup table and id info from module config.
    Get sys_id if needed.
#>
function Invoke-TableIdLookup {

    [OutputType([Array])]
    [CmdletBinding()]

    Param (
        [Parameter(ParameterSetName = 'Table', Mandatory)]
        [Parameter(ParameterSetName = 'TableID', Mandatory)]
        [Parameter(ParameterSetName = 'TableIdSysId', Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [Alias('T')]
        [string] $Table,

        [Parameter(ParameterSetName = 'ID', Mandatory)]
        [Parameter(ParameterSetName = 'TableID', Mandatory)]
        [Parameter(ParameterSetName = 'IdSysId', Mandatory)]
        [Parameter(ParameterSetName = 'TableIdSysId', Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [Alias('I')]
        [string] $ID,

        [Parameter(ParameterSetName = 'IdSysId', Mandatory)]
        [Parameter(ParameterSetName = 'TableIdSysId', Mandatory)]
        [Alias('AS')]
        [switch] $AsSysId,

        [Parameter(ParameterSetName = 'IdSysId')]
        [Parameter(ParameterSetName = 'TableIdSysId')]
        [Alias('C')]
        [hashtable] $Connection,

        [Parameter(ParameterSetName = 'IdSysId')]
        [Parameter(ParameterSetName = 'TableIdSysId')]
        [Alias('S')]
        [hashtable] $ServiceNowSession

    )

    $thisTable = $thisID = $null

    if ( $Table ) {
        $thisTable = $script:ServiceNowTable | Where-Object { $_.Name.ToLower() -eq $Table.ToLower() -or $_.ClassName.ToLower() -eq $Table.ToLower() }
        if ( -not $thisTable ) {
            # we aren't aware of this table, create default config
            $thisTable = @{
                Name             = $Table
                ClassName        = $null
                Type             = $null
                NumberPrefix     = $null
                DescriptionField = $null
            }
        }
    }

    if ( $ID ) {
        if ( $ID -match '^[a-zA-Z0-9]{32}$' ) {
            if ( -not $thisTable ) {
                throw 'Providing sys_id for -ID requires a value for -Table.  Alternatively, provide an ID with a prefix, eg. INC1234567, and the table will be automatically determined.'
            }

            $thisID = $ID
        }
        else {
            if ( -not $thisTable ) {
                # get table name from prefix if only Id was provided
                $idPrefix = ($ID | Select-String -Pattern '^([a-zA-Z]+)([0-9]+$)').Matches.Groups[1].Value.ToLower()

                $thisTable = $script:ServiceNowTable | Where-Object { $_.NumberPrefix -and $idPrefix -eq $_.NumberPrefix }
                if ( -not $thisTable ) {
                    throw ('The prefix for Id ''{0}'' was not found and the appropriate table cannot be determined.  Known prefixes are {1}.  Please provide a value for -Table.' -f $ID, ($ServiceNowTable.NumberPrefix.Where( { $_ }) -join ', '))
                }
            }

            if ( $AsSysId ) {
                $getParams = @{
                    Table             = $thisTable.Name
                    Filter            = @('number', '-eq', $ID)
                    Property          = 'sys_class_name', 'sys_id', 'number'
                    Connection        = $Connection
                    ServiceNowSession = $ServiceNowSession
                }

                $thisRecord = Invoke-ServiceNowRestMethod @getParams

                if ( -not $thisRecord ) {
                    throw ('Table: {0}, ID: {1} not found' -f $thisTable.Name, $ID)
                }
                else {
                    $thisID = $thisRecord.sys_id
                }
            }
            else {
                $thisID = $ID
            }
        }
    }

    $thisTable, $thisID
}
