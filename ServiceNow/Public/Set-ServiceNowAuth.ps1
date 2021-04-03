function Set-ServiceNowAuth {
<#
    .SYNOPSIS
    Set your Service-Now authentication credentials

    .DESCRIPTION
    This cmdlet will set your Service-Now authentication credentials which will enable you to interact with Service-Now using the other cmdlets in the module

    .PARAMETER Url
    The URL of your Service-Now instance

    .PARAMETER Credentials
    Credentials to authenticate you to the Service-Now instance provided in the Url parameter

    .EXAMPLE
    Set-ServiceNowAuth -Url tenant.service-now.com

    .NOTES
    The URL should be the instance name portion of the FQDN for your instance. If you browse to https://yourinstance.service-now.com the URL required for the module is yourinstance.service-now.com
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [ValidateScript({$_ | Test-ServiceNowURL})]
        [Alias('ServiceNowUrl')]
        [string] $Url,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential] $Credentials
    )
    Write-Warning -Message 'Set-ServiceNowAuth will be deprecated in a future release.  Please use New-ServiceNowSession.  Also, the current default of v1 of the API will be deprecated in favor of the latest in a future release.  Set-ServiceNowAuth will utilize v1.  To test the latest API, use New-ServiceNowSession.'
    New-ServiceNowSession -Url $Url -Credential $Credentials -ApiVersion 1
    return $true
}
