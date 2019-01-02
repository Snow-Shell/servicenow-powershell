function Get-ServiceNowTable {
<#
    .SYNOPSIS
        Retrieves records for the specified table
    .DESCRIPTION
        The Get-ServiceNowTable function retrieves records for the specified table
    .INPUTS
        None
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .LINK
        Service-Now Kingston REST Table API: https://docs.servicenow.com/bundle/kingston-application-development/page/integrate/inbound-rest/concept/c_TableAPI.html
        Service-Now Table API FAQ: https://hi.service-now.com/kb_view.do?sysparm_article=KB0534905
#>

    [CmdletBinding(SupportsPaging = $true)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName)]
    Param (
        # Name of the table we're querying (e.g. incidents)
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [Parameter(Mandatory = $false)]
        [string]$Query,

        # Whether or not to show human readable display values instead of machine values
        [Parameter(Mandatory = $false)]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    # Get credential and ServiceNow REST URL
    if ($null -ne $Connection) {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $ServiceNowCredential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
    }
    elseif ($null -ne $ServiceNowCredential -and $null -ne $ServiceNowURL) {
        Test-ServiceNowURL -Url $ServiceNowURL
        $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1'
    }
    elseif ((Test-ServiceNowAuthIsSet)) {
        $ServiceNowCredential = $Global:ServiceNowCredentials
        $ServiceNowURL = $global:ServiceNowRESTURL
    }
    else {
        throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
    }

    # Populate the query
    $Body = @{
        'sysparm_display_value' = $DisplayValues
    }

    # Number of results to return.
    # If the user doesn't provide the -First parameter, it defaults to [uint64]::MaxValue
    if ($PSCmdlet.PagingParameters.First -ne [uint64]::MaxValue) {
        $Body['sysparm_limit'] = $PSCmdlet.PagingParameters.First
    }
    else {
        # If no paging information was provided, default to the legacy behavior,
        # which was to return 10 records
        $Body['sysparm_limit'] = 10
    }

    if ($PSCmdlet.PagingParameters.Skip) {
        $Body['sysparm_offset'] = $PSCmdlet.PagingParameters.Skip
    }

    if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
        # To my knowledge, ServiceNow doesn't expose any data regarding how
        # many records match the provided query.
        # If that data is available, we'd update it here.

        # Accuracy is a double between 0.0 and 1.0 representing an estimated
        # percentage accuracy. 0.0 means we have no idea and 1.0 means the
        # number is exact.
        [double] $accuracy = 0.0
        $PSCmdlet.PagingParameters.NewTotalCount($PSCmdlet.PagingParameters.First, $accuracy)
    }

    if ($Query) {
        $Body.sysparm_query = $Query
    }

    # Perform table query and capture results
    $Uri = $ServiceNowURL + "/table/$Table"
    $Result = (Invoke-RestMethod -Uri $Uri -Credential $ServiceNowCredential -Body $Body -ContentType "application/json").Result

    # Convert specific fields to DateTime format
    $ConvertToDateField = @('closed_at', 'expected_start', 'follow_up', 'opened_at', 'sys_created_on', 'sys_updated_on', 'work_end', 'work_start')
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
                        $null = 'Silencing a PSSA alert with this line'
                    }
                }
            }
        }
    }

    # Return the results
    $Result
}
