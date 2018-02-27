function Set-ServiceNowAuth{
<#
.SYNOPSIS
    Configures default connection settings for the Service-Now Instance 
.DESCRIPTION
    The Set-ServiceNowAuth function configures default connection settings for the Service-Now Instance. These include the instance URL,
    authentication credentials and date format.
.INPUTS
    None
.OUTPUTS
    System.Boolean
.LINK
    Service-Now Kingston Release REST API Reference: https://docs.servicenow.com/bundle/kingston-application-development/page/build/applications/concept/api-rest.html
    Service-Now Table API FAQ: https://hi.service-now.com/kb_view.do?sysparm_article=KB0534905
#>
param(
        # The URL for the ServiceNow instance being used
        [parameter(mandatory=$true)]
        [string]$url,
        
        # Credential used to authenticate to ServiceNow
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credentials,

        # The date format specified in the Service-Now Instance, sys_properties table, property glide.sys.data_format. This is required
        # to correctly convert datetime fields to the local computer locale format when the DisplayValues parameter of the Get-* functions
        # is set to true 
        [parameter(mandatory=$false)]
        [String]$DateFormat=(Get-Culture).DateTimeFormat.ShortDatePattern+' '+(Get-Culture).DateTimeFormat.LongTimePattern
        )

    $Global:ServiceNowURL = 'https://' + $url
    $Global:ServiceNowRESTURL = $ServiceNowURL + '/api/now/v1'
    $Global:ServiceNowCredentials = $credentials
    $Global:ServiceNowDateFormat = $DateFormat
    
    return $true;
}
