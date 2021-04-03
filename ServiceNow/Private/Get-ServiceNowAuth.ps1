function Get-ServiceNowAuth {
    <#
    .SYNOPSIS
    .DESCRIPTION
    .INPUTS
        None
    .OUTPUTS
        Hashtable
#>

    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param (
        [Parameter()]
        [PSCredential] $Credential,

        [Parameter()]
        [string] $ServiceNowURL,

        [Parameter()]
        [hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    $hashOut = @{}

    # Get credential and ServiceNow REST URL
    if ( $ServiceNowSession.Count -gt 0 ) {
        $hashOut.Uri = $ServiceNowSession.BaseUri
        if ( $ServiceNowSession.AccessToken ) {
            $hashOut.Headers = @{
                'Authorization' = 'Bearer {0}' -f $ServiceNowSession.AccessToken
            }
        } else {
            $hashOut.Credential = $ServiceNowSession.Credential
        }
    } elseif ( $Credential -and $ServiceNowURL ) {
        Write-Warning -Message 'This authentication path, providing URL and credential directly, will be deprecated in a future release.  Please use New-ServiceNowSession.'
        $hashOut.Uri = 'https://{0}/api/now/v1' -f $ServiceNowURL
        $hashOut.Credential = $Credential
    } elseif ( $Connection ) {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $hashOut.Credential = $Credential
        $hashOut.Uri = 'https://{0}/api/now/v1' -f $Connection.ServiceNowUri
    } else {
        throw "Exception:  You must do one of the following to authenticate: `n 1. Call the New-ServiceNowSession cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
    }

    $hashOut
}
