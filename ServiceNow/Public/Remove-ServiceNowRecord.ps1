function Remove-ServiceNowRecord {
    [CmdletBinding(DefaultParameterSetName = 'Session', ConfirmImpact = 'High')]
    Param(
        # Table containing the entry we're deleting
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        # sys_id of the entry we're deleting
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $ServiceNowCredential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceNowURL,

        #Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    $params = @{
        Method            = 'Delete'
        Table             = $Table
        SysId             = $SysId
        Connection        = $Connection
        Credential        = $Credential
        ServiceNowUrl     = $ServiceNowURL
        ServiceNowSession = $ServiceNowSession
    }
    Invoke-ServiceNowRestMethod @params
}
