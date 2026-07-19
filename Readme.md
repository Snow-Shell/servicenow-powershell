# ServiceNow

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ServiceNow?style=plastic)](https://www.powershellgallery.com/packages/ServiceNow)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ServiceNow?style=plastic)
[![GitHub license](https://img.shields.io/github/license/Snow-Shell/servicenow-powershell.svg?style=plastic)](LICENSE)
[![CI](https://github.com/Snow-Shell/servicenow-powershell/actions/workflows/ci.yml/badge.svg)](https://github.com/Snow-Shell/servicenow-powershell/actions/workflows/ci.yml)

This PowerShell module provides a series of cmdlets for interacting with the [ServiceNow REST API](https://docs.servicenow.com/bundle/quebec-application-development/page/integrate/inbound-rest/concept/c_RESTAPI.html).

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.

## Breaking Changes

- **5.0**: Azure Automation support has been removed. See [CHANGELOG.md](CHANGELOG.md) for full release-by-release details.

## Requirements

Requires PowerShell 5.1 (Windows PowerShell) or PowerShell 7+ (PowerShell Core).  The module is cross-platform and works on Windows, Linux, and macOS; the [docker image](https://hub.docker.com/repository/docker/gdbarron/servicenow-module) runs on PowerShell 7 on Linux.

Requires authorization in your ServiceNow tenant.  Due to the custom nature of ServiceNow your organization may have REST access restricted.  The following are some tips to ask for if you're having to go to your admin for access:

* Out of the box tables should be accessible by granting the `ITIL` role.
* Custom tables may require adjustments to the ACL.
* The `Web_Service_Admin` role may also be an option.

## Usage

The ServiceNow module should be installed from the [PowerShell Gallery](https://www.powershellgallery.com/packages/ServiceNow) with `Install-Module ServiceNow`.

A [docker image](https://hub.docker.com/repository/docker/gdbarron/servicenow-module) is also available with [Microsoft's PowerShell base image](https://hub.docker.com/_/microsoft-powershell) and the ServiceNow module preinstalled.  The following environment variables should be used:
- SNOW_SERVER: the ServiceNow instance, eg. instance.service-now.com
- SNOW_TOKEN: pre-generated oauth token.  Provide this or SNOW_USER/SNOW_PASS.
- SNOW_USER: username to connect to SNOW_SERVER
- SNOW_PASS: password for SNOW_USER

When using the docker image, creating a new session is not required.

## Function Reference

### Session & Authentication
| Function | Description |
| --- | --- |
| `New-ServiceNowSession` | Create a new session using basic auth, OAuth (user or client-credentials grant), or an existing access token |

### Records
| Function | Description |
| --- | --- |
| `Get-ServiceNowRecord` | Retrieve records from any table |
| `New-ServiceNowRecord` | Create a new record in any table |
| `Update-ServiceNowRecord` | Update record values |
| `Remove-ServiceNowRecord` | Remove a record |
| `New-ServiceNowQuery` | Build a query string for an API call |
| `Export-ServiceNowRecord` | Export table records to a file |

### Incidents & Changes
| Function | Description |
| --- | --- |
| `New-ServiceNowIncident` | Create a new incident |
| `New-ServiceNowChangeRequest` | Create a new change request |
| `New-ServiceNowChangeTask` | Create a new change task |
| `New-ServiceNowConfigurationItem` | Create a new configuration item |

### Attachments
| Function | Description |
| --- | --- |
| `Add-ServiceNowAttachment` | Attach a file to an existing record |
| `Get-ServiceNowAttachment` | Retrieve attachment details |
| `Export-ServiceNowAttachment` | Export (download) an attachment |
| `Remove-ServiceNowAttachment` | Remove an attachment by sys_id |

### Service Catalog
| Function | Description |
| --- | --- |
| `Get-ServiceNowCart` | Get the current user's cart |
| `New-ServiceNowCartItem` | Add an item to the current user's cart |
| `Remove-ServiceNowCartItem` | Remove one or all items from a cart |
| `Submit-ServiceNowCart` | Check out the current user's cart |

### GraphQL
| Function | Description |
| --- | --- |
| `Invoke-ServiceNowGraphQL` | Query or mutate data via a Scripted GraphQL API |

Each function has full comment-based help; use `Get-Help <function> -Full` for parameters and examples not covered below.

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

Oauth authentication with user credential as well as application/client credential.  The application/client credential can be found in the System OAuth->Application Registry section of ServiceNow.  The access token will be refreshed automatically when it expires.
```PowerShell
$params = @{
    Url = 'instance.service-now.com'
    Credential = $userCred
    ClientCredential = $clientCred
}
New-ServiceNowSession @params
```
**Note: ServiceNow's API does not support SSO**

Oauth authentication using only the application/client credential (the `client_credentials` grant).  This does not require user credentials and is useful for machine-to-machine automation or when MFA is enforced for interactive users.
```PowerShell
$params = @{
    Url = 'instance.service-now.com'
    ClientCredential = $clientCred
}
New-ServiceNowSession @params
```

Requests that receive a retryable HTTP error (429, 502, 503, 504, 408, 409) are automatically retried, honoring the `Retry-After` header when present.  Use `RetryCount`, `RetryWaitSeconds`, and `MaxRetryAfterSeconds` on `New-ServiceNowSession` to control this behavior.

All examples below assume a new session has already been created.

### Discovering tables and fields with tab completion

The `-Table` parameter tab-completes across the module's functions, and once a table is specified, `Get-ServiceNowRecord -Property` tab-completes every field available on that table, along with its type and an example value, so you don't need to go look up the schema in ServiceNow first:

```PowerShell
Get-ServiceNowRecord -Table incident -Property <press tab>
```

![Property tab completion showing available fields, types, and example values](https://github.com/user-attachments/assets/2fdc6639-a61c-4259-a0a1-2e305f2a0c9f)

### Getting incidents opened in the last 30 days
```PowerShell
Get-ServiceNowRecord -Table incident -Filter @('opened_at', '-ge', (Get-Date).AddDays(-30))
```

### Retrieving an Incident Containing the Word 'PowerShell'

```PowerShell
Get-ServiceNowRecord -Table incident -Description 'powershell'
```

### Update a Ticket

```PowerShell
Get-ServiceNowRecord inc0010002 | Update-ServiceNowRecord -InputData @{comments='Updated via PowerShell'}
```

### Creating an Incident with custom table entries

```PowerShell
$params = @{
    Caller = "UserName"
    ShortDescription = "New PS Incident"
    Description = "This incident was created from Powershell"
    InputData = @{
        u_service = "MyService"
        u_incident_type = "Request"
        urgency = 1
    }
}
New-ServiceNowIncident @params
```

### Creating a Change Task

```PowerShell
New-ServiceNowChangeTask -ChangeRequest CHG0010001 -ShortDescription 'New PS change task' -Description 'This change task was created from Powershell' -AssignmentGroup ServiceDesk
```

### Ordering from the Service Catalog

Add an item to the current user's cart, optionally checking out in the same step. `CatalogItem` supports tab/menu completion of available catalog items.
```PowerShell
New-ServiceNowCartItem -CatalogItem 'Standard Laptop' -Quantity 1
```

Review the current cart, then submit it for checkout (based on the catalog's one-step or two-step checkout configuration).
```PowerShell
Get-ServiceNowCart
Submit-ServiceNowCart -PassThru
```

Remove a specific item, or empty the entire cart.
```PowerShell
Remove-ServiceNowCartItem -CartItemId 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6'
Remove-ServiceNowCartItem -All
```

### GraphQL

`Invoke-ServiceNowGraphQL` talks to a [Scripted GraphQL API](https://docs.servicenow.com/bundle/sandiego-application-development/page/integrate/graphql/concept/scripted-graph-ql.html), which your ServiceNow instance's admins must design and build first (there's no generic, built-in schema that works out of the box). Create the session with `-GraphQL`, then query using the `Application`/`Schema` your admins have configured:
```PowerShell
New-ServiceNowSession -Url instance.service-now.com -Credential $userCred -GraphQL
Invoke-ServiceNowGraphQL -Application myapp -Schema incident -Query 'findById (id: "INC0010001") {sys_id {value} description {value}}'
```

## Scope & Contributing

Contributions are gratefully received, so please feel free to submit a pull request with additional features or amendments.

Before submitting a PR:
- Run the unit test suite with `Invoke-Pester ./Tests` and ensure everything passes.
- If you have access to a ServiceNow instance, run `Tests/Invoke-ServiceNowLiveSmokeTest.ps1` against it to validate your changes end to end.
- Lint your changes with `Invoke-ScriptAnalyzer -Path . -Recurse`.

## Authors

- Current: [Greg Brownstein](https://github.com/gdbarron)

- Previous
  - [Sam Martin](https://github.com/Sam-Martin)
  - [Rick Arroues](https://github.com/Rick-2CA)
