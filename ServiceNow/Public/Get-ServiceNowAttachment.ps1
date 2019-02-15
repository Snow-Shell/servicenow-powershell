Function Get-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .DESCRIPTION
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .PARAMETER SysID
    The ServiceNow sys_id of the file

    .PARAMETER FileName
    File name the file is saved as.  Do not include the path.

    .PARAMETER Destination
    Path the file is saved to.  Do not include the file name.

    .PARAMETER AllowOverwrite
    Allows the function to overwrite the existing file.

    .PARAMETER AppendNameWithSysID
    Adds the SysID to the file name.  Intended for use when a ticket has multiple files with the same name.

    .EXAMPLE
    Get-ServiceNowAttachment -SysID $SysID -FileName 'mynewfile.txt'

    Save the attachment with the specified sys_id with a name of 'mynewfile.txt'

    .EXAMPLE
    Get-ServiceNowAttachment -Number $Number -Table $Table | Get-ServiceNowAttachment

    Save all attachments from the ticket.  Filenames will be assigned from the attachment name.

    .EXAMPLE
    Get-ServiceNowAttachment -Number $Number -Table $Table | Get-ServiceNowAttachment -AppendNameWithSysID

    Save all attachments from the ticket.  Filenames will be assigned from the attachment name and appended with the sys_id.

    .EXAMPLE
    Get-ServiceNowAttachment -Number $Number -Table $Table | Get-ServiceNowAttachment -Destination $Destionion -AllowOverwrite

    Save all attachments from the ticketto the destination allowing for overwriting the destination file.

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
        [string]$Destination = $PWD.Path,

        # Options impacting downloads
        [parameter(Mandatory=$false)]
        [switch]$AllowOverwrite,

        # Options impacting downloads
        [parameter(Mandatory=$false)]
        [switch]$AppendNameWithSysID,

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
        Try {
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
                    If ((Test-ServiceNowAuthIsSet)) {
                        $Credential = $Global:ServiceNowCredentials
                        $ApiUrl = $Global:ServiceNowRESTURL + '/attachment'
                    }
                    Else {
                        Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                    }
                }
            }

            # URI format:  https://tenant.service-now.com/api/now/v1/attachment/{sys_id}/file
            $Uri = $ApiUrl + '/' + $SysID + '/file'

            If ($True -eq $PSBoundParameters.ContainsKey('AppendNameWithSysID')) {
                $FileName = "{0}_{1}{2}" -f [io.path]::GetFileNameWithoutExtension($FileName),
                $SysID,[io.path]::GetExtension($FileName)
            }
            $OutFile = $Null
            $OutFile = Join-Path $Destination $FileName

            If ((Test-Path $OutFile) -and -not $PSBoundParameters.ContainsKey('AllowOverwrite')) {
                $ThrowMessage = "The file [{0}] already exists.  Please choose a different name, use the -AppendNameWithSysID switch parameter, or use the -AllowOverwrite switch parameter to overwrite the file." -f $OutFile
                Throw $ThrowMessage
            }

            $invokeRestMethodSplat = @{
                Uri         = $Uri
                Credential  = $Credential
                OutFile     = $OutFile
            }

            If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
                Invoke-RestMethod @invokeRestMethodSplat
            }
        }
        Catch {
            Write-Error $PSItem
        }

    }
	end {}
}
