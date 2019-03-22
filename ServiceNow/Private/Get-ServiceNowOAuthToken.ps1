function Get-ServiceNowOAuthToken {
    [cmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('ServiceNowUrl')]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ClientCredential
    )

    $invokeRestMethodSplat = @{
        Uri     = 'https://{0}/oauth_token.do' -f $Url
        Body    = 'grant_type=password&client_id={0}&client_secret={1}&username={2}&password={3}&' -f @(
            $ClientCredential.UserName,
            $ClientCredential.GetNetworkCredential().Password,
            $Credential.UserName,
            $Credential.GetNetworkCredential().Password
        )
        Method  = 'Post'
    }
    
    $Token = Invoke-RestMethod @invokeRestMethodSplat
    
    $Token.access_token
}
