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

    [CmdletBinding(DefaultParameterSetName,SupportsShouldProcess=$true)]
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
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory=$false)]
        [hashtable]$Values,

        # Switch to allow the results to be passed back
        [parameter(Mandatory=$false)]
        [switch]$PassThru
    )

    begin {}
    process {
        Try {
            # Prep a splat to use the provided number to find the sys_id
            $getServiceNowTableEntry = @{
                Table         = $Table
                MatchExact    = @{number = $number}
                ErrorAction   = 'Stop'
            }

            # Process credential steps based on parameter set name
            Switch ($PSCmdlet.ParameterSetName) {
                'SpecifyConnectionFields' {
                    $getServiceNowTableEntry.Add('ServiceNowCredential',$Credential)
                    $getServiceNowTableEntry.Add('ServiceNowURL',$ServiceNowURL)
                    $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1'
                }
                'UseConnectionObject' {
                    $getServiceNowTableEntry.Add('Connection',$Connection)
                    $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
                    $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
                    $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
                }
                Default {
                    If ((Test-ServiceNowAuthIsSet)) {
                        $Credential = $Global:ServiceNowCredentials
                        $ServiceNowURL = $Global:ServiceNowRESTURL
                    }
                    Else {
                        Throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
                    }
                }
            }

            # Use the number and table to determine the sys_id
            $SysID = Get-ServiceNowTableEntry @getServiceNowTableEntry | Select-Object -Expand sys_id

            # Convert the values to Json and encode them to an UTF8 array to support special chars
            $Body = $Values | ConvertTo-Json
            $utf8Bytes = [System.Text.Encoding]::Utf8.GetBytes($Body)

            # Setup splat
            $Uri = $ServiceNowURL + "/table/$Table/$SysID"
            $invokeRestMethodSplat = @{
                Uri         = $uri
                Method      = 'Patch'
                Credential  = $Credential
                Body        = $utf8Bytes
                ContentType = 'application/json'
            }

            If ($PSCmdlet.ShouldProcess("$Table/$SysID",$MyInvocation.MyCommand)) {
                # Send REST call
                $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

                # Option to return results
                If ($PSBoundParameters.ContainsKey('Passthru')) {
                    $Result
                }
            }
        }
        Catch {
            Write-Error $PSItem
        }
    }
    end {}
}
