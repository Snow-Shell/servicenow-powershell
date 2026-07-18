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
function Invoke-ServiceNowRestMethod {

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(SupportsPaging)]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseBOMForUnicodeEncodedFile', '', Justification = 'issuees with *nix machines and no benefit')]

    param (
        [parameter()]
        [ValidateSet('Get', 'Post', 'Patch', 'Delete')]
        [string] $Method = 'Get',

        # Name of the table we're querying (e.g. incidents)
        [parameter(Mandatory, ParameterSetName = 'Table')]
        [ValidateNotNullOrEmpty()]
        [Alias('sys_class_name')]
        [string] $Table,

        [parameter(ParameterSetName = 'Table')]
        [ValidateNotNullOrEmpty()]
        [string] $SysId,

        [parameter(ParameterSetName = 'Uri')]
        [ValidateNotNullOrEmpty()]
        [string] $UriLeaf,

        # [parameter()]
        # [hashtable] $Header,

        [parameter()]
        [hashtable] $Values,

        [parameter()]
        [object[]] $Filter,

        [parameter()]
        [string] $FilterString,

        [parameter()]
        [string] $Namespace = 'now',

        [parameter()]
        [object[]] $Sort = @('opened_at', 'desc'),

        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [Parameter()]
        [string] $Query,

        # Fields to return
        [Parameter()]
        [Alias('Fields', 'Properties')]
        [string[]] $Property,

        # Whether or not to show human readable display values instead of machine values
        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [Alias('DisplayValues')]
        [string] $DisplayValue = 'true',

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    # get header/body auth values
    $params = Get-ServiceNowAuth -S $ServiceNowSession -N $namespace

    $params.Method = $Method
    $params.ContentType = 'application/json'
    $params.UseBasicParsing = $true

    if ( $Table ) {
        # table can either be the actual table name or class name
        # look up the actual table name
        $tableName = $script:ServiceNowTable | Where-Object { $_.Name.ToLower() -eq $Table.ToLower() -or $_.ClassName.ToLower() -eq $Table.ToLower() } | Select-Object -ExpandProperty Name
        # if not in our lookup, just use the table name as provided
        if ( -not $tableName ) {
            $tableName = $Table
        }

        $params.Uri += "/table/$tableName"
        if ( $SysId ) {
            $params.Uri += "/$SysId"
        }
    } else {
        $params.Uri += $UriLeaf
    }

    if ( $Method -eq 'Get') {
        $Body = @{
            'sysparm_display_value' = $DisplayValue
            'sysparm_limit'         = 10
        }

        if ( $FilterString ) {
            $Body.sysparm_query = $FilterString
        } else {
            $Body.sysparm_query = (New-ServiceNowQuery -Filter $Filter -Sort $Sort)
        }

        # Handle paging parameters
        # The value of -First defaults to [uint64]::MaxValue if not specified.
        # If no paging information was provided, default to the legacy behavior, which was to return 10 records.

        if ($PSCmdlet.PagingParameters.First -ne [uint64]::MaxValue) {
            $Body['sysparm_limit'] = $PSCmdlet.PagingParameters.First
        }

        if ($PSCmdlet.PagingParameters.Skip) {
            $Body['sysparm_offset'] = $PSCmdlet.PagingParameters.Skip
        }

        if ($Query) {
            $Body.sysparm_query = $Query
        }

        if ($Property) {
            $Body.sysparm_fields = $Property -join ','
        }

        if ( $Body ) {
            $params.Body = $Body
        }

        Write-Verbose ($params | ConvertTo-Json)
    }

    if ( $Values ) {
        $Body = $Values | ConvertTo-Json -Compress
        $params.Body = $Body
        Write-Verbose ($params | ConvertTo-Json)

        #Convert to UTF8 array to support special chars such as the danish "ï¿½","ï¿½","ï¿½"
        $params.Body = [System.Text.Encoding]::UTf8.GetBytes($Body)
    }

    # hide invoke-webrequest progress
    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    # Retry configuration from session
    $retryStatusCodes = @(429, 502, 503, 504, 408, 409)
    $maxRetries = if ( $ServiceNowSession.ContainsKey('RetryCount') ) { $ServiceNowSession.RetryCount } else { 2 }
    $retryWait = if ( $ServiceNowSession.ContainsKey('RetryWaitSeconds') ) { $ServiceNowSession.RetryWaitSeconds } else { 5 }
    $maxRetryAfter = if ( $ServiceNowSession.ContainsKey('MaxRetryAfterSeconds') ) { $ServiceNowSession.MaxRetryAfterSeconds } else { 10 }

    $attempt = 0
    while ($true) {
        try {
            $response = Invoke-WebRequest @params
            Write-Debug $response
            break
        } catch {
            $attempt++
            $statusCode = $null

            if ( $_.Exception.Response ) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            if ( $statusCode -and $statusCode -in $retryStatusCodes -and $attempt -le $maxRetries ) {
                Write-Warning "HTTP $statusCode received. Retry attempt $attempt of $maxRetries."

                # Check for Retry-After header
                $waitSeconds = $retryWait
                if ( $_.Exception.Response.Headers ) {
                    $retryAfterValue = $null
                    try {
                        if ( $PSVersionTable.PSVersion.Major -lt 6 ) {
                            $retryAfterValue = $_.Exception.Response.Headers['Retry-After']
                        } else {
                            $retryAfterHeader = $_.Exception.Response.Headers.GetValues('Retry-After')
                            if ( $retryAfterHeader ) {
                                $retryAfterValue = $retryAfterHeader[0]
                            }
                        }
                    } catch {
                        # Header not present, use default wait
                    }

                    if ( $retryAfterValue ) {
                        $retryAfterSeconds = 0
                        if ( [int]::TryParse($retryAfterValue, [ref]$retryAfterSeconds) ) {
                            if ( $retryAfterSeconds -gt $maxRetryAfter ) {
                                Write-Warning "Server requested Retry-After of $retryAfterSeconds seconds which exceeds maximum of $maxRetryAfter seconds."
                                $ProgressPreference = $oldProgressPreference
                                throw $_
                            }
                            $waitSeconds = $retryAfterSeconds
                        }
                    }
                }

                Write-Verbose "Waiting $waitSeconds seconds before retry..."
                Start-Sleep -Seconds $waitSeconds
            } else {
                $ProgressPreference = $oldProgressPreference
                throw $_
            }
        }
    }

    # validate response
    switch ($Method) {
        'Delete' {
            if ( $response.StatusCode -ne 204 ) {
                throw ('"{0} : {1}' -f $response.StatusCode, $response | Out-String )
            }
        }
        Default {
            # TODO: this could use some work
            # checking for content is good, but at times we'll get content that's not valid
            # eg. html content when a dev instance is hibernating
            if ( $response.Content ) {
                $content = $response.content | ConvertFrom-Json
                if ( $content.PSobject.Properties.Name -contains "result" ) {
                    $records = @($content | Select-Object -ExpandProperty result)
                } else {
                    $records = @($content)
                }
            } else {
                # invoke-webrequest didn't throw an error per se, but we didn't get content back either
                throw ('"{0} : {1}' -f $response.StatusCode, $response | Out-String )
            }
        }
    }

    $totalRecordCount = 0
    if ( $response.Headers.'X-Total-Count' ) {
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            $totalRecordCount = [int]$response.Headers.'X-Total-Count'
        } else {
            $totalRecordCount = [int]($response.Headers.'X-Total-Count'[0])
        }
        Write-Verbose "Total number of records for this query: $totalRecordCount"
    }

    # if option to get all records was provided, loop and get them all
    if ( $PSCmdlet.PagingParameters.IncludeTotalCount ) {

        $retrieveRecordCount = $totalRecordCount - $PSCmdlet.PagingParameters.Skip
        if ( $retrieveRecordCount -ne 0 ) {
            Write-Warning "Getting $retrieveRecordCount records..."
        }

        $setPoint = $params.body.sysparm_offset + $params.body.sysparm_limit

        while ($totalRecordCount -gt $setPoint) {

            # up the offset so we get the next set of records
            $params.body.sysparm_offset += $params.body.sysparm_limit
            $setPoint = $params.body.sysparm_offset + $params.body.sysparm_limit

            $end = if ( $totalRecordCount -lt $setPoint ) {
                $totalRecordCount
            } else {
                $setPoint
            }

            Write-Verbose ('getting {0}-{1} of {2}' -f ($params.body.sysparm_offset + 1), $end, $totalRecordCount)

            $pagingAttempt = 0
            while ($true) {
                try {
                    $response = Invoke-WebRequest @params -Verbose:$false
                    break
                } catch {
                    $pagingAttempt++
                    $pagingStatusCode = $null

                    if ( $_.Exception.Response ) {
                        $pagingStatusCode = [int]$_.Exception.Response.StatusCode
                    }

                    if ( $pagingStatusCode -and $pagingStatusCode -in $retryStatusCodes -and $pagingAttempt -le $maxRetries ) {
                        Write-Warning "HTTP $pagingStatusCode received during paging. Retry attempt $pagingAttempt of $maxRetries."
                        Start-Sleep -Seconds $retryWait
                    } else {
                        $ProgressPreference = $oldProgressPreference
                        throw $_
                    }
                }
            }

            $content = $response.content | ConvertFrom-Json
            if ( $content.PSobject.Properties.Name -contains "result" ) {
                $records += $content | Select-Object -ExpandProperty result
            } else {
                $records += $content
            }
        }

        if ( $totalRecordCount -ne ($records.count + $PSCmdlet.PagingParameters.Skip) ) {
            Write-Error ('The expected number of records was not received.  This can occur if your -First value, how many records retrieved at once, is too large.  Lower this value and try again.  Received: {0}, expected: {1}' -f $records.count, ($totalRecordCount - $PSCmdlet.PagingParameters.Skip))
        }
    }

    # set the progress pref back now that done with invoke-webrequest
    $ProgressPreference = $oldProgressPreference

    switch ($Method) {
        'Get' {
            $ConvertToDateField = @('closed_at', 'expected_start', 'follow_up', 'opened_at', 'sys_created_on', 'sys_updated_on', 'work_end', 'work_start')
            foreach ($SNResult in $records) {
                foreach ($Property in $ConvertToDateField) {
                    if (-not [string]::IsNullOrEmpty($SNResult.$Property)) {
                        try {
                            # Extract the default Date/Time formatting from the local computer's "Culture" settings, and then create the format to use when parsing the date/time from Service-Now
                            $CultureDateTimeFormat = (Get-Culture).DateTimeFormat
                            $DateFormat = $CultureDateTimeFormat.ShortDatePattern
                            $TimeFormat = $CultureDateTimeFormat.LongTimePattern
                            $DateTimeFormat = [string[]]@("$DateFormat $TimeFormat", 'yyyy-MM-dd HH:mm:ss')
                            $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                        } catch {
                            # If the local culture and universal formats both fail keep the property as a string (Do nothing)
                            $null = 'Silencing a PSSA alert with this line'
                        }
                    }
                }
            }
        }

        { $_ -in 'Post', 'Patch' } {
            $records = $content | Select-Object -ExpandProperty result
        }

        'Delete' {
            # nothing to do
        }

        Default {
            # we should never get here given the list of methods is set
        }
    }

    $records
}
