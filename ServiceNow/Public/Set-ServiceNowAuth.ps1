<#
.SYNOPSIS
Set your Service-Now authentication credentials

.DESCRIPTION
This cmdlet will set your Service-Now authentication credentials which will enable you to interact with Service-Now using the other cmdlets in the module

.PARAMETER Url
The URL of your Service-Now instance

.PARAMETER Credentials
Credentials to authenticate you to the Service-Now instance provided in the Url parameter

.PARAMETER DateFormat
The date format specified in the Service-Now Instance, sys_properties table, property glide.sys.data_format. This is required
to correctly convert datetime fields to the local computer locale format when the DisplayValues parameter of the Get-* functions
is set to true 

.EXAMPLE
Set-ServiceNowAuth -Url tenant.service-now.com

.NOTES
The URL should be the instance name portion of the FQDN for your instance. If you browse to https://yourinstance.service-now.com the URL required for the module is yourinstance.service-now.com

.LINK
    Service-Now Kingston Release REST API Reference: https://docs.servicenow.com/bundle/kingston-application-development/page/build/applications/concept/api-rest.html
    Service-Now Table API FAQ: https://hi.service-now.com/kb_view.do?sysparm_article=KB0534905
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
        $Credentials,

        [parameter(mandatory = $false)]
        [String]
        $DateFormat = (Get-Culture).DateTimeFormat.ShortDatePattern+' '+(Get-Culture).DateTimeFormat.LongTimePattern
    )

    $Global:serviceNowUrl = 'https://' + $Url
    $Global:serviceNowRestUrl = $serviceNowUrl + '/api/now/v1'
    $Global:serviceNowCredentials = $Credentials
    $Global:ServiceNowDateFormat = $DateFormat

    return $true
}
