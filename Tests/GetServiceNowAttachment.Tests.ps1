[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [ValidateNotNullorEmpty()]
    [PSCredential]$Credential
)

If (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
$Script:ThisCommand = $MyInvocation.MyCommand

$ProjectRoot = Resolve-Path "$PSScriptRoot\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psd1")
$ModuleName = Split-Path $ModuleRoot -Leaf
$ModulePsd = (Resolve-Path "$ProjectRoot\*\$ModuleName.psd1").Path
$ModulePsm = (Resolve-Path "$ProjectRoot\*\$ModuleName.psm1").Path
$DefaultsFile = Join-Path $ProjectRoot "Tests\$($ModuleName).Pester.Defaults.json"

$ModuleLoaded = Get-Module $ModuleName
if ($null -eq $ModuleLoaded) {
    Import-Module $ModulePSD -Force
} elseIf ($null -ne $ModuleLoaded -and $ModuleLoaded -ne $ModulePSM) {
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    Import-Module $ModulePSD -Force
}

# Load defaults from file
if (Test-Path $DefaultsFile) {
    $Script:Defaults = Get-Content $DefaultsFile -Raw | ConvertFrom-Json

    if ('testingurl.service-now.com' -eq $Defaults.ServiceNowUrl) {
        throw 'Please populate the *.Pester.Defaults.json file with your values'
    }
} else {
    # Write example file
    @{
        ServiceNowURL = 'testingurl.service-now.com'
        TestCategory  = 'Internal'
        TestUserGroup = '8a4dde73c6112278017a6a4baf547aa7'
        TestUser      = '6816f79cc0a8016401c5a33be04be441'
    } | ConvertTo-Json | Set-Content $DefaultsFile
    throw "$DefaultsFile does not exist. Created example file. Please populate with your values"
}

Describe "$ThisCommand" -Tag Attachment {
    $null = Set-ServiceNowAuth -Url $Defaults.ServiceNowUrl -Credentials $Credential

    It 'Create incident with New-ServiceNowIncident' {
        $ShortDescription = "Testing Ticket Creation with Pester:  $ThisCommand"
        $NewServiceNowIncidentSplat = @{
            Caller               = $Defaults.TestUser
            ShortDescription     = $ShortDescription
            Description          = 'Long description'
            Comment              = 'Test Comment'
            ServiceNowCredential = $Credential
            ServiceNowURL        = $Defaults.ServiceNowURL
        }
        $Script:TestTicket = New-ServiceNowIncident @NewServiceNowIncidentSplat

        $TestTicket.short_description | Should -Be $ShortDescription
    }

    It 'Attachment test file exist' {
        $FileValue = "{0}`t{1}" -f (Get-Date), $ThisCommand
        $FileName = '{0}.txt' -f ('GetServiceNowAttachment')
        $NewItemSplat = @{
            Name     = $FileName
            ItemType = 'File'
            Value    = $FileValue
        }
        $Script:File = New-Item @NewItemSplat

        $File.FullName | Should -Exist
    }

    It "File is attached to $($TestTicket.Number)" {
        $AddServiceNowAttachmentSplat = @{
            Number        = $TestTicket.Number
            Table         = 'incident'
            File          = $File.FullName
            Credential    = $Credential
            ServiceNowURL = $Defaults.ServiceNowURL
            PassThru      = $true
        }
        $Script:Attachment = Add-ServiceNowAttachment @AddServiceNowAttachmentSplat

        $Attachment.file_name | Should -Be $File.Name
    }

    It 'Attachment test file removed' {
        Remove-Item $File.FullName -Force

        $File.FullName | Should -Not -Exist
    }

    $Script:FileName = 'DownloadServiceNowAttachment.txt'
    $Script:ExpectedOutput = '{0}_{1}{2}' -f [io.path]::GetFileNameWithoutExtension($FileName), $Attachment.sys_id, [io.path]::GetExtension($FileName)

    It 'Attachment download successful (Global Credentials, Append Name)' {
        $GetServiceNowAttachmentSplat = @{
            FileName            = $FileName
            SysId               = $Attachment.sys_id
            AppendNameWithSysID = $true
        }
        { Get-ServiceNowAttachment @GetServiceNowAttachmentSplat } | Should -Not -Throw
        $ExpectedOutput | Should -Exist
    }

    It 'Attachment download successful (Specify Credentials, Allow Overwrite)' {
        $GetServiceNowAttachmentSplat = @{
            FileName            = $FileName
            SysId               = $Attachment.sys_id
            AppendNameWithSysID = $true
            AllowOverwrite      = $true
            Credential          = $Credential
            ServiceNowURL       = $Defaults.ServiceNowURL
        }

        { Get-ServiceNowAttachment @GetServiceNowAttachmentSplat } | Should -Not -Throw
    }

    It 'Attachment test file removed' {
        try {
            Remove-Item $ExpectedOutput -Force -ErrorAction Stop
        } catch {
            Write-Error $PSItem
        }

        $ExpectedOutput | Should -Not -Exist
    }

    $null = Remove-ServiceNowAuth
}
