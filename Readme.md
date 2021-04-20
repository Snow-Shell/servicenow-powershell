# ServiceNow

[![GitHub release](https://img.shields.io/github/release/Snow-Shell/servicenow-powershell.svg)](https://github.com/Snow-Shell/servicenow-powershell/releases/latest) [![GitHub license](https://img.shields.io/github/license/Snow-Shell/servicenow-powershell.svg)](LICENSE)

This PowerShell module provides a series of cmdlets for interacting with the [ServiceNow REST API](http://wiki.servicenow.com/index.php?title=REST_API), performed by wrapping `Invoke-RestMethod` for the API calls.

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.

## Version 2

Building on the great work the community has done thus far, a lot of new updates with this release.
- Although still in the module for backward compatibility, `Set-ServiceNowAuth` is being replaced with `New-ServiceNowSession`.  With this comes OAuth support, removal of global variables, and much more folks have asked for.  The ability to provide credentials directly to functions has been retained for this release, but will be deprecated in a future release in favor of using `New-ServiceNowSession`.
- Support for different api versions.  `Set-ServiceNowAuth` will continue to use v1 of the api, but `New-ServiceNowSession` defaults to the latest.  Check out the `-ApiVersion` parameter of `New-ServiceNowSession`.
- `Remove-ServiceNowAuth` has been retained for this release, but as global variables have been removed, there is no longer a need for it; it will always return `$true`.  It will be removed in a future release.
- `-PassThru` added to remaining `Update-` and `New-` functions.  Depending on your code, this may be a ***breaking change*** if you expected the result to be returned.
- Pipeline support added to many functions
- Standardizing on coding between all functions

## Requirements

Requires PowerShell 3.0 or above as this is when `Invoke-RestMethod` was introduced.

Requires authorization in your ServiceNow tenant.  Due to the custom nature of ServiceNow your organization may have REST access restricted.  The following are some tips to ask for if you're having to go to your admin for access:

* Out of the box tables should be accessible by granting the `ITIL` role.
* Custom tables may require adjustments to the ACL.
* The `Web_Service_Admin` role may also be an option.

## Usage

The ServiceNow module should be installed from the PowerShell Gallery with `install-module ServiceNow`.

### Creating a new session

```PowerShell
New-ServiceNowSession -url InstanceName.service-now.com -Credentials (Get-Credential)
```

This example is using basic authentication, but OAuth is available as well; see the built-in help for `New-ServiceNowSession`.  All examples below assume a new session has already been created.

### Example - Retrieving an Incident Containing the Word 'PowerShell'

```PowerShell
Get-ServiceNowIncident -MatchContains @{short_description='PowerShell'}
```

### Example - Update a Ticket

```PowerShell
Get-ServiceNowIncident -Limit 1 -MatchContains @{short_description='PowerShell'} | Update-ServiceNowIncident -Values @{comments='Updated via PowerShell'}
```

### Example - Creating a Incident with custom table entries

```PowerShell
$IncidentParams = @{Caller = "UserName"
            ShortDescription = "New PS Incident"
            Description = "This incident was created from Powershell"
            CustomFields = @{u_service = "MyService"
                            u_incident_type = "Request"}
            }
New-ServiceNowIncident @Params
```

### Azure Connection Object (Automation Integration Module Support)

The module can use the `Connection` parameter in conjunction with the included `ServiceNow-Automation.json` file for use as an Azure automation integration module.  Details of the process is available at [Authoring Integration Modules for Azure Automation](https://azure.microsoft.com/en-us/blog/authoring-integration-modules-for-azure-automation).

The `Connection` parameter accepts a hashtable object that requires a username, password, and ServiceNowURL.

## Tests

This module comes with limited [Pester](https://github.com/pester/Pester/) tests for unit testing.

## Scope & Contributing

Contributions are gratefully received, so please feel free to submit a pull request with additional features or amendments.

## Authors

- [Sam Martin](https://github.com/Sam-Martin)
- [Rick Arroues](https://github.com/Rick-2CA)
- [Greg Brownstein](https://github.com/gdbarron)
