function Update-ServiceNowRecord {
    <#
    .SYNOPSIS
        Update record values

    .DESCRIPTION
        Update one or more record values and optionally return the updated record

    .PARAMETER Table
        Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
        You can also provide any table name ad hoc.

    .PARAMETER Id
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
        Update-ServiceNowRecord -Table incident -Id 'INC0010001' -Values @{State = 'Closed'}
        Close an incident record

    .INPUTS
        Table, Id

    .OUTPUTS
        PSCustomObject, if PassThru is provided
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $ID,

        [Parameter(Mandatory)]
        [Hashtable] $Values,

        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {}

    process {

        if ( $Table -and ($Id -match '[a-zA-Z0-9]{32}') ) {
            # we already have table name and sys_id, no more to do before update
            $TableName = $Table
            $SysID = $ID
        } else {
            # get needed details, table name and sys_id, for update
            $GetParams = @{
                Id                = $ID
                Property          = 'sys_class_name', 'sys_id', 'number'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            if ( $Table ) {
                $GetParams.Table = $Table
            }

            $ThisRecord = Get-ServiceNowRecord @GetParams

            if ( $ThisRecord ) {
                $TableName = $ThisRecord.sys_class_name
                $SysID = $ThisRecord.sys_id
            } else {
                Write-Error ('Record not found for Id ''{0}''' -f $Id)
                continue
            }
        }

        $Params = @{
            Method            = 'Patch'
            Table             = $TableName
            SysId             = $SysID
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ($PSCmdlet.ShouldProcess("$TableName $SysID", 'Update values')) {
            $Response = Invoke-ServiceNowRestMethod @Params
            if ( $PassThru.IsPresent ) {
                $Response
            }
        }
    }
}
