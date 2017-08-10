function Set-ServiceNowAuth{
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credentials
    )
    $Global:ServiceNowURL = 'https://' + $url
    $Global:ServiceNowRESTURL = $ServiceNowURL + '/api/now/v1'
    $Global:ServiceNowCredentials = $credentials
    return $true;
}
