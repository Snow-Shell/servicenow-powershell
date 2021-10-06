function Remove-ServiceNowRecord {

    [CmdletBinding(ConfirmImpact = 'High')]

    Param(
        # Table containing the entry we're deleting
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('sys_class_name')]
        [string] $Table,

        # sys_id of the entry we're deleting
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {

    }

    process {
        $params = @{
            Method            = 'Delete'
            Table             = $Table
            SysId             = $SysId
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        Invoke-ServiceNowRestMethod @params
    }
}
