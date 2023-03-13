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

.PARAMETER InputData
    Key/value pairs of fields and their values

.PARAMETER CustomVariableData
    Key/value pairs of custom variable names and their values.
    Get custom variable names with Get-ServiceNowRecord -IncludeCustomVariable.

.PARAMETER PassThru
    If provided, the updated record will be returned

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Update-ServiceNowRecord -ID 'INC0010001' -InputData @{State = 'Closed'}

    Update a record by number.  The table name will be looked up based on the prefix.

.EXAMPLE
    Update-ServiceNowRecord -Table 'change_request' -ID 'CHG0010001' -InputData @{'work_notes' = 'my notes'}

    Update a record by number.  The table name is provided directly as the table lookup is different, 'Change Request' as opposed to 'change_request'.

.EXAMPLE
    Update-ServiceNowRecord -Table incident -ID '13378afb-97a6-451a-b1ec-2c9e85313188' -InputData @{State = 'Closed'}

    Update a record by table name and sys_id.
    Providing a sys_id as opposed to a number minimizes the api calls.

.EXAMPLE
    Get-ServiceNowRecord INC0000001 | Update-ServiceNowRecord -InputData @{'work_notes' = 'Updated by PowerShell'}

    Update details piping an existing object.  You do not need to specify the table or ID for the update.

.EXAMPLE
    Update-ServiceNowRecord -ID RITM0000001 -CustomVariableData @{'question' = 'Yes'}

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
        [hashtable] $InputData,

        [parameter(Mandatory, ParameterSetName = 'both')]
        [parameter(Mandatory, ParameterSetName = 'custom')]
        [hashtable] $CustomVariableData,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    process {

        $thisTable, $thisID = Invoke-TableIdLookup -T $Table -I $ID -AsSysId -C $Connection -S $ServiceNowSession

        If (-not $PSCmdlet.ShouldProcess("$($thisTable.ClassName) $ID", 'Update values')) {
            return
        }

        if ( $PSBoundParameters.ContainsKey('InputData') ) {

            $params = @{
                Method            = 'Patch'
                Table             = $thisTable.Name
                SysId             = $thisID
                Values            = $InputData
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            $response = Invoke-ServiceNowRestMethod @params
        }

        if ( $PSBoundParameters.ContainsKey('CustomVariableData') ) {

            $customVarsOut = Get-ServiceNowRecord -Table $thisTable.Name -ID $thisID -IncludeCustomVariable -Property sys_id, number -Connection $Connection -ServiceNowSession $ServiceNowSession | Select-Object -ExpandProperty CustomVariable

            foreach ($key in $CustomVariableData.Keys) {

                $thisCustomVar = $customVarsOut.PSObject.Properties.Value | Where-Object { $key -in $_.Name, $_.DisplayName, $_.SysId }

                if ( $thisCustomVar ) {
                    $params = @{
                        Method            = 'Patch'
                        Table             = 'sc_item_option'
                        SysId             = $thisCustomVar.SysId
                        Values            = @{'value' = $CustomVariableData[$key] }
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
            if ( $PSBoundParameters.ContainsKey('CustomVariableData') ) {
                $response = Get-ServiceNowRecord -Table $thisTable.Name -ID $thisID -IncludeCustomVariable -Connection $Connection -ServiceNowSession $ServiceNowSession
            }

            if ($thisTable.Type) {
                $response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $thisTable.Type) }
            }
            $response
        }
    }
}
