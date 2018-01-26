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
function Set-ServiceNowAuth {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ($_ -match '^\w+\..*\.\w+') {
                    $true
                }
                else {
                    Throw "The expected URL format is tenant.domain.com"
                }
            })]
        [string]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credentials
    )
    $Global:serviceNowUrl = 'https://' + $Url
    $Global:serviceNowRestUrl = $serviceNowUrl + '/api/now/v1'
    $Global:serviceNowCredentials = $Credentials
    return $true
}
