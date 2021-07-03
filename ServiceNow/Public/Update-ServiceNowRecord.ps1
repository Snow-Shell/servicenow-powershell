function Update-ServiceNowRecord {
    [CmdletBinding(DefaultParameterSetName = 'SessionSysId', SupportsShouldProcess)]
    Param(
        # Table containing the entry we're updating
        [parameter(Mandatory)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'AutomationSysId', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'SessionSysId', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter(ParameterSetName = 'AutomationNumber', Mandatory)]
        [Parameter(ParameterSetName = 'SessionNumber', Mandatory)]
        [string] $Number,

        # Hashtable of values to use as the record's properties
        [parameter()]
        [hashtable] $Values,

        [Parameter(ParameterSetName = 'AutomationSysId', Mandatory)]
        [Parameter(ParameterSetName = 'AutomationNumber', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Connection,

        [Parameter(ParameterSetName = 'SessionSysId')]
        [Parameter(ParameterSetName = 'SessionNumber')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        $params = @{
            Method            = 'Patch'
            Table             = $Table
            SysId             = $SysId
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("$Table $SysID", 'Update values')) {
            $response = Invoke-ServiceNowRestMethod @params
            if ( $PassThru.IsPresent ) {
                $response
            }
        }
    }
}
