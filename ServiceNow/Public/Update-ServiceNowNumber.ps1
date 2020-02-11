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

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [CmdletBinding(DefaultParameterSetName = 'UseConnectionObject',SupportsShouldProcess=$true)]
    Param(
        # Object number
        [Parameter(Mandatory=$true)]
        [string]$Number,

        # Table containing the entry
        [Parameter(Mandatory=$true)]
        [string]$Table,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject')]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection = $script:ConnectionObj,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory=$false)]
        [hashtable]$Values,

        # Switch to allow the results to be passed back
        [parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    process {
        # Prep a splat to use the provided number to find the sys_id
        $getServiceNowTableEntry = @{
            Table         = $Table
            MatchExact    = @{number = $number}
            ErrorAction   = 'Stop'
        }

        # Update the splat if the parameters have values
        if ($null -ne $PSBoundParameters.Connection) {
            $getServiceNowTableEntry.Add('Connection', $Connection)
        }
        elseif ($null -ne $PSBoundParameters.Credential -and $null -ne $PSBoundParameters.ServiceNowURL) {
            $getServiceNowTableEntry.Add('Credential', $Credential)
            $getServiceNowTableEntry.Add('ServiceNowURL', $ServiceNowURL)
        }

        # Use the number and table to determine the sys_id
        $SysID = Get-ServiceNowTableEntry @getServiceNowTableEntry | Select-Object -Expand sys_id

        # Re-purpose the existing Splat
        $getServiceNowTableEntry.Remove('MatchExact')
        $getServiceNowTableEntry.Add('SysId', $SysID)
        $getServiceNowTableEntry.Add('Values', $Values)

        If ($PSCmdlet.ShouldProcess("$Table/$SysID", $MyInvocation.MyCommand)) {
            try {
                $Result = (Update-ServiceNowTableEntry @getServiceNowTableEntry).Result
            }
            Catch {
                Write-Error $PSItem
            }

            # Option to return results
            If ($PSBoundParameters.ContainsKey('Passthru')) {
                $Result
            }
        }
        
    }
}
