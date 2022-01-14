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
            }
            else {
                $hashOut.Credential = $ServiceNowSession.Credential
            }

            if ( $ServiceNowSession.Proxy ) {
                $hashOut.Proxy = $ServiceNowSession.Proxy
                if ( $ServiceNowSession.ProxyCredential ) {
                    $hashOut.ProxyCredential = $ServiceNowSession.ProxyCredential
                }
                else {
                    $hashOut.ProxyUseDefaultCredentials = $true
                }
            }
        }
        elseif ( $Connection ) {
            Write-Verbose 'connection'
            $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
            $hashOut.Credential = $Credential
            $hashOut.Uri = 'https://{0}/api/now/v1' -f $Connection.ServiceNowUri
        } else {
            throw "You must authenticate by either calling the New-ServiceNowSession cmdlet or passing in an Azure Automation connection object"
        }
    }

    end {
        $hashOut
    }
}
