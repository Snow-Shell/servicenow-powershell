# ServiceNow

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ServiceNow?style=plastic)](https://www.powershellgallery.com/packages/ServiceNow)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ServiceNow?style=plastic)
[![GitHub license](https://img.shields.io/github/license/Snow-Shell/servicenow-powershell.svg?style=plastic)](LICENSE)

This PowerShell module provides a series of cmdlets for interacting with the [ServiceNow REST API](https://docs.servicenow.com/bundle/quebec-application-development/page/integrate/inbound-rest/concept/c_RESTAPI.html).

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.

## Version 2

Building on the great work the community has done thus far, a lot of new updates with this release.
- Although still in the module for backward compatibility, `Set-ServiceNowAuth` is being replaced with `New-ServiceNowSession`.  With this comes OAuth support, removal of global variables, and much more folks have asked for.  The ability to provide credentials directly to functions has been retained for this release, but will be deprecated in a future release in favor of using `New-ServiceNowSession`.
- Support for different api versions.  `Set-ServiceNowAuth` will continue to use v1 of the api, but `New-ServiceNowSession` defaults to the latest.  Check out the `-ApiVersion` parameter of `New-ServiceNowSession`.
- `Remove-ServiceNowAuth` has been retained for this release, but as global variables have been removed, there is no longer a need for it; it will always return `$true`.  It will be removed in a future release.
- `-PassThru` added to remaining `Update-` and `New-` functions.  Depending on your code, this may be a ***breaking change*** if you expected the result to be returned.
- Pipeline support added to many functions
- Standardizing on coding between all functions

***It is recommended to use `Get-ServiceNowRecord` instead of the other 'Get' functions.***

## Requirements

Requires PowerShell 5.1 or above.

Requires authorization in your ServiceNow tenant.  Due to the custom nature of ServiceNow your organization may have REST access restricted.  The following are some tips to ask for if you're having to go to your admin for access:

* Out of the box tables should be accessible by granting the `ITIL` role.
* Custom tables may require adjustments to the ACL.
* The `Web_Service_Admin` role may also be an option.

## Usage

The ServiceNow module should be installed from the PowerShell Gallery with `install-module ServiceNow`.

### Creating a new session

Creating a new session will create a script scoped variable `$ServiceNowSession` which will be used by default in other functions.

Basic authentication with just a credential...
```PowerShell
$params @{
    Url = 'instance.service-now.com'
    Credential = $userCred
}
New-ServiceNowSession @params
```

Oauth authentication with user credential as well as application/client credential.  The application/client credential can be found in the System OAuth->Application Registry section of ServiceNow.
```PowerShell
$params @{
    Url = 'instance.service-now.com'
    Credential = $userCred
    ClientCredential = $clientCred
}
New-ServiceNowSession @params
```

All examples below assume a new session has already been created.

### Getting incidents opened in the last 30 days
```PowerShell
$filter = @('opened_at', '-ge', 'javascript:gs.daysAgoEnd(30)')
Get-ServiceNowRecord -Table incident -Filter $filter
```

### Retrieving an Incident Containing the Word 'PowerShell'

```PowerShell
Get-ServiceNowRecord -Table incident -Filter @('short_description','-like','PowerShell')
```

### Update a Ticket

```PowerShell
Get-ServiceNowRecord -First 1 -Filter @('short_description','-eq','PowerShell') | Update-ServiceNowIncident -Values @{comments='Updated via PowerShell'}
```

### Creating an Incident with custom table entries

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
