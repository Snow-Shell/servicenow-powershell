[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [ValidateNotNullorEmpty()]
    [PSCredential]$Credential
)

$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psd1")
$ModuleName = Split-Path $ModuleRoot -Leaf
$ModulePsd = (Resolve-Path "$ProjectRoot\*\$ModuleName.psd1").Path
$ModulePsm = (Resolve-Path "$ProjectRoot\*\$ModuleName.psm1").Path
$DefaultsFile = Join-Path $ProjectRoot "Tests\$($ModuleName).Pester.Defaults.json"

$ModuleLoaded = Get-Module $ModuleName
If ($null -eq $ModuleLoaded) {
    Import-Module $ModulePSD -Force
}
ElseIf ($null -ne $ModuleLoaded -and $ModuleLoaded -ne $ModulePSM) {
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    Import-Module $ModulePSD -Force
}

# Load defaults from file
If (Test-Path $DefaultsFile) {
    $Script:Defaults = Get-Content $DefaultsFile -Raw | ConvertFrom-Json

    If ('testingurl.service-now.com' -eq $Defaults.ServiceNowUrl) {
        Throw 'Please populate the *.Pester.Defaults.json file with your values'
    }
}
Else {
    # Write example file
    @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory  = 'Internal'
        TestUserGroup = '8a4dde73c6112278017a6a4baf547aa7'
        TestUser      = '6816f79cc0a8016401c5a33be04be441'
    } | ConvertTo-Json | Set-Content $DefaultsFile
    Throw "$DefaultsFile does not exist. Created example file. Please populate with your values"
}

Describe "ServiceNow-Module" {
    # Ensure auth is not set (not a test)
    If (Test-ServiceNowAuthisSet) {
        Remove-ServiceNowAuth
    }

    # Validate Environment
    It "ServiceNow url has Test-Connection connectivity" {
        Test-Connection $Defaults.ServiceNowURL -Quiet | Should -Be $true
    }

    # Auth Functions
    It "Test-ServiceNowAuthIsSet not set" {
        Test-ServiceNowAuthIsSet | Should -Be $false
    }

    It "Set-ServiceNowAuth works" {
        Set-ServiceNowAuth -url $Defaults.ServiceNowURL -Credentials $Credential | Should -Be $true
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
            Credential           = $Credential
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
        $TestTicket = Get-ServiceNowChangeRequest -First 1

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
            Credential    = $Credential
            ServiceNowURL = $Defaults.ServiceNowURL
        }
        Update-ServiceNowNumber @updateServiceNowNumberSplat

        $TestTicket = Get-ServiceNowIncident -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.short_description | Should -Be 'Ticket Updated with Pester (Update-ServiceNowNumber)'
        $TestTicket.description | Should -Be 'Updated by Pester test Update-ServiceNowNumber with SpecifyConnectionFields works'
    }

    It "Update-ServiceNowRequestItem No PassThru works" {
        # Due to a lack of ServiceNow request (REQ) commands this test only works consistently in a developer instance
        $TestTicket = Get-ServiceNowRequestItem -MatchExact @{number='RITM0000001';short_description='Apple iPad 3';state=1} -ErrorAction SilentlyContinue
        $TestTicket.number | Should -Be 'RITM0000001' -Because 'This test only works in a ServiceNow developer instance for RITM0000001'

        $Values = @{
            'description' = 'Updated by Pester test Update-ServiceNowRequestItem No PassThru works'
        }

        $CommandOutput = Update-ServiceNowRequestItem -SysId $TestTicket.sys_id -Values $Values

        $TestTicket = Get-ServiceNowRequestItem -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.description | Should -Be 'Updated by Pester test Update-ServiceNowRequestItem No PassThru works'
        $CommandOutput | Should -BeNullOrEmpty
    }

    It "Update-ServiceNowRequestItem with SpecifyConnectionFields and PassThru works" {
        # Due to a lack of ServiceNow request (REQ) commands this test only works consistently in a developer instance
        $TestTicket = Get-ServiceNowRequestItem -MatchExact @{number='RITM0000001';short_description='Apple iPad 3';state=1} -ErrorAction SilentlyContinue
        $TestTicket.number | Should -Be 'RITM0000001' -Because 'This test only works in a ServiceNow developer instance for RITM0000001'

        $Values = @{
            'description' = 'Updated by Pester test Update-ServiceNowRequestItem with SpecifyConnectionFields works'
        }

        $updateServiceNowRequestItemSplat = @{
            SysID         = $TestTicket.sys_id
            Values        = $Values
            Credential    = $Credential
            ServiceNowURL = $Defaults.ServiceNowURL
            PassThru      = $true
        }
        $CommandOutput = Update-ServiceNowRequestItem @updateServiceNowRequestItemSplat

        $TestTicket = Get-ServiceNowRequestItem -MatchExact @{sys_id=$TestTicket.sys_id}
        $TestTicket.description | Should -Be 'Updated by Pester test Update-ServiceNowRequestItem with SpecifyConnectionFields works'
        $CommandOutput | Should -Not -BeNullOrEmpty
    }

    # Remove Functions
    It "Remove-ServiceNowTable works" {
        $TestTicket = Get-ServiceNowIncident -First 1
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
        Remove-ServiceNowAuth | Should -Be $true
    }
}
