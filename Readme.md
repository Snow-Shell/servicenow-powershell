# PSServiceNow  
[![GitHub release](https://img.shields.io/github/release/Sam-Martin/servicenow-powershell.svg)](https://github.com/Sam-Martin/servicenow-powershell/releases/latest) [![GitHub license](https://img.shields.io/github/license/Sam-Martin/servicenow-powershell.svg)](LICENSE) ![Test Coverage](https://img.shields.io/badge/coverage-87%25-yellowgreen.svg)  
This PowerShell module provides a series of cmdlets for interacting with the [ServiceNow REST API](http://wiki.servicenow.com/index.php?title=REST_API), performed by wrapping `Invoke-RestMethod` for the API calls.  
**IMPORTANT:** Neither this module, nor its creator are in any way affiliated with ServiceNow.

## Requirements
Requires PowerShell 3.0 or above as this is when `Invoke-RestMethod` was introduced.

## Usage
Download the [latest release](https://github.com/Sam-Martin/servicenow-powershell/releases/latest) and  extract the .psm1 and .psd1 files to your PowerShell profile directory (i.e. the `Modules` directory under wherever `$profile` points to in your PS console) and run:  
`Import-Module PSServiceNow`  
Once you've done this, all the cmdlets will be at your disposal, you can see a full list using `Get-Command -Module PSServiceNow`.

### Example - Retrieving an Incident Containing the Word 'PowerShell'
```
Import-Module PSServiceNow
Set-ServiceNowAuth 
Get-ServiceNowIncident -MatchContains @{short_description='PowerShell'} 
```

### Example - Retrieving an Incident Containing the Word 'PowerShell' While Passing Authentication
```
Import-Module PSServiceNow
Get-ServiceNowIncident -MatchContains @{short_description='PowerShell'} -ServiceNowCredential $PSCredential -ServiceNowURL $ServiceNowURL
```

### Azure Connection Object (Automation Integration Module Support)
The module can use the `Connection` parameter in conjunction with the included `PSServiceNow-Automation.json` file for use as an Azure automation integration module.  Details of the process is available at [Authoring Integration Modules for Azure Automation](https://azure.microsoft.com/en-us/blog/authoring-integration-modules-for-azure-automation).  

The `Connection` parameter accepts a hashtable object that requires a username, password, and ServiceNowURL.

## Cmdlets  
* Get-ServiceNowChangeRequest
* Get-ServiceNowConfigurationItem
* Get-ServiceNowIncident
* Get-ServiceNowTable
* Get-ServiceNowUser
* Get-ServiceNowUserGroup
* New-ServiceNowIncident
* New-ServiceNowQuery
* New-ServiceNowTableEntry
* Remove-ServiceNowAuth
* Remove-ServiceNowTableEntry
* Set-ServiceNowAuth
* Test-ServiceNowAuthIsSet

## Tests
This module comes with [Pester](https://github.com/pester/Pester/) tests for unit testing.

## Scope & Contributing
This module has been created as an abstraction layer to suit my immediate requirements. Contributions are gratefully received however, so please feel free to submit a pull request with additional features or amendments.

## Author
Author:: Sam Martin (<samjackmartin@gmail.com>)

