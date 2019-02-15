Function Get-ServiceNowAttachmentDetail {
    <#
    .SYNOPSIS
    List details for ServiceNow attachments associated with a ticket number.

    .DESCRIPTION
    List details for ServiceNow attachments associated with a ticket number.

    .PARAMETER Number
    ServiceNow ticket number

    .PARAMETER Table
    ServiceNow ticket table name

    .PARAMETER FileName
    Filter for one or more file names.  Works like a 'match' where partial file names are valid.

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number $Number -Table $Table

    List attachment details

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number $Number -Table $Table -FileName filename.txt,report.csv

    List details for only filename.txt and report.csv (if they exist).

    .OUTPUTS
    System.Management.Automation.PSCustomObject

    .NOTES

    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName)]
    Param(
        # Object number
        [Parameter(Mandatory=$true)]
        [string]$Number,

        # Table containing the entry
        [Parameter(Mandatory=$true)]
        [string]$Table,

        # Filter results by file name
        [parameter(Mandatory=$false)]
        [string[]]$FileName,

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

            # Populate the query
            $Body = @{'sysparm_limit' = 500; 'table_name' = $Table; 'table_sys_id' = $TableSysID}
            $Body.sysparm_query = 'ORDERBYfile_name^ORDERBYDESC'

            # Perform table query and capture results
            $Uri = $ApiUrl

            $invokeRestMethodSplat = @{
                Uri         = $Uri
                Body        = $Body
                Credential  = $Credential
                ContentType = 'application/json'
            }
            $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

            # Filter for requested file names
            If ($FileName) {
                $Result = $Result | Where-Object {$PSItem.file_name -match ($FileName -join '|')}
            }

            $Result | Update-ServiceNowDateTimeField
        }
        Catch {
            Write-Error $PSItem
        }
    }
	end {}
}
