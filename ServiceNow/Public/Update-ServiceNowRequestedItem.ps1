function Update-ServiceNowRequestItem {
    <#
    .SYNOPSIS
    Update an existing request item (RITM)

    .DESCRIPTION
    Update an existing request item (RITM)

    .EXAMPLE
    Update-ServiceNowRequestItem -SysId $SysId -Values @{property='value'}

    Updates a ticket number with a value providing no return output.

    .EXAMPLE
    Update-ServiceNowRequestItem -SysId $SysId -Values @{property='value'} -PassThru

    Updates a ticket number with a value providing return output.

    .NOTES

    #>

    [OutputType([void], [System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]

    Param (
        # sys_id of the ticket to update
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        # Hashtable of values to use as the record's properties
        [Parameter(Mandatory)]
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
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {

        $params = @{
            Method            = 'Patch'
            Table             = 'sc_req_item'
            SysId             = $SysId
            Values            = $Values
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("Requested Item $SysID", 'Update values')) {
            $response = Invoke-ServiceNowRestMethod @params
            if ( $PassThru.IsPresent ) {
                $response
            }
        }

    }

    end {}
}
