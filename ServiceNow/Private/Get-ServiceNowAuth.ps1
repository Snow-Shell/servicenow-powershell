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

    param (
        [Parameter()]
        [Alias('N')]
        [string] $Namespace = 'now',

        [Parameter()]
        [Alias('S')]
        [hashtable] $ServiceNowSession
    )

    begin {
        $hashOut = @{}
    }

    process {

        if ( $ServiceNowSession.Count -gt 0 ) {
            $hashOut.Uri = $ServiceNowSession.BaseUri + $Namespace
            if ($ServiceNowSession.Version) { $hashOut.uri = $hashOut.uri + $ServiceNowSession.Version }

            # check if we need a new access token
            if ( $ServiceNowSession.ExpiresOn -lt (Get-Date) -and $ServiceNowSession.ClientCredential ) {
                
                # Build refresh/re-auth body based on grant type
                $refreshBody = @{
                    client_id     = $ServiceNowSession.ClientCredential.UserName
                    client_secret = $ServiceNowSession.ClientCredential.GetNetworkCredential().password
                }

                if ($ServiceNowSession.GrantType -eq 'client_credentials') {
                    # Client credentials: re-authenticate (no refresh token available)
                    $refreshBody['grant_type'] = 'client_credentials'
                }
                elseif ($ServiceNowSession.RefreshToken) {
                    # Password grant: use refresh token
                    $refreshBody['grant_type'] = 'refresh_token'
                    $refreshBody['refresh_token'] = $ServiceNowSession.RefreshToken.GetNetworkCredential().password
                }
                else {
                    Write-Warning 'Access token expired but no refresh method available'
                }

                if ($refreshBody.ContainsKey('grant_type')) {
                    $refreshParams = @{
                        Uri         = 'https://{0}/oauth_token.do' -f $ServiceNowSession.Domain
                        Method      = 'POST'
                        ContentType = 'application/x-www-form-urlencoded'
                        Body        = $refreshBody
                    }

                    $response = Invoke-RestMethod @refreshParams

                    $ServiceNowSession.AccessToken = New-Object System.Management.Automation.PSCredential('AccessToken', ($response.access_token | ConvertTo-SecureString -AsPlainText -Force))
                    
                    # Update refresh token if provided (password grant only)
                    if ($response.refresh_token) {
                         $ServiceNowSession.RefreshToken = New-Object System.Management.Automation.PSCredential('RefreshToken', ($response.refresh_token | ConvertTo-SecureString -AsPlainText -Force))
                    }

                    if ($response.expires_in) {
                        $ServiceNowSession.ExpiresOn = (Get-Date).AddSeconds($response.expires_in)
                        Write-Verbose ('Access token has been refreshed and will expire at {0}' -f $ServiceNowSession.ExpiresOn)
                    }

                    # ensure script/module scoped variable is updated
                    $script:ServiceNowSession = $ServiceNowSession
                }
            }

            if ( $ServiceNowSession.AccessToken ) {
                $hashOut.Headers = @{
                    'Authorization' = 'Bearer {0}' -f $ServiceNowSession.AccessToken.GetNetworkCredential().password
                }
            } else {
                # issue 248
                $pair = '{0}:{1}' -f $ServiceNowSession.Credential.UserName, $ServiceNowSession.Credential.GetNetworkCredential().Password
                $hashOut.Headers = @{ Authorization = 'Basic ' + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair)) }
            }

            if ( $ServiceNowSession.Proxy ) {
                $hashOut.Proxy = $ServiceNowSession.Proxy
                if ( $ServiceNowSession.ProxyCredential ) {
                    $hashOut.ProxyCredential = $ServiceNowSession.ProxyCredential
                } else {
                    $hashOut.ProxyUseDefaultCredentials = $true
                }
            }
        # } elseif ( $Connection ) {
        #     Write-Verbose 'connection'
        #     # issue 248
        #     $pair = '{0}:{1}' -f $Connection.Username, $Connection.Password
        #     $hashOut.Headers = @{ Authorization = 'Basic ' + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair)) }
        #     $hashOut.Uri = 'https://{0}/api/{1}/v1' -f $Connection.ServiceNowUri, $Namespace
        } elseif ( $env:SNOW_SERVER ) {
            $hashOut.Uri = 'https://{0}/api/{1}' -f $env:SNOW_SERVER, $Namespace
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
            throw "You must authenticate by calling the New-ServiceNowSession cmdlet"
        }
    }

    end {
        $hashOut.Clone()
    }
}
