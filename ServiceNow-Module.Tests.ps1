$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultsFile = "$here\ServiceNow-Module.Pester.Defaults.json"

# Load defaults from file (merging into $global:ServiceNowPesterTestDefaults
if(Test-Path $DefaultsFile){
    $defaults = if($global:ServiceNowPesterTestDefaults){$global:ServiceNowPesterTestDefaults}else{@{}};
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | %{$defaults."$($_.Name)" = $_.Value}
    
    # Prompt for credentials
    $defaults.Creds = if($defaults.Creds){$defaults.Creds}else{Get-Credential}

    $global:ServiceNowPesterTestDefaults = $defaults
}else{
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values";
    
    # Write example file
   @{
        ServiceNowURL = 'testingurl.service-now.com'
    } | ConvertTo-Json | Set-Content $DefaultsFile
    return;
}

# Load the module (unload it first in case we've made changes since loading it previously)
Remove-Module ServiceNow-Module -ErrorAction SilentlyContinue
Import-Module $here\ServiceNow-Module.psm1   

Describe "ServiceNow-Module" {
    
    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $defaults.ServiceNowURL -Credentials $defaults.Creds | Should be $true
    }

    It "Get-ServiceNowTable works" {
        # There should be one or more incidents returned
        (Get-ServiceNowTable -Table 'incident' -Query 'ORDERBYDESCopened_at').Count | Should Match '\d?'
    }

    It "Get-ServiceNowIncident works" {
        # There should be one or more incidents returned
        (Get-ServiceNowIncident).Count | Should Match '\d?'
    }
}