Function Update-ServiceNowDateTimeField {
    <#
    .SYNOPSIS
    Attempt to update statically set ServiceNow result fields from string to DateTime fields

    .DESCRIPTION
    Attempt to update statically set ServiceNow result fields from string to DateTime fields

    .EXAMPLE
    Update-ServiceNowDateTimeField -Result $Result

    .OUTPUTS
    System.Management.Automation.PSCustomObject

    .NOTES

    #>

    [OutputType([PSCustomObject[]])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Pipeline variable
        [Parameter(
            Mandatory         = $true,
            ValueFromPipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$Result
    )

	begin {}
	process	{
		# Convert specific fields to DateTime format
        $ConvertToDateField = @('closed_at', 'expected_start', 'follow_up', 'opened_at', 'sys_created_on', 'sys_updated_on', 'work_end', 'work_start')

        If ($PSCmdlet.ShouldProcess($SearchBase,$MyInvocation.MyCommand)) {
        ForEach ($SNResult in $Result) {
                ForEach ($Property in $ConvertToDateField) {
                    If (-not [string]::IsNullOrEmpty($SNResult.$Property)) {
                        Try {
                            # Extract the default Date/Time formatting from the local computer's "Culture" settings, and then create the format to use when parsing the date/time from Service-Now
                            $CultureDateTimeFormat = (Get-Culture).DateTimeFormat
                            $DateFormat = $CultureDateTimeFormat.ShortDatePattern
                            $TimeFormat = $CultureDateTimeFormat.LongTimePattern
                            $DateTimeFormat = "$DateFormat $TimeFormat"
                            $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                        }
                        Catch {
                            Try {
                                # Universal Format
                                $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss'
                                $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                            }
                            Catch {
                                # If the local culture and universal formats both fail keep the property as a string (Do nothing)
                                $null = 'Code to make PSSA happy when we just want to suppress errors'
                            }
                        }
                    }
                }
            }
        }

        $Result
    }
	end {}
}
