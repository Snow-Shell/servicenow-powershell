<#
.SYNOPSIS
    Tests if a string is a valid ServiceNow sys_id format

.DESCRIPTION
    Validates that a string matches the ServiceNow sys_id format of a 32-character alphanumeric string

.PARAMETER Value
    The string value to test

.EXAMPLE
    Test-ServiceNowSysId -Value '9d385017c611228701d22104cc95c371'
    Returns $true

.EXAMPLE
    Test-ServiceNowSysId -Value 'INC0010001'
    Returns $false

.OUTPUTS
    System.Boolean
#>
function Test-ServiceNowSysId {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string] $Value
    )

    process {
        if ([string]::IsNullOrEmpty($Value)) {
            return $false
        }

        return $Value -match '^[a-zA-Z0-9]{32}$'
    }
}
