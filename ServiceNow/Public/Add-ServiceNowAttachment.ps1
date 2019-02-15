Function Add-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Attaches a file to an existing ticket.

    .DESCRIPTION
    Attaches a file to an existing ticket.

    .PARAMETER Number
    ServiceNow ticket number

    .PARAMETER Table
    ServiceNow ticket table name

    .PARAMETER File
    A valid path to the file to attach

    .EXAMPLE
    Add-ServiceNowAttachment -Number $Number -Table $Table -File .\File01.txt, .\File02.txt

    Upload one or more files to a ServiceNow ticket by specifing the number and table

    .EXAMPLE
    Add-ServiceNowAttachment -Number $Number -Table $Table -File .\File01.txt -ContentType 'text/plain'

    Upload a file and specify the MIME type (content type).  Should only be required if the function cannot automatically determine the type.

    .EXAMPLE
    Add-ServiceNowAttachment -Number $Number -Table $Table -File .\File01.txt -PassThru

    Upload a file and receive back the file details.

    .OUTPUTS
    System.Management.Automation.PSCustomObject

    .NOTES

    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
    Param(
        # Object number
        [Parameter(Mandatory=$true)]
        [string]$Number,

        # Table containing the entry
        [Parameter(Mandatory=$true)]
        [string]$Table,

        # Filter results by file name
        [parameter(Mandatory=$true)]
        [ValidateScript({
            Test-Path $_
        })]
        [string[]]$File,

        # Content (MIME) type - if not automatically determined
        [Parameter(Mandatory=$false)]
        [string]$ContentType,

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
        [Hashtable]$Connection,

        # Allow the results to be shown
        [Parameter()]
        [switch]$PassThru
    )

	begin {}
	process	{
        Try {
            # Use the number and table to determine the sys_id
            $getServiceNowTableEntry = @{
                Table         = $Table
                MatchExact    = @{number = $number}
                ErrorAction   = 'Stop'
            }

            # Update the Table Splat if an applicable parameter set name is in use
            Switch ($PSCmdlet.ParameterSetName) {
                'SpecifyConnectionFields' {
                    $getServiceNowTableEntry.Add('Credential', $Credential)
                    $getServiceNowTableEntry.Add('ServiceNowURL', $ServiceNowURL)
                }
                'UseConnectionObject' {
                    $getServiceNowTableEntry.Add('Connection', $Connection)
                }
                Default {
                    If (-not (Test-ServiceNowAuthIsSet)) {
                        Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                    }
                }
            }

            $TableSysID = Get-ServiceNowTableEntry @getServiceNowTableEntry | Select-Object -Expand sys_id

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

            ForEach ($Object in $File) {
                $FileData = Get-ChildItem $Object -ErrorAction Stop
                If (-not $ContentType) {
                    Add-Type -AssemblyName 'System.Web'
                    $ContentType = [System.Web.MimeMapping]::GetMimeMapping($FileData.FullName)
                }

                # POST: https://instance.service-now.com/api/now/attachment/file?table_name=incident&table_sys_id=d71f7935c0a8016700802b64c67c11c6&file_name=Issue_screenshot
                $Uri = "{0}/file?table_name={1}&table_sys_id={2}&file_name={3}" -f $ApiUrl,$Table,$TableSysID,$FileData.Name

                $invokeRestMethodSplat = @{
                    Uri        = $Uri
                    Headers    = @{'Content-Type' = $ContentType}
                    Method     = 'POST'
                    InFile     = $FileData.FullName
                    Credential = $Credential
                }

                If ($PSCmdlet.ShouldProcess($Uri,$MyInvocation.MyCommand)) {
                    $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

                    If ($PassThru) {
                        $Result | Update-ServiceNowDateTimeField
                    }
                }
            }
        }
        Catch {
            Write-Error $PSItem
        }
    }
	end {}
}
