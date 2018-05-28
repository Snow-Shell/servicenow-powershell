function Get-ServiceNowTable {
<#
.SYNOPSIS
    Retrieves multiple records for the specified table
.DESCRIPTION
    The Get-ServiceNowTable function retrieves multiple records for the specified table
.INPUTS
    None
.OUTPUTS
    System.Management.Automation.PSCustomObject
.LINK
    Service-Now Kingston REST Table API: https://docs.servicenow.com/bundle/kingston-application-development/page/integrate/inbound-rest/concept/c_TableAPI.html
    Service-Now Table API FAQ: https://hi.service-now.com/kb_view.do?sysparm_article=KB0534905
#>
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

        # Whether to return manipulated display values rather than actual database values.
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
        $ServiceNowDateFormat = $Global:ServiceNowDateFormat
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
    $DefaultServiceNowDateFormat = 'yyyy-MM-dd HH:mm:ss'
    $ConvertToDateField = @('closed_at', 'expected_start', 'follow_up', 'opened_at', 'sys_created_on', 'sys_updated_on', 'work_end', 'work_start')
    ForEach ($SNResult in $Result) {
        ForEach ($Property in $ConvertToDateField) {
            If (-not [string]::IsNullOrEmpty($SNResult.$Property)) {
                If ($DisplayValues -eq $True) {
                    # DateTime fields returned in the Service-Now instance system date format need converting to the local computers "culture" setting based upon the format specified
                    Try {
                        Write-Debug "Date Parsing field: $Property, value: $($SNResult.$Property) against global format $Global:ServiceNowDateFormat"
                        $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $Global:ServiceNowDateFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo)
                    }
                    Catch {
                        Throw "Problem parsing date-time field $Property with value $($SNResult.$Property) against format $Global:ServiceNowDateFormat. " +
                              "Please verify the DateFormat parameter matches the glide.sys.date_format property of the Service-Now instance"
                    }
                }
                Else {
                    # DateTime fields always returned as yyyy-MM-dd hh:mm:ss when sysparm_display_value is set to false
                    Write-Debug "Date Parsing field: $Property, value: $($SNResult.$Property) against default format $DefaultServiceNowDateFormat"
                    $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DefaultServiceNowDateFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo) 
                }
            }
        }
    }

    # Return the results
    $Result
}
