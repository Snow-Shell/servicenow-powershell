# ServiceNow

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ServiceNow?style=plastic)](https://www.powershellgallery.com/packages/ServiceNow)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ServiceNow?style=plastic)
[![GitHub license](https://img.shields.io/github/license/Snow-Shell/servicenow-powershell.svg?style=plastic)](LICENSE)

This PowerShell module provides a series of cmdlets for interacting with the [ServiceNow REST API](https://docs.servicenow.com/bundle/quebec-application-development/page/integrate/inbound-rest/concept/c_RESTAPI.html).

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.

## Requirements

Requires PowerShell 5.1 or above.

Requires authorization in your ServiceNow tenant.  Due to the custom nature of ServiceNow your organization may have REST access restricted.  The following are some tips to ask for if you're having to go to your admin for access:

* Out of the box tables should be accessible by granting the `ITIL` role.
* Custom tables may require adjustments to the ACL.
* The `Web_Service_Admin` role may also be an option.

## Usage

The ServiceNow module should be installed from the [PowerShell Gallery](https://www.powershellgallery.com/packages/ServiceNow) with `install-module ServiceNow`.

### Creating a new session

Creating a new session will create a script scoped variable `$ServiceNowSession` which will be used by default in other functions.

Basic authentication with just a credential...
```PowerShell
$params = @{
    Url = 'instance.service-now.com'
    Credential = $userCred
}
New-ServiceNowSession @params
```

Oauth authentication with user credential as well as application/client credential.  The application/client credential can be found in the System OAuth->Application Registry section of ServiceNow.
```PowerShell
$params = @{
    Url = 'instance.service-now.com'
    Credential = $userCred
    ClientCredential = $clientCred
}
New-ServiceNowSession @params
```
**Note: ServiceNow's API does not support SSO**

All examples below assume a new session has already been created.

### Getting incidents opened in the last 30 days
```PowerShell
$filter = @('opened_at', '-ge', (Get-Date).AddDays(-30))
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

## Scope & Contributing

Contributions are gratefully received, so please feel free to submit a pull request with additional features or amendments.

## Authors

- [Sam Martin](https://github.com/Sam-Martin)
- [Rick Arroues](https://github.com/Rick-2CA)
- [Greg Brownstein](https://github.com/gdbarron)
