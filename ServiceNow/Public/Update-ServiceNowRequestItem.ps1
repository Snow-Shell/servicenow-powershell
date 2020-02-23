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

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([void],[System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'UseConnectionObject',SupportsShouldProcess=$true)]
    Param (
        # sys_id of the ticket to update
        [Parameter(mandatory=$true)]
        [string]$SysId,

         # Hashtable of values to use as the record's properties
        [Parameter(mandatory=$true)]
        [hashtable]$Values,

         # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        # The URL for the ServiceNow instance being used (eg: instancename.service-now.com)
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        #Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject')]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection = $script:ConnectionObj,

        # Switch to allow the results to be passed back
        [Parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    $updateServiceNowTableEntrySplat = @{
        SysId  = $SysId
        Table  = 'sc_req_item'
        Values = $Values
    }

    # Update the splat if the parameters have values
    If ($null -ne $PSBoundParameters.Connection) {
        $updateServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    ElseIf ($null -ne $PSBoundParameters.Credential -and $null -ne $PSBoundParameters.ServiceNowURL) {
         $updateServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
         $updateServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    If ($PSCmdlet.ShouldProcess("$Table/$SysID",$MyInvocation.MyCommand)) {
        # Send REST call
        $Result = Update-ServiceNowTableEntry @updateServiceNowTableEntrySplat

        # Option to return results
        If ($PSBoundParameters.ContainsKey('Passthru')) {
            $Result
        }
    }
}
