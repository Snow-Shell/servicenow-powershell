function Update-ServiceNowIncident {

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]

    Param
    (   # sys_id of the caller of the incident (use Get-ServiceNowUser to retrieve this)
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory)]
        [hashtable] $Values,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential] $Credential,

        # The URL for the ServiceNow instance being used (eg: instancename.service-now.com)
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

    begin {
        Write-Warning -Message 'PassThru will be implemented in a future release and the response will not be returned by default.  Please update your code to handle this.'
    }

    process {
        $params = @{
            Method            = 'Patch'
            Table             = 'incident'
            SysId             = $SysId
            Values            = $Values
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("Incident $SysID", 'Update values')) {
            Invoke-ServiceNowRestMethod @params
        }

    }

    end {}
}

