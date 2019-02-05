Function Get-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .DESCRIPTION
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .EXAMPLE
    Get-ServiceNowAttachment -SysID $SysID -FileName 'mynewfile.txt' -Destination $Destination

    Save the attachment with the specified sys_id to the destination with a name of 'mynewfile.txt'

    .EXAMPLE
    Get-ServiceNowAttachment -Number $Number -Table $Table | Get-ServiceNowAttachment -Destination $Destination

    Save all attachments from the ticket to the destination.  Filenames will be assigned from the attachment name.

    .NOTES

    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param(
        # Object number
        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('sys_id')]
        [string]$SysID,

        [Parameter(
            Mandatory=$true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('file_name')]
        [string]$FileName,

        # Out path to download files
        [parameter(Mandatory=$false)]
        [ValidateScript({
            Test-Path $_
        })]
        [string]$Destination,

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
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )

	begin {}
	process	{

        # Process credential steps based on parameter set name
        Switch ($PSCmdlet.ParameterSetName) {
            'SpecifyConnectionFields' {
                $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1/attachment'
            }
            'UseConnectionObject' {
                $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
                $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1/attachment'
            }
            Default {
                If ((Test-ServiceNowAuthIsSet)) {
                    $Credential = $Global:ServiceNowCredentials
                    $ServiceNowURL = $Global:ServiceNowRESTURL + '/attachment'
                }
                Else {
                    Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                }
            }
        }

        # URI format:  https://tenant.service-now.com/api/now/v1/attachment/{sys_id}/file
        $Uri = $ServiceNowURL + '/' + $SysID + '/file'

        $OutFile = $Null
        $OutFile = Join-Path $Destination $FileName

        $invokeRestMethodSplat = @{
            Uri         = $Uri
            Credential  = $Credential
            OutFile     = $OutFile
        }

        If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
            Invoke-RestMethod @invokeRestMethodSplat
        }

    }
	end {}
}
