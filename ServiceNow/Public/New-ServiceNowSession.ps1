<#
.SYNOPSIS
Create a new ServiceNow session

.DESCRIPTION

#>
function New-ServiceNowSession {

    [CmdletBinding(DefaultParameterSetName = 'BasicAuth')]

    param(
        [Parameter(Mandatory)]
        [ValidateScript( { $_ | Test-ServiceNowURL })]
        [Alias('ServiceNowUrl')]
        [string] $Url,

        [Parameter(Mandatory, ParameterSetName = 'BasicAuth')]
        [Parameter(Mandatory, ParameterSetName = 'OAuth')]
        [Alias('Credentials')]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory, ParameterSetName = 'OAuth')]
        [System.Management.Automation.PSCredential] $ClientCredential,

        [Parameter(Mandatory, ParameterSetName = 'AccessToken')]
        [string] $AccessToken,

        [Parameter()]
        [int] $ApiVersion,

        [Parameter()]
        [switch] $PassThru
    )

    if ( $ApiVersion -le 0 ) {
        $version = ''
    } else {
        $version = ('/v{0}' -f $ApiVersion)
    }

    $newSession = @{
        Domain = $Url
        BaseUri = ('https://{0}/api/now{1}' -f $Url, $version)
    }

    switch ($PSCmdLet.ParameterSetName) {
        'OAuth' {
            $params = @{
                Uri    = 'https://{0}/oauth_token.do' -f $Url
                Body   = @{
                    'grant_type'    = 'password'
                    'client_id'     = $ClientCredential.UserName
                    'client_secret' = $ClientCredential.GetNetworkCredential().Password
                    'username'      = $Credential.UserName
                    'password'      = $Credential.GetNetworkCredential().Password
                }
                Method = 'Post'
            }

            $token = Invoke-RestMethod @params
            $newSession.Add('AccessToken', $token.access_token)
            $newSession.Add('RefreshToken', $token.refresh_token)
        }
        'AccessToken' {
            $newSession.Add('AccessToken', $AccessToken)
        }
        'BasicAuth' {
            $newSession.Add('Credential', $Credential)
        }
        'SSO' {

        }
        Default {

        }
    }

    if ( $PassThru ) {
        $newSession
    } else {
        $Script:ServiceNowSession = $newSession
    }
}
