<#
.SYNOPSIS
Requests and refreshes access token

.DESCRIPTION
Requests and refreshes access token

.PARAMETER Url
The URL of your Service-Now instance

.PARAMETER Credentials
Credentials to authenticate you to the Service-Now instance provided in the Url parameter

.EXAMPLE
Please use Set-ServiceNowAuth. It calls this function.


#>

function Set-ServiceNowAuthToken {

    [cmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ClientID,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $ClientSecret,

        [switch]$renewToken=$false

    )

    if($renewToken -eq $true){
        try{
            $Token = Invoke-RestMethod -Uri $serviceNowUrl/oauth_token.do -Body "grant_type=refresh_token&client_id=$clientID&client_secret=$clientSecret&refresh_token=$RefreshToken" -Method Post
            Write-Host "Token Renew Successful" -ForegroundColor Green
         }

         catch{
            Write-Host "There was a problem with the information supplied" -ForegroundColor Red
            return $false
         }
        
        $global:AccessToken = $Token.access_token
        return $true
    }
    
    else{

        $Username = $ServiceNowCredentials.Username
        $Password = $serviceNowCredentials.GetNetworkCredential().password

        try{
            $Token = Invoke-RestMethod -Uri $serviceNowUrl/oauth_token.do -Body "grant_type=password&client_id=$clientID&client_secret=$clientSecret&username=$Username&password=$password" -Method Post
            Write-Host "Token Request Successful" -ForegroundColor Green
        }
        
        catch{
            Write-Host "There was a problem with the information supplied" -ForegroundColor Red
            return $false
        }
        
        $global:AccessToken = $Token.access_token
        $global:RefreshToken = $Token.refresh_token
        return $true
    }

}