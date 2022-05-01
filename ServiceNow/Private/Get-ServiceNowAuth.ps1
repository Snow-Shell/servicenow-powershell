function Get-ServiceNowAuth {
    <#
    .SYNOPSIS
        Return hashtable with base Uri and auth info. Add uri leaf, body, etc to output.
    .DESCRIPTION
    .INPUTS
        None
    .OUTPUTS
        Hashtable
    #>

    [OutputType([Hashtable])]
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'requirement of azure automation')]

    param (
        [Parameter()]
        [Alias('C')]
        [Hashtable] $Connection,

        [Parameter()]
        [Alias('S')]
        [Hashtable] $ServiceNowSession
    )

    begin {
        $HashOut = @{}
    }

    process {
        if ( $ServiceNowSession.Count -gt 0 ) {
            $HashOut.Uri = $ServiceNowSession.BaseUri
            if ( $ServiceNowSession.AccessToken ) {
                $HashOut.Headers = @{
                    'Authorization' = 'Bearer {0}' -f $ServiceNowSession.AccessToken.GetNetworkCredential().password
                }
            } else {
                $HashOut.Credential = $ServiceNowSession.Credential
            }

            if ( $ServiceNowSession.Proxy ) {
                $HashOut.Proxy = $ServiceNowSession.Proxy
                if ( $ServiceNowSession.ProxyCredential ) {
                    $HashOut.ProxyCredential = $ServiceNowSession.ProxyCredential
                } else {
                    $HashOut.ProxyUseDefaultCredentials = $true
                }
            }
        } elseif ( $Connection ) {
            Write-Verbose 'connection'
            $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
            $HashOut.Credential = $Credential
            $HashOut.Uri = 'https://{0}/api/now/v1' -f $Connection.ServiceNowUri
        } else {
            throw 'You must authenticate by either calling the New-ServiceNowSession cmdlet or passing in an Azure Automation connection object'
        }
    }

    end {
        $HashOut
    }
}
