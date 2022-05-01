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
    [CmdletBinding(SupportsShouldProcess)]

    param (
        # sys_id of the ticket to update
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysID,

        # Hashtable of values to use as the record's properties
        [Parameter(Mandatory)]
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
            Table             = 'sc_req_item'
            SysId             = $SysID
            Values            = $Values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ($PSCmdlet.ShouldProcess("Requested Item $SysID", 'Update values')) {
            $Response = Invoke-ServiceNowRestMethod @Params
            if ( $PassThru.IsPresent ) {
                $Response
            }
        }

    }

    end {}
}
