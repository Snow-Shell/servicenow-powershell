function Set-ServiceNowAuth {
    <#
    .SYNOPSIS
    Set your Service-Now authentication credentials

    .DESCRIPTION
    This cmdlet will set your Service-Now authentication credentials.
    This will enable you to interact with Service-Now using the other cmdlets in the module

    .PARAMETER Url
    The URL of your Service-Now instance

    .PARAMETER Credentials
    Credentials to authenticate you to the Service-Now instance provided in the Url parameter

    .PARAMETER ClientCredential
    Client PSCredential Object consisting of ClientID/Client Secret.
    Requires an OAuth API endpoint for external clients setup in ServiceNow

    .PARAMETER UserCredential
    User PSCredential Object consisting of UserID/User Password of a standard user with roles in ServiceNow

    .EXAMPLE
    Set-ServiceNowAuth -Url $domain -ClientCredential $clientcreds -UserCredential $usercreds
    #>

    [CmdletBinding(DefaultParameterSetName = 'AccessToken')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments','')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('ServiceNowUrl')]
        [string]$Url,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Credential')]
        [Alias('Credentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [System.Management.Automation.PSCredential]
        $ClientCredential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [System.Management.Automation.PSCredential]
        $UserCredential
    )

    $Global:serviceNowUrl = 'https://{0}' -f $Url
    $Global:serviceNowRestUrl = 'https://{0}/api/now/v1' -f $Url

    if ($Pscmdlet.ParameterSetName -eq 'AccessToken') {
        $AccessToken = Get-ServiceNowOAuthToken -Url $Url -ClientCredential $ClientCredential -UserCredential $UserCredential -Verbose
        $Global:AccessToken =  $AccessToken
    }
    else {
        $Global:Credential = $Credential
    }
}
