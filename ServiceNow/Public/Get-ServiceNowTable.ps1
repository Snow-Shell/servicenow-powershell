function Get-ServiceNowTable {
    [OutputType([Array])]
    Param (
        # Name of the table we're querying (e.g. incidents)
        [parameter(Mandatory)]
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [string]$Query,

        # Maximum number of records to return
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [int]$Limit = 10,

        # Whether or not to show human readable display values instead of machine values
        [parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [parameter(ParameterSetName = 'UseConnectionObject')]
        [parameter(ParameterSetName = 'SetGlobalAuth')]
        [ValidateSet("true", "false", "all")]
        [string]$DisplayValues = 'false',

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName = 'SpecifyConnectionFields')]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $ServiceNowCredential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceNowURL,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection
    )

    # Get credential and ServiceNow REST URL
    if ($null -ne $Connection) {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $ServiceNowCredential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
    }
    elseif ($null -ne $ServiceNowCredential -and $null -ne $ServiceNowURL) {
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
    $Body = @{'sysparm_limit' = $Limit; 'sysparm_display_value' = $DisplayValues}
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
                    }
                }
            }
        }
    }

    # Return the results
    $Result
}
