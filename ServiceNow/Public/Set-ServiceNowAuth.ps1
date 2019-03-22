function Set-ServiceNowAuth {
    <#
    .SYNOPSIS
    Set your Service-Now authentication credentials

    .DESCRIPTION
    This cmdlet will set your Service-Now authentication credentials.
    This will enable you to interact with Service-Now using the other cmdlets in the module

    .PARAMETER Url
    The URL of your Service-Now instance

    .PARAMETER Credential
    Credentials to authenticate you to the Service-Now instance provided in the Url parameter

    .PARAMETER ClientCredential
    Client PSCredential Object consisting of ClientID/Client Secret.
    Requires an OAuth API endpoint for external clients setup in ServiceNow

    .EXAMPLE
    Set-ServiceNowAuth -Url $domain -Credential $usercreds

    .EXAMPLE
    Set-ServiceNowAuth -Url $domain -Credental $usercreds -ClientCredential $clientcreds
    #>

    [CmdletBinding(DefaultParameterSetName = 'AccessToken')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments','')]
    Param (
        [Parameter(Mandatory = $true,
            ParameterSetName = 'BasicAuth')]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('ServiceNowUrl')]
        [string]$Url,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'BasicAuth')]
        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [Alias('Credentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [System.Management.Automation.PSCredential]
        $ClientCredential
    )
    $Script:ConnectionObj = @{
        Uri = $Url
    }

    if ($Pscmdlet.ParameterSetName -eq 'AccessToken') {
        $AccessToken = Get-ServiceNowOAuthToken -Url $Url -ClientCredential $ClientCredential -UserCredential $UserCredential -Verbose
        $Script:ConnectionObj.Add('AccessToken', $AccessToken)
    }
    else {
        $Script:ConnectionObj.Add('Credential', $Credential)
    }
}
