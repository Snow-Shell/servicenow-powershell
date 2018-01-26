function Set-ServiceNowAuth {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if ($_ -notlike 'https://*') {
                    $true
                }
                else {
                    Throw "Please exclude https:// from your URL parameter: $_ "
                } })]
        [string]$url,
        
        [parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credentials
    )
    $Global:ServiceNowURL = 'https://' + $url
    $Global:ServiceNowRESTURL = $ServiceNowURL + '/api/now/v1'
    $Global:ServiceNowCredentials = $credentials
    return $true
}
