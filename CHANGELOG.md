## 2.4.2
- Fix [#141](https://github.com/Snow-Shell/servicenow-powershell/issues/141), add `UseBasicParsing` to all API calls to keep AA from failing when IE hasn't been initialized

## 2.4.1
- Add `-IncludeCustomVariable` to `Get-ServiceNowRecord` to retrieve custom variables, eg. ritm form values, in addition to the standard fields.  [#138](https://github.com/Snow-Shell/servicenow-powershell/discussions/138)

## 2.4
- Add `New-ServiceNowConfigurationItem`, [#109](https://github.com/Snow-Shell/servicenow-powershell/issues/109)
- Add grouping operators -and and -group as well as comparison operators -startwith and -endswith to `Get-ServiceNowRecord -Filter` to keep with the -operator standard
- Add tab ahead/completion for the `-Table` property in `Get-ServiceNowRecord`.  This will allow you to cycle through the different tables the module is aware of.  The values are the 'common' names, not table names so it's easier to understand for beginners.  You can also provide any other table name ad hoc.
- Add Change Task to formatter and tab ahead
- Fix null index error when executing `New-ServiceNowQuery` without providing a value for `-Sort`
- Fix [#136](https://github.com/Snow-Shell/servicenow-powershell/issues/136) to account for PS v7.x Invoke-WebRequest response headers all being arrays

## 2.3.2
- Added ability to pipe to `Add-ServiceNowAttachment` and `Get-ServiceNowAttachmentDetail`.  For example, `New-ServiceNowIncident @params -PassThru | Add-ServiceNowAttachment -File MyFile.txt`.  This will create an incident and add an attachment in one step.

## 2.3.1
- Fix query operator -notin and -notlike which had a missing space
- Move verbose logging message in `Invoke-ServiceNowRestMethod` for number of records so it always shows.  This is helpful when you change a filter and can see how many records would be returned without actually returning them.

## v2.3
- Add paging support to all `Get-` functions.  Use `-First`, `-Skip`, and `-IncludeTotalCount` parameters.  In support of this, api calls have been changed from Invoke-RestMethod to Invoke-WebRequest.
- Additional pipline support added for Table and SysId parameters to pipe `Get-` functions to `Update-` and `Remove-`.
- ***Breaking change:*** deprecate `-Limit` parameter.  The warning regarding deprecation went out over 2 years ago and now that paging has been implemented, it's a good time for this cleanup.  Use `-First` instead.
- 'TableEntry' renamed to 'Record' for `New-`, `Update-`, and `Remove-` functions.  Aliases added.

## v2.2
- Add advanced filtering and sorting.  Initially implemented with `New-ServiceNowQuery` and `Get-ServiceNowRecord`.  Filter with many different comparison operators as well as 'and', 'or', and 'group'ing.  Sort ascending or descending against multiple fields.  Comparison operators are the same as PowerShell for ease of use.  Please use the GitHub Discussions section to provide feedback, thoughts, etc.
- Add `Get-ServiceNowRecord`.  This function implements the new advanced filtering and sorting.  As long as you know your table name, this can replace all other Get functions.
- Enumerate implemented tables and advanced filtering operators in a json config to easily manage going forward; make available via script scoped variables.
Be able to reference types from this config per table, removing the need to have separate Get functions for every table.
- Add type for catalog task
- Fix error when getting an empty result from the api and performing a type lookup
- Rename `RequestItem` to `RequestedItem` which is the actual name.  Function aliases created.

## v2.1
- Add proxy support to `New-ServiceNowSession`, [#97](https://github.com/Snow-Shell/servicenow-powershell/issues/97).

## v2.0
- Although still in the module for backward compatibility, `Set-ServiceNowAuth` is being replaced with `New-ServiceNowSession`.  With this comes OAuth support, removal of global variables, and much more folks have asked for.  The ability to provide credentials directly to functions has been retained for this release, but will be deprecated in a future release in favor of using `New-ServiceNowSession`.
- Support for different api versions.  `Set-ServiceNowAuth` will continue to use v1 of the api, but `New-ServiceNowSession` defaults to the latest.  Check out the `-ApiVersion` parameter of `New-ServiceNowSession`.
- `Remove-ServiceNowAuth` has been retained for this release, but as global variables have been removed, there is no longer a need for it; it will always return `$true`.  It will be removed in a future release.
- `-PassThru` added to remaining `Update-` and `New-` functions.  Depending on your code, this may be a ***breaking change*** if you expected the result to be returned.
- Pipeline support added to many functions
- Standardizing on coding between all functions

## v1.8.1
- Update links to reference the new GitHub organization this project will be moved to.  Module functionality unchanged.

## v1.8.0
- Add Update-ServiceNowRequestItem
- Fix switch statements by adding breaks to each condition

## v1.7.0
- Add New-ServiceNowChangeRequest

## v1.6.0
- Add Update-ServiceNowDateTimeField
- Add Add-ServiceNowAttachment
- Add Get-ServiceNowAttachment
- Add Get-ServiceNowAttachmentDetail
- Add Remove-ServiceNowAttachment
