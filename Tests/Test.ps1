<#
$DomainSuffix = 'iheartmedia.com'

$UserName = '1113192'
$newFolderName = "$UserName".ToUpper()
$newFolderFull = "\\CIHM01SATRA\c$\users\1113193\desktop\$newFolderName"

[system.io.directory]::CreateDirectory($newFolderFull)

$AddAccessRule = New-Object 'security.accesscontrol.filesystemaccessrule'("$UserName@$($DomainSuffix)",@("FullControl"),"ContainerInherit,Objectinherit","None","Allow")
$acl = Get-Acl $newFolderFull
$acl.AddAccessRule($AddAccessRule)
set-acl -aclobject $acl $newFolderFull
#>

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
$moduleName = Split-Path $moduleRoot -Leaf
$DefaultsFile = Join-Path $projectRoot "Tests\$($ModuleName).Pester.Defaults.json"

Write-Host "ProjectRoot:  " $projectroot
Write-Host "moduleroot:  " $moduleroot
Write-Host "modulename:  " $modulename
Write-Host "DefaultsFile:  " $DefaultsFile
Test-Path $DefaultsFile