$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$DefaultsFile = Join-Path $projectRoot "Tests\$($ModuleName).Pester.Defaults.json"

# Load defaults from file
if (Test-Path $DefaultsFile) {
    $Defaults = @{}
    # Add properties to the defaults hash
    (Get-Content $DefaultsFile | Out-String | ConvertFrom-Json).psobject.properties | ForEach-Object {
        $Defaults."$($_.Name)" = $_.Value
    }

    # Prompt for credentials
    $Defaults.Creds = if ($Defaults.Creds) {
        $Defaults.Creds
    } else {
        Get-Credential
    }
} else {
    # Write example file
   @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory  = 'Internal'
        TestUserGroup = 'e9e9a2406f4c35001855fa0dba3ee4f3'
        TestUser      = "7a4b573a6f3725001855fa0dba3ee485"
    } | ConvertTo-Json | Set-Content $DefaultsFile
    Write-Error "$DefaultsFile does not exist. Created example file. Please populate with your values"
    Return
}

# Load the module (unload it first in case we've made changes since loading it previously)
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleRoot "$moduleName.psd1") -Force

Describe "ServiceNow-Module" {
    # Ensure auth is not set (not a test)
    If (Test-ServiceNowAuthisSet) {
        Remove-ServiceNowAuth
    }

    # Auth Functions
    It "Test-ServiceNowAuthIsSet not set" {
        Test-ServiceNowAuthIsSet | Should -Be $false
    }

    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $Defaults.ServiceNowURL -Credentials $Defaults.Creds | Should -Be $true
    }

    It "Test-ServiceNowAuthIsSet set" {
        Test-ServiceNowAuthIsSet | Should -Be $true
    }

    # Get Functions
    It "Get-ServiceNowTable returns records" {
        ([array](Get-ServiceNowTable -Table 'incident' -Query 'ORDERBYDESCopened_at')).Count -gt 0  | Should -Match $true
    }

    It "Get-ServiceNowTable with SpecifyConnectionFields param set returns records" {
        $getServiceNowTableSplat = @{
            Table                = 'incident'
            Query                = 'ORDERBYDESCopened_at'
            ServiceNowCredential = $Defaults.Creds
            ServiceNowURL        = $Defaults.ServiceNowURL
        }
        ([array](Get-ServiceNowTable @getServiceNowTableSplat)).Count -gt 0  | Should -Match $true
    }

    It "Get-ServiceNowTableEntry returns records" {
        ([array](Get-ServiceNowTableEntry -Table incident)).count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowIncident returns records" {
        ([array](Get-ServiceNowIncident)).count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowRequest returns records" {
        ([array](Get-ServiceNowRequest)).count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowRequestItem returns records" {
        ([array](Get-ServiceNowRequestItem)).count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowUserGroup works" {
        (Get-ServiceNowUserGroup).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowUser works" {
        (Get-ServiceNowUser).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowConfigurationItem works" {
        (Get-ServiceNowConfigurationItem).Count -gt 0 | Should -Match $true
    }

    It "Get-ServiceNowChangeRequest works" {
        (Get-ServiceNowChangeRequest).Count -gt 0 | Should -Match $true
    }

    # New Functions
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

    # Update functions
    It "Update-ServiceNowChangeRequest works" {
        $TestTicket = Get-ServiceNowChangeRequest -Limit 1

        $Values = @{
            description = 'Pester Comment:  Update-ServiceNowChangeRequest works'
        }

        $updateServiceNowNumberSplat = @{
            SysID  = $TestTicket.sys_id
            Values = $Values
        }
        $UpdatedTicket = Update-ServiceNowChangeRequest @updateServiceNowNumberSplat

        $UpdatedTicket.description | Should -Be 'Pester Comment:  Update-ServiceNowChangeRequest works'

        $Values = @{
            description = $TestTicket.description
        }

        $updateServiceNowNumberSplat = @{
            SysID  = $TestTicket.sys_id
            Values = $Values
        }
        $null = Update-ServiceNowChangeRequest @updateServiceNowNumberSplat

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

        $Values = @{
            'short_description' = 'Ticket Updated with Pester'
            'description' = 'Even Longer Description'
        }

        $null = Update-ServiceNowIncident -SysId $TestTicket.sys_id -Values $Values

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should -Be "Ticket Updated with Pester"
        $TestTicket.description | Should -Be "Even Longer Description"
    }

    It "Update-ServiceNowNumber works" {
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

        $Values = @{
            'short_description' = 'Ticket Updated with Pester (Update-ServiceNowNumber)'
            'description'       = 'Updated by Pester test Update-ServiceNowNumber works'
        }

        $updateServiceNowNumberSplat = @{
            Number = $TestTicket.Number
            Table  = 'incident'
            Values = $Values
        }
        Update-ServiceNowNumber @updateServiceNowNumberSplat

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should -Be 'Ticket Updated with Pester (Update-ServiceNowNumber)'
        $TestTicket.description | Should -Be 'Updated by Pester test Update-ServiceNowNumber works'
    }

    It "Update-ServiceNowNumber with SpecifyConnectionFields works" {
        $ShortDescription = 'Testing Ticket Update with Pester'
        $newServiceNowIncidentSplat = @{
            Caller              = $Defaults.TestUser
            ShortDescription    = $ShortDescription
            Description         = 'Long description'
            AssignmentGroup     = $Defaults.TestUserGroup
            Comment             = 'Comment'
            Category            = $Defaults.TestCategory
            SubCategory         = $Defaults.TestSubcategory
            ConfigurationItem   = $Defaults.TestConfigurationItem
        }
        $TestTicket = New-ServiceNowIncident @newServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription

        $Values = @{
            'short_description' = 'Ticket Updated with Pester (Update-ServiceNowNumber)'
            'description'       = 'Updated by Pester test Update-ServiceNowNumber with SpecifyConnectionFields works'
        }

        $updateServiceNowNumberSplat = @{
            Number        = $TestTicket.Number
            Table         = 'incident'
            Values        = $Values
            Credential    = $Defaults.Creds
            ServiceNowURL = $Defaults.ServiceNowURL
        }
        Update-ServiceNowNumber @updateServiceNowNumberSplat

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should -Be 'Ticket Updated with Pester (Update-ServiceNowNumber)'
        $TestTicket.description | Should -Be 'Updated by Pester test Update-ServiceNowNumber with SpecifyConnectionFields works'
    }

    # Remove Functions
    It "Remove-ServiceNowTable works" {
        $TestTicket = Get-ServiceNowIncident -Limit 1
        $removeServiceNowTableEntrySplat = @{
            SysId = $TestTicket.sys_id
            Table = 'incident'
        }
        Remove-ServiceNowTableEntry @removeServiceNowTableEntrySplat

        $getServiceNowIncidentSplat = @{
            MatchExact = @{sys_id=$($Ticket.sys_id)}
            ErrorAction = 'Stop'
        }
        {Get-ServiceNowIncident @getServiceNowIncidentSplat} | Should -Throw '(404) Not Found'
    }

    It "Remove-ServiceNowAuth works" {
        Remove-ServiceNowAuth | Should be $true
    }
}
