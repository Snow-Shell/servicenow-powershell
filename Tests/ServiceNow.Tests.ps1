$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$DefaultsFile = Join-Path $projectRoot "Tests\$($ModuleName).Pester.Defaults.json"

# Load defaults from file (merging into $global:ServiceNowPesterTestDefaults)
if(Test-Path $DefaultsFile){
    $defaults = @{}
    # Add properties to the defaults hash
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | ForEach-Object {
        $defaults."$($_.Name)" = $_.Value
    }

    # Prompt for credentials
    $defaults.Creds = if($defaults.Creds){$defaults.Creds}else{Get-Credential}

    $global:ServiceNowPesterTestDefaults = $defaults
}else{
    # Write example file
   @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory = 'Internal'
        TestUserGroup = 'e9e9a2406f4c35001855fa0dba3ee4f3'
        TestUser = "7a4b573a6f3725001855fa0dba3ee485"
    } | ConvertTo-Json | Set-Content $DefaultsFile
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values"
    Return
}

# Load the module (unload it first in case we've made changes since loading it previously)
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleRoot "$moduleName.psd1") -Force

Describe "ServiceNow-Module" {
    If (Test-ServiceNowAuthisSet) {
        Remove-ServiceNowAuth | Should -Be $True
    }

    It "Test-ServiceNowAuthIsSet not set" {
        Test-ServiceNowAuthIsSet | Should -Be $false
    }

    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $defaults.ServiceNowURL -Credentials $defaults.Creds | Should -Be $true
    }

    It "Test-ServiceNowAuthIsSet set" {
        Test-ServiceNowAuthIsSet | Should -Be $true
    }

    It "New-ServiceNowIncident (and by extension New-ServiceNowTableEntry) works" {
        $ShortDescription = "Testing Ticket Creation with Pester"
        $newServiceNowIncidentSplat = @{
            Caller              = $Defaults.TestUser
            ShortDescription    = $ShortDescription
            Description         = "Long description"
            AssignmentGroup     = $Defaults.TestUserGroup
            Comment             = "Comment"
            Category            = $Defaults.TestCategory
            SubCategory         = $Defaults.TestSubcategory
            ConfigurationItem   = $Defaults.TestConfigurationIte
        }
        $TestTicket = New-ServiceNowIncident @newServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription
    }

    It "Get-ServiceNowTable works" {
        # There should be one or more incidents returned
        ([array](Get-ServiceNowTable -Table 'incident' -Query 'ORDERBYDESCopened_at')).Count -gt 0  | Should -Match $true
    }

    It "Get-ServiceNowIncident works" {
        # There should be one or more incidents returned
        ([array](Get-ServiceNowIncident)).count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowRequest works" {
        # There should be one or more incidents returned
        ([array](Get-ServiceNowRequest)).count -gt 0 | Should -Match $true
    }

    It "Update-ServiceNowIncident works" {
        $ShortDescription = "Testing Ticket Update with Pester"
        $newServiceNowIncidentSplat = @{
            Caller              = $Defaults.TestUser
            ShortDescription    = $ShortDescription
            Description         = "Long description"
            AssignmentGroup     = $Defaults.TestUserGroup
            Comment             = "Comment"
            Category            = $Defaults.TestCategory
            SubCategory         = $Defaults.TestSubcategory
            ConfigurationItem   = $Defaults.TestConfigurationItem

        }
        $TestTicket = New-ServiceNowIncident @newServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription

        $Values =
        @{
            'short_description' = 'Ticket Updated with Pester'
            'description' = 'Even Longer Description'
        }

        Update-ServiceNowIncident -SysId $TestTicket.sys_id -Values $Values

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should -Be "Ticket Updated with Pester"
        $TestTicket.description | Should -Be "Even Longer Description"
    }

    It "Get-ServiceNowUserGroup works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUserGroup).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowUser works" {
        # There should be one or more user groups returned
        (Get-ServiceNowUser).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowConfigurationItem works" {
        # There should be one or more configuration items returned
        (Get-ServiceNowConfigurationItem).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowChangeRequest works" {
        (Get-ServiceNowChangeRequest).Count -gt 0 | Should -Match $true
    }

    It "Remove-ServiceNowAuth works" {
        Remove-ServiceNowAuth | Should be $true
    }
}
