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

    Write-Verbose $PSCmdLet.ParameterSetName

    if ( $ApiVersion -le 0 ) {
        if ( $PSCmdLet.ParameterSetName -eq 'BasicAuth' ) {
            # for existing users the expectation is v1 of the api, keep this for now
            Write-Warning -Message 'A default of v1 of the API will be deprecated in favor of the latest in a future release.'
            $version = '/v1'
        } else {
            $version = ''
        }
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

    Write-Verbose ($newSession | Out-String)

    if ( $PassThru ) {
        $newSession
    } else {
        $Script:ServiceNowSession = $newSession
    }
}
