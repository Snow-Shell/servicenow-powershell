<#
.EXAMPLE
    Update-ServiceNowChangeRequest -Values @{ 'state' = 3 } -SysId <sysid>
#>
function Update-ServiceNowChangeRequest {

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # sys_id of the caller of the incident (use Get-ServiceNowUser to retrieve this)
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory)]
        [Hashtable] $Values,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        $Params = @{
            Method            = 'Patch'
            Table             = 'change_request'
            SysId             = $SysId
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ($PSCmdlet.ShouldProcess("Change request $SysID", 'Update values')) {
            $Response = Invoke-ServiceNowRestMethod @Params
            if ( $PassThru.IsPresent ) {
                $Response
            }
        }
    }

    end {}
}
