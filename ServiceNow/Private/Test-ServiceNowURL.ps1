Function Test-ServiceNowURL {
    <#
    .SYNOPSIS
    For use in testing ServiceNow Urls.

    .DESCRIPTION
    For use in testing ServiceNow Urls.  The test is a simple regex match in an attempt to validate that users use a 'tenant.domain.com' pattern.

    .EXAMPLE
    Test-ServiceNowURL -Url tenant.domain.com

    This example can have text

    .OUTPUTS
    System.Boolean

    #>

    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param (
        # Pipeline variable
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )

	begin {}
	process	{
        Write-Verbose "Testing url:  $Url"
		if ($Url -match '^\w+\..*\.\w+') {
            $true
        }
        else {
            Throw "The expected URL format is tenant.domain.com"
        }
    }
	end {}
}
