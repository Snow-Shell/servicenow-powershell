## v2.2
- Add advanced filtering and sorting.  Initially implemented with `New-ServiceNowQuery` and `Get-ServiceNowRecord`.  Filter with many different comparison operators as well as 'and', 'or', and 'group'ing.  Sort ascending or descending against multiple fields.  Comparison operators are the same as PowerShell for ease of use.  Please use the GitHub Discussions section to provide feedback, thoughts, etc.
- Add `Get-ServiceNowRecord`.  This function implements the new advanced filtering and sorting.  As long as you know your table name, this can replace all other Get functions.
- Enumerate implemented tables and advanced filtering operators in a json config to easily manage going forward; make available via script scoped variables.
Be able to reference types from this config per table, removing the need to have separate Get functions for every table.
- Add type for catalog task
- Fix error when getting an empty result from the api and performing a type lookup
- Rename `Get-ServiceNowRequestItem` to `Get-ServiceNowRequestedItem` which is the actual name.  Function alias created.

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