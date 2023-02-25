<#
.SYNOPSIS
    Update record values

.DESCRIPTION
    Update one or more record values and optionally return the updated record

.PARAMETER Table
    Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
    You can also provide any table name ad hoc.

.PARAMETER ID
    Either the record sys_id or number.
    If providing just an Id, not with Table, the Id prefix will be looked up to find the table name.

.PARAMETER Values
    Hashtable with all the field/value pairs for the updated record

.PARAMETER PassThru
    If provided, the updated record will be returned

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Update-ServiceNowRecord -ID 'INC0010001' -Values @{State = 'Closed'}
    Update a record by number.  The table name will be looked up based on the prefix.

.EXAMPLE
    Update-ServiceNowRecord -Table 'change_request' -ID 'CHG0010001' -Values @{'work_notes' = 'my notes'}
    Update a record by number.  The table name is provided directly as the table lookup is different, 'Change Request' as opposed to 'change_request'.

.EXAMPLE
    Update-ServiceNowRecord -Table incident -ID '13378afb-97a6-451a-b1ec-2c9e85313188' -Values @{State = 'Closed'}
    Update a record by table name and sys_id.

.EXAMPLE
    Get-ServiceNowRecord INC0000001 | Update-ServiceNowRecord -Values @{work_notes = "Updated by PowerShell"}
    Update details piping an existing object.  You do not need to specify the table or ID for the update.

.INPUTS
    Table, ID

.OUTPUTS
    PSCustomObject, if PassThru is provided
#>

function Update-ServiceNowRecord {

    [CmdletBinding(SupportsShouldProcess)]

    Param(
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $ID,

        [parameter(Mandatory)]
        [hashtable] $Values,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {}

    process {

        if ( $ID -match '[a-zA-Z0-9]{32}' ) {
            $sysId = $ID
            if ( $Table ) {
                $tableName = $Table
            }
            else {
                Write-Error 'Providing a sys_id for -ID requires a value for -Table'
            }
        }
        else {
            # get needed details, table name and sys_id, for update
            $getParams = @{
                Id                = $ID
                Property          = 'sys_class_name', 'sys_id', 'number'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            if ( $Table ) {
                $getParams.Table = $Table
            }

            $thisRecord = Get-ServiceNowRecord @getParams

            if ( -not $thisRecord ) {
                Write-Error ('Record not found for ID ''{0}''' -f $ID)
                continue
            }

            # if the table name was provided, use it
            # otherwise use the table name we retrieved which may or may not work
            if ( $Table ) {
                $tableName = $Table
            }
            else {
                $tableName = $thisRecord.sys_class_name
            }
            $sysId = $thisRecord.sys_id
        }

        $newTableName = $script:ServiceNowTable | Where-Object { $_.Name.ToLower() -eq $tableName.ToLower() -or $_.ClassName.ToLower() -eq $tableName.ToLower() } | Select-Object -ExpandProperty Name
        if ( -not $newTableName ) {
            # we aren't aware of this table in our config so use as is
            $newTableName = $tableName
        }

        $params = @{
            Method            = 'Patch'
            Table             = $newTableName
            SysId             = $sysId
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("$newTableName $sysId", 'Update values')) {
            $response = Invoke-ServiceNowRestMethod @params
            if ( $PassThru ) {
                $response
            }
        }
    }
}
