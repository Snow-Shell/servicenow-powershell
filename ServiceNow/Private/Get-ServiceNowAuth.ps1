function Get-ServiceNowAuth {
    <#
    .SYNOPSIS
        Return hashtable with base Uri and auth info.  Add uri leaf, body, etc to output.
    .DESCRIPTION
    .INPUTS
        None
    .OUTPUTS
        Hashtable
#>

    [OutputType([Hashtable])]
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'requirement of azure automation')]

    Param (
        [Parameter()]
        [Alias('C')]
        [hashtable] $Connection,

        [Parameter()]
        [Alias('S')]
        [hashtable] $ServiceNowSession
    )

    begin {
        $hashOut = @{}
    }

    process {

        if ( $ServiceNowSession.Count -gt 0 ) {
            $hashOut.Uri = $ServiceNowSession.BaseUri
            if ( $ServiceNowSession.AccessToken ) {
                $hashOut.Headers = @{
                    'Authorization' = 'Bearer {0}' -f $ServiceNowSession.AccessToken.GetNetworkCredential().password
                }
            } else {
                $hashOut.Credential = $ServiceNowSession.Credential
            }

            if ( $ServiceNowSession.Proxy ) {
                $hashOut.Proxy = $ServiceNowSession.Proxy
                if ( $ServiceNowSession.ProxyCredential ) {
                    $hashOut.ProxyCredential = $ServiceNowSession.ProxyCredential
                } else {
                    $hashOut.ProxyUseDefaultCredentials = $true
                }
            }
        } elseif ( $Connection ) {
            Write-Verbose 'connection'
            $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
            $hashOut.Credential = $Credential
            $hashOut.Uri = 'https://{0}/api/now/v1' -f $Connection.ServiceNowUri
        } elseif ( $env:SNOW_SERVER ) {
            $hashOut.Uri = 'https://{0}/api/now' -f $env:SNOW_SERVER
            if ( $env:SNOW_TOKEN ) {
                $hashOut.Headers = @{
                    'Authorization' = 'Bearer {0}' -f $env:SNOW_TOKEN
                }
            } elseif ( $env:SNOW_USER -and $env:SNOW_PASS ) {
                $hashOut.Credential = New-Object System.Management.Automation.PSCredential($env:SNOW_USER, ($env:SNOW_PASS | ConvertTo-SecureString -AsPlainText -Force))
            } else {
                throw 'A ServiceNow server environment variable has been set, but authentication via SNOW_TOKEN or SNOW_USER/SNOW_PASS was not found'
            }
        } else {
            throw "You must authenticate by either calling the New-ServiceNowSession cmdlet or passing in an Azure Automation connection object"
        }
    }

    end {
        $hashOut.Clone()
    }
}
