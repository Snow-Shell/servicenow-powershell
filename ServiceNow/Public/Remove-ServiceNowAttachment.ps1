Function Remove-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Remove a ServiceNow attachment by sys_id.

    .DESCRIPTION
    Remove a ServiceNow attachment by sys_id.

    .EXAMPLE
    Remove-ServiceNowAttachment -SysID $SysID

    Removes the attachment with the associated sys_id

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number CHG0000001 | Remove-ServiceNowAttachment

    Removes all attachments from CHG0000001

    .NOTES

    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param(
        # Attachment sys_id
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('sys_id')]
        [string]$SysID,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string]$ServiceNowURL,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )

	begin {}
	process	{
		# DELETE: https://tenant.service-now.com/api/now/v1/attachment/{sys_id}

        # Process credential steps based on parameter set name
        Switch ($PSCmdlet.ParameterSetName) {
            'SpecifyConnectionFields' {
                $ApiUrl = 'https://' + $ServiceNowURL + '/api/now/v1/attachment'
            }
            'UseConnectionObject' {
                $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
                $ApiUrl = 'https://' + $Connection.ServiceNowUri + '/api/now/v1/attachment'
            }
            Default {
                If (Test-ServiceNowAuthIsSet) {
                    $Credential = $Global:ServiceNowCredentials
                    $ApiUrl = $Global:ServiceNowRESTURL + '/attachment'
                }
                Else {
                    Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                }
            }
        }

        $Uri = $ApiUrl + '/' + $SysID
        Write-Verbose "URI:  $Uri"

        $invokeRestMethodSplat = @{
            Uri         = $Uri
            Credential  = $Credential
            Method      = 'Delete'
        }

        If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
            (Invoke-RestMethod @invokeRestMethodSplat).Result
        }
    }
	end {}
}
