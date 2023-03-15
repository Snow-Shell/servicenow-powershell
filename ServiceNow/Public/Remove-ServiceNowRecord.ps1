<#
.SYNOPSIS
    Remove a record

.DESCRIPTION
    Remove a record

.PARAMETER Table
    Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
    You can also provide any table name ad hoc.

.PARAMETER ID
    Either the record sys_id or number.
    If providing just an ID, not with Table, the ID prefix will be looked up to find the table name.

.EXAMPLE
    Remove-ServiceNowRecord CHG0123456

    Removes a record

.EXAMPLE
    Remove-ServiceNowRecord CHG0123456 -Confirm:$false

    Removes a record without prompting for confirmation

.EXAMPLE
    Get-ServiceNowRecord -Table incident -Description 'not needed' | Remove-ServiceNowRecord

    Remove multiple records via pipeline
#>

function Remove-ServiceNowRecord {

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

    Param(
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $ID,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    process {

        $thisTable, $thisID = Invoke-TableIdLookup -T $Table -I $ID -AsSysId -C $Connection -S $ServiceNowSession

        If ($PSCmdlet.ShouldProcess("$($thisTable.ClassName) $ID", 'Remove record')) {

            $params = @{
                Method            = 'Delete'
                Table             = $thisTable.Name
                SysId             = $thisID
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            Invoke-ServiceNowRestMethod @params
        }
    }
}
