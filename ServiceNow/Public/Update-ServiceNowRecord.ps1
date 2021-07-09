function Update-ServiceNowRecord {

    <#
    .SYNOPSIS
        Update record values
    .DESCRIPTION
        Update one or more record values and optionally return the updated record
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>

    [CmdletBinding(SupportsShouldProcess)]

    Param(
        # Table containing the entry we're updating
        [parameter(ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $Id,

        # Hashtable of values to use as the record's properties
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

        if ( $Table -and ($Id -match '[a-zA-Z0-9]{32}') ) {
            # we already have table name and sys_id, no more to do before update
            $tableName = $Table
            $sysId = $Id
        }
        else {
            # get needed details, table name and sys_id, for update
            $getParams = @{
                Id                = $Id
                Property          = 'sys_class_name', 'sys_id', 'number'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            if ( $Table ) {
                $getParams.Table = $Table
            }

            $thisRecord = Get-ServiceNowRecord @getParams

            if ( $thisRecord ) {
                $tableName = $thisRecord.sys_class_name
                $sysId = $thisRecord.sys_id
            }
            else {
                throw ('Record not found for Id ''{0}''' -f $Id)
            }
        }

        $params = @{
            Method            = 'Patch'
            Table             = $tableName
            SysId             = $sysId
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("$tableName $sysId", 'Update values')) {
            $response = Invoke-ServiceNowRestMethod @params
            if ( $PassThru.IsPresent ) {
                $response
            }
        }
    }
}
