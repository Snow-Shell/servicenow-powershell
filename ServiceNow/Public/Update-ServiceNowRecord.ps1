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
    If providing just an ID, not with Table, the ID prefix will be looked up to find the table name.

.PARAMETER FieldValue
    Key/value pairs of fields and their values

.PARAMETER CustomVariableValue
    Key/value pairs of custom variable names and their values.
    Get custom variable names with Get-ServiceNowRecord -IncludeCustomVariable.

.PARAMETER PassThru
    If provided, the updated record will be returned

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Update-ServiceNowRecord -ID 'INC0010001' -FieldValue @{State = 'Closed'}

    Update a record by number.  The table name will be looked up based on the prefix.

.EXAMPLE
    Update-ServiceNowRecord -Table 'change_request' -ID 'CHG0010001' -FieldValue @{'work_notes' = 'my notes'}

    Update a record by number.  The table name is provided directly as the table lookup is different, 'Change Request' as opposed to 'change_request'.

.EXAMPLE
    Update-ServiceNowRecord -Table incident -ID '13378afb-97a6-451a-b1ec-2c9e85313188' -FieldValue @{State = 'Closed'}

    Update a record by table name and sys_id.

.EXAMPLE
    Get-ServiceNowRecord INC0000001 | Update-ServiceNowRecord -FieldValue @{'work_notes' = 'Updated by PowerShell'}

    Update details piping an existing object.  You do not need to specify the table or ID for the update.

.EXAMPLE
    Update-ServiceNowRecord -ID RITM0000001 -CustomVariableValue @{'question' = 'Yes'}

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

        [parameter(Mandatory, ParameterSetName = 'both')]
        [parameter(Mandatory, ParameterSetName = 'field')]
        [Alias('Values')]
        [hashtable] $FieldValue,

        [parameter(Mandatory, ParameterSetName = 'both')]
        [parameter(Mandatory, ParameterSetName = 'custom')]
        [hashtable] $CustomVariableValue,

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


        If ($PSCmdlet.ShouldProcess("$newTableName $sysId", 'Update values')) {

            if ( $FieldValue ) {

                $params = @{
                    Method            = 'Patch'
                    Table             = $newTableName
                    SysId             = $sysId
                    Values            = $FieldValue
                    Connection        = $Connection
                    ServiceNowSession = $ServiceNowSession
                }

                $response = Invoke-ServiceNowRestMethod @params
            }

            if ( $CustomVariableValue ) {

                $customVarsOut = Get-ServiceNowRecord -Table $newTableName -ID $sysId -IncludeCustomVariable -Property sys_id, number | Select-Object -ExpandProperty CustomVariable

                foreach ($key in $CustomVariableValue.Keys) {

                    $thisCustomVar = $customVarsOut.PSObject.Properties.Value | Where-Object { $key -in $_.Name, $_.DisplayName, $_.SysId }

                    if ( $thisCustomVar ) {
                        $params = @{
                            Method            = 'Patch'
                            Table             = 'sc_item_option'
                            SysId             = $thisCustomVar.SysId
                            Values            = @{'value' = $CustomVariableValue[$key] }
                            Connection        = $Connection
                            ServiceNowSession = $ServiceNowSession
                        }
                        $null = Invoke-ServiceNowRestMethod @params
                    }
                    else {
                        Write-Warning ('Custom variable {0} not found' -f $key)
                    }
                }
            }

            if ( $PassThru ) {
                if ( $CustomVariableValue ) {
                    Get-ServiceNowRecord -Table $newTableName -ID $sysId -IncludeCustomVariable -Connection $Connection -ServiceNowSession $ServiceNowSession
                }
                else {
                    $response
                }
            }
        }
    }
}
