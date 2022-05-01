function Remove-ServiceNowRecord {

    [CmdletBinding(ConfirmImpact = 'High')]

    param(
        # Table containing the entry we're deleting
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('sys_class_name')]
        [string] $Table,

        # sys_id of the entry we're deleting
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {

    }

    process {
        $Params = @{
            Method            = 'Delete'
            Table             = $Table
            SysId             = $SysId
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        Invoke-ServiceNowRestMethod @Params
    }
}
