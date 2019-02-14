[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [PSCredential]$Credential
)

If (-not $PSScriptRoot) {$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent}
$Script:ThisCommand = $MyInvocation.MyCommand

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

Describe "$ThisCommand" -Tag Attachment {
    # It "Test It" {}

    It "Create incident with New-ServiceNowIncident" {
        $ShortDescription = "Testing Ticket Creation with Pester:  $ThisCommand"
        $newServiceNowIncidentSplat = @{
            Caller               = $Defaults.TestUser
            ShortDescription     = $ShortDescription
            Description          = 'Long description'
            Comment              = 'Test Comment'
            ServiceNowCredential = $Credential
            ServiceNowURL        = $Defaults.ServiceNowURL
        }
        $Script:TestTicket = New-ServiceNowIncident @newServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription
    }

    It 'Attachment test file exist' {
        $FileValue = "{0}`t{1}" -f (Get-Date),$($MyInvocation.MyCommand)
        $FileName = "{0}.txt" -f 'GetServiceNowAttachment'
        $newItemSplat = @{
            Name     = $FileName
            ItemType = 'File'
            Value    = $FileValue
        }
        $Script:File = New-Item @newItemSplat

        $File.FullName | Should -Exist
    }

    It "File is attached to $($TestTicket.Number)" {
        $addServiceNowAttachmentSplat = @{
            Number        = $TestTicket.Number
            Table         = 'incident'
            File          = $File.FullName
            Credential    = $Credential
            ServiceNowURL = $Defaults.ServiceNowURL
            PassThru      = $true
        }
        $Script:Attachment = Add-ServiceNowAttachment @addServiceNowAttachmentSplat

        $Attachment.file_name | Should -Be $File.Name
    }

    It 'Attachment test file removed' {
        Remove-Item $File.FullName -Force

        $File.FullName | Should -Not -Exist
    }

    It 'Attachment downloaded successfully' {
        $FileName = 'DownloadServiceNowAttachment.txt'
        $Script:ExpectedOutput = "{0}_{1}{2}" -f [io.path]::GetFileNameWithoutExtension($FileName),
        $Attachment.sys_id,[io.path]::GetExtension($FileName)

        $getServiceNowAttachmentSplat = @{
            FileName            = $FileName
            SysId               = $Attachment.sys_id
            AppendNameWithSysID = $true
            Credential          = $Credential
            ServiceNowURL       = $Defaults.ServiceNowURL
        }
        Get-ServiceNowAttachment @getServiceNowAttachmentSplat

        $ExpectedOutput | Should -Exist
    }

    It 'Attachment test file removed' {
        Remove-Item $ExpectedOutput -Force

        $ExpectedOutput | Should -Not -Exist
    }
}

<#

$Hash = @{
    Path = 'C:\Users\1113193\OneDrive\GitHub\servicenow-powershell\Tests\GetServiceNowAttachment.Tests.ps1'
    Parameters = @{
        Credential = $Credential
    }
}

$invokePesterSplat = @{
    Script = $Hash
    Tag = 'Attachment'
}
Invoke-Pester @invokePesterSplat

#>
