Function Update-ServiceNowNumber {
    <#
    .SYNOPSIS
    Allows for the passing of a number, instead of a sys_id, and associated table to update a ServiceNow entry.

    .DESCRIPTION
    Allows for the passing of a number, instead of a sys_id, and associated table to update a ServiceNow entry.  Output is suppressed and may be returned with a switch parameter.

    .EXAMPLE
    Update-ServiceNowNumber -Number $Number -Table $Table -Values @{property='value'}

    Updates a ticket number with a value providing no return output.

    .EXAMPLE
    Update-ServiceNowNumber -Number $Number -Table $Table -Values @{property='value'} -PassThru

    Updates a ticket number with a value providing return output.
    .NOTES

    #>

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]

    Param(
        # Table containing the entry
        [Parameter(Mandatory)]
        [string]$Table,

        # Object number
        [Parameter(Mandatory)]
        [string]$Number,

        # Hashtable of values to use as the record's properties
        [parameter()]
        [hashtable]$Values,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        # Switch to allow the results to be passed back
        [parameter()]
        [switch]$PassThru
    )

    begin {}

    process {
        # Prep a splat to use the provided number to find the sys_id
        $getSysIdParams = @{
            Table             = $Table
            Query             = (New-ServiceNowQuery -MatchExact @{'number' = $number })
            Properties        = 'sys_id'
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }

        # Use the number and table to determine the sys_id
        $sysId = Invoke-ServiceNowRestMethod @getSysIdParams | Select-Object -ExpandProperty sys_id

        $updateParams = @{
            Method            = 'Patch'
            Table             = $Table
            SysId             = $sysId
            Values            = $Values
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }
        If ($PSCmdlet.ShouldProcess("$Table $SysID", 'Update values')) {
            $response = Invoke-ServiceNowRestMethod @updateParams
            if ( $PassThru.IsPresent ) {
                $response
            }
        }
    }

    end {}
}
