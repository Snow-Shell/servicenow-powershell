<#
$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleName = "PoshServiceNow"
#>

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$DefaultsFile = Join-Path $projectRoot "Tests\$($ModuleName).Pester.Defaults.json"

# Load defaults from file (merging into $global:ServiceNowPesterTestDefaults)
if(Test-Path $DefaultsFile){
    $defaults = if($global:ServiceNowPesterTestDefaults){$global:ServiceNowPesterTestDefaults}else{@{}};
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | ForEach-Object {
        $defaults."$($_.Name)" = $_.Value
    }

    ###########################
    #
    #Cheating here with the credentials
    #
    ###########################
    $defaults.Creds = (Get-MDSCredentials User)
    
    # Prompt for credentials
    $defaults.Creds = if($defaults.Creds){$defaults.Creds}else{Get-Credential}

    $global:ServiceNowPesterTestDefaults = $defaults
}else{
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values"
    
    # Write example file
   @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory = 'Internal'
        TestUserGroup = 'e9e9a2406f4c35001855fa0dba3ee4f3'
        TestUser = "7a4b573a6f3725001855fa0dba3ee485"
    } | ConvertTo-Json | Set-Content $DefaultsFile
    return
}

# Load the module (unload it first in case we've made changes since loading it previously)
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -Force

Describe "ServiceNow-Module" {
        
    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $defaults.ServiceNowURL -Credentials $defaults.Creds | Should be $true
    }

    It "New-ServiceNowIncident (and by extension New-ServiceNowTableEntry) works" {
        $TestTicket = New-ServiceNowIncident -ShortDescription "Testing with Pester" `
            -Description "Long description" -AssignmentGroup $defaults.TestUserGroup `
            -Category $defaults.TestCategory -SubCategory $Defaults.TestSubcategory `
            -Comment "Comment" -ConfigurationItem $defaults.TestConfigurationItem `
            -Caller $defaults.TestUser `

        $TestTicket.short_description | Should be "Testing with Pester"               
    }

    It "Get-ServiceNowTable works" {
        # There should be one or more incidents returned
        (Get-ServiceNowTable -Table 'incident' -Query 'ORDERBYDESCopened_at').Count -gt 0  | Should Match $true
    }

    It "Get-ServiceNowIncident works" {
        # There should be one or more incidents returned
        (Get-ServiceNowIncident).Count -gt 0 | Should Match $true
    }

    It "Update-ServiceNowIncident works" {        
         $TestTicket = New-ServiceNowIncident -ShortDescription "Testing Ticket Update with Pester" `
            -Description "Long description" -AssignmentGroup $defaults.TestUserGroup `
            -Category $defaults.TestCategory -SubCategory $Defaults.TestSubcategory `
            -Comment "Comment" -ConfigurationItem $defaults.TestConfigurationItem `
            -Caller $defaults.TestUser `
        
        $TestTicket.short_description | Should be "Testing Ticket Update with Pester"    
                
        $Values = 
        @{
            'short_description' = 'Ticket Updated with Pester'
            'description' = 'Even Longer Description'            
        }                
        
        Update-ServiceNowIncident -SysId $TestTicket.sys_id -Values $Values

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should be "Ticket Updated with Pester"    
        $TestTicket.description | Should be "Even Longer Description"    
    }

    It "Get-ServiceNowUserGroup works" {        
        # There should be one or more user groups returned
        (Get-ServiceNowUserGroup).Count -gt 0 | Should Match $true
    }

    It "Get-ServiceNowUser works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUser).Count -gt 0 | Should Match $true
    }

    It "Get-ServiceNowConfigurationItem works" {
        # There should be one or more configuration items returned
        (Get-ServiceNowConfigurationItem).Count -gt 0 | Should Match $true
    }

    It "Get-ServiceNowChangeRequest works" {     
        (Get-ServiceNowChangeRequest).Count -gt 0 | Should Match $true
    }
}