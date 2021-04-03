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