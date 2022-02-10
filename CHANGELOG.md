## 3.1.7
- Add `AsValue` parameter to `Get-ServiceNowRecord` to return the underlying value for a property instead of a pscustomobject.  Get your sys_id directly!
- Add formatting for Unique Certificate (cmdb_ci_certificate) table

## 3.1.6
- Add `AsValue` parameter to `Export-ServiceNowAttachment` to return attachment contents instead of writing to a file

## 3.1.5
- Add table name translation to `Get-ServiceNowAttachment` where sys_class_name does not match table name
- Change .endswith operator from % to ENDSWITH as % was not working

## 3.1.4
- Add email type to custom variables, [#173](https://github.com/Snow-Shell/servicenow-powershell/issues/173)


## 3.1.3
- Fix [#167](https://github.com/Snow-Shell/servicenow-powershell/issues/167), fix ServiceNowTable not being populated on Linux due to file name case

## 3.1.2
- Fix [#160](https://github.com/Snow-Shell/servicenow-powershell/issues/160), adding an attachment to catalog tasks not working for instances created pre-Istanbul.  Thanks @natescherer!

## 3.1.1
- Fix [#158](https://github.com/Snow-Shell/servicenow-powershell/issues/158), failure on successful record deletion
- Move table details retrieval in `New-ServiceNowSession` to be switch operated, `-GetAllTable` and reduce function time
- Fix pipelining in `Remove-ServiceNowRecord`

## 3.1.0
- Add DateTime support to querying, [#68](https://github.com/Snow-Shell/servicenow-powershell/issues/68)
- Add `-between` operator
- Enhanced value validation for all operators in `New-ServiceNowQuery` which is used by `Get-ServiceNowRecord`

## 3.0.2
- Fix [#152](https://github.com/Snow-Shell/servicenow-powershell/issues/152), object conversion to json failing.

## 3.0.1
- Fix [#149](https://github.com/Snow-Shell/servicenow-powershell/issues/149), combination of `-Id` and `-IncludeCustomVariable` failing.  Thanks @natescherer.
- Fix [#150](https://github.com/Snow-Shell/servicenow-powershell/issues/150), Test-ServiceNowURL does not account for URL with a - character.  The validation wasn't providing much value so was removed.
- Getting info on all tables so we can be more intelligent/dynamic about prefixes.  Querying the sys_number table and might require elevated rights.  If rights aren't present, no failure will occur, this is just an added bonus for those with rights :)

## 3.0
- New functionality in `Get-ServiceNowRecord`
  - Add `Id` property to easily retrieve a record by either number or sysid.
  - Add `ParentId` property to easily retrieve records based on the parent number or sysid.  For example, to retrieve catalog tasks associated with a requested item execute `Get-ServiceNowRecord -Table 'Catalog Task' -ParentId RITM01234567`.
  - Add `Description` property to retrieve records based on a table specific description field.  For many tables this field will be short_description, but will be different for others.  For example, when performing this against the 'User' table, the description field is 'Name'.
  - Add ability to provide a known prefixed `Id` without providing `Table`, `Get-ServiceNowRecord -Id inc0010001`.  To see the list of known prefixes, execute `$ServiceNowTable.NumberPrefix` after importing the module.
  - Add alias `gsnr`.  With the above change, a Get can be as simple as `gsnr inc0010001`.
- Add autocomplete for `Table` parameter in `Add-ServiceNowAttachment` and `Get-ServiceNowAttachment`.
- Add `Id` parameter to `Add-ServiceNowAttachment` and `Update-ServiceNowRecord` which accepts either number or sysid.  Just as with `Get-ServiceNowRecord` you can now provide just `Id` if it has a known prefix.
- Add ability to `Get-ServiceNowAttachment` to get attachments either via associated record or directly from the attachments table when you want to search all attachments.
- Add advanced filtering and sorting functionality to `Get-ServiceNowAttachment` which can be really useful when searching across the attachments table.
- Convert access and refresh tokens in $ServiceNowSession from plain text to a credential for added security.
- Pipeline enhancements added in many places.
- Add Change Task and Attachments to formats.
- `Update-ServiceNowNumber` has been deprecated and the functionality has been added to `Update-ServiceNowRecord`.  An alias has also been added so existing scripts do not break.
- Prep for removal of all `Get-` functions except for `Get-ServiceNowRecord` and `Get-ServiceNowAttachment`.  Table specific Get functions have been deprecated.  `Get-ServiceNowRecordInterim` has been created and all table specific Get functions have been aliased so existing scripts do not break.  Please start to migrate to `Get-ServiceNowRecord` as these functions will all be deprecated in the near future.
- As communicated in v2.0, authentication cleanup has occurred.  This involves removal of Credential/Url authentication in each function in favor of `ServiceNowSession`.  You can still authenticate with Credential/Url, but must use `New-ServiceNowSession`.  `Set-ServiceNowAuth`, `Remove-ServiceNowAuth`, and `Test-ServiceNowAuthIsSet` have been deprecated.
- ***Breaking change:*** rename `Get-ServiceNowAttachmentDetail` to `Get-ServiceNowAttachment`.
- ***Breaking change:*** rename `Get-ServiceNowAttachment` to `Export-ServiceNowAttachment`.
- ***Breaking change:*** `Get-ServiceNowTable` and `Get-ServiceNowTableEntry` have been deprecated.  Use `Get-ServiceNowRecord`.

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




