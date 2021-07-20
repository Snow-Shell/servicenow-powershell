function Update-ServiceNowIncident {

    [CmdletBinding(SupportsShouldProcess)]

    Param
    (   # sys_id of the caller of the incident (use Get-ServiceNowUser to retrieve this)
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory)]
        [hashtable] $Values,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        $params = @{
            Method            = 'Patch'
            Table             = 'incident'
            SysId             = $SysId
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("Incident $SysID", 'Update values')) {
            $response = Invoke-ServiceNowRestMethod @params
            if ( $PassThru.IsPresent ) {
                $response
            }
        }
    }

    end {}
}

