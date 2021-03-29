function Invoke-ServiceNowRestMethod {
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

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(SupportsPaging)]
    Param (
        [parameter()]
        [ValidateSet('Get', 'Post', 'Patch', 'Delete')]
        [string] $Method = 'Get',

        # Name of the table we're querying (e.g. incidents)
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $SysId,

        [parameter()]
        [hashtable] $Values,

        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [Parameter()]
        [string]$Query,

        # Maximum number of records to return
        [Parameter()]
        [int]$Limit,

        # Fields to return
        [Parameter()]
        [Alias('Fields')]
        [string[]]$Properties,

        # Whether or not to show human readable display values instead of machine values
        [Parameter()]
        [ValidateSet('true', 'false', 'all')]
        [string]$DisplayValues = 'true',

        [Parameter()]
        [PSCredential]$Credential,

        [Parameter()]
        [string] $ServiceNowURL,

        [Parameter()]
        [hashtable]$Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession
    )

    $params = @{
        Method      = $Method
        ContentType = 'application/json'
    }

    # Get credential and ServiceNow REST URL
    if ( $ServiceNowSession ) {
        $uri = $ServiceNowSession.BaseUri
        if ( $ServiceNowSession.AccessToken ) {
            $params.Headers = @{
                'Authorization' = 'Bearer {0}' -f $ServiceNowSession.AccessToken
            }
        }
    } elseif ( $Credential -and $ServiceNowURL ) {
        Write-Warning -Message 'This authentication path, providing URL and credential directly, will be deprecated in a future release.  Please use New-ServiceNowSession.'
        $uri = 'https://{0}/api/now/v1' -f $ServiceNowURL
        $params.Credential = $Credential
    } elseif ( $Connection ) {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $params.Credential = $Credential
        $uri = 'https://{0}/api/now/v1' -f $Connection.ServiceNowUri
    } else {
        throw "Exception:  You must do one of the following to authenticate: `n 1. Call the New-ServiceNowSession cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
    }

    if ( $Table -eq 'attachment' ) {
        $uri += '/attachment'
    } else {
        $uri += "/table/$Table"
    }
    if ( $SysId ) {
        $uri += "/$SysId"
    }
    $params.Uri = $uri

    if ( $Method -eq 'Get') {
        $Body = @{
            'sysparm_display_value' = $DisplayValues
        }

        # Handle paging parameters
        # If -Limit was provided, write a warning message, but prioritize it over -First.
        # The value of -First defaults to [uint64]::MaxValue if not specified.
        # If no paging information was provided, default to the legacy behavior, which was to return 10 records.

        if ($PSBoundParameters.ContainsKey('Limit')) {
            Write-Warning "The -Limit parameter is deprecated, and may be removed in a future release. Use the -First parameter instead."
            $Body['sysparm_limit'] = $Limit
        } elseif ($PSCmdlet.PagingParameters.First -ne [uint64]::MaxValue) {
            $Body['sysparm_limit'] = $PSCmdlet.PagingParameters.First
        } else {
            $Body['sysparm_limit'] = 10
        }

        if ($PSCmdlet.PagingParameters.Skip) {
            $Body['sysparm_offset'] = $PSCmdlet.PagingParameters.Skip
        }

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            # Accuracy is a double between 0.0 and 1.0 representing an estimated percentage accuracy.
            # 0.0 means we have no idea and 1.0 means the number is exact.

            # ServiceNow does return this information in the X-Total-Count response header,
            # but we're currently using Invoke-RestMethod to perform the API call, and Invoke-RestMethod
            # does not provide the response headers, so we can't capture this info.

            # To properly support this parameter, we'd need to fall back on Invoke-WebRequest, read the
            # X-Total-Count header of the response, and update this parameter after performing the API
            # call.

            # Reference:
            # https://developer.servicenow.com/app.do#!/rest_api_doc?v=jakarta&id=r_TableAPI-GET

            [double] $accuracy = 0.0
            $PSCmdlet.PagingParameters.NewTotalCount($PSCmdlet.PagingParameters.First, $accuracy)
        }

        # Populate the query
        if ($Query) {
            $Body.sysparm_query = $Query
        }

        if ($Properties) {
            $Body.sysparm_fields = ($Properties -join ',').ToLower()
        }
    }

    if ( $Values ) {
        $Body = $Values | ConvertTo-Json

        #Convert to UTF8 array to support special chars such as the danish "ï¿½","ï¿½","ï¿½"
        $body = [System.Text.Encoding]::UTf8.GetBytes($Body)
    }

    if ( $Body ) {
        $params.Body = $Body
    }

    Write-Verbose ($params | Format-List | Out-String)

    $response = Invoke-RestMethod @params

    switch ($Method) {
        'Get' {
            if ( $response.result ) {

                $result = $response | Select-Object -ExpandProperty result
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
                            } Catch {
                                Try {
                                    # Universal Format
                                    $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss'
                                    $SNResult.$Property = [DateTime]::ParseExact($($SNResult.$Property), $DateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)
                                } Catch {
                                    # If the local culture and universal formats both fail keep the property as a string (Do nothing)
                                    $null = 'Silencing a PSSA alert with this line'
                                }
                            }
                        }
                    }
                }
            } else {
                $response
            }
        }

        { $_ -in 'Post', 'Patch' } {
            $result = $response | Select-Object -ExpandProperty result
        }

        'Delete' {
            # nothing to do
        }

        Default {
            # we should never get here given the list of methods is set
        }
    }

    $result
    # Invoke-RestMethod -Uri $Uri -Credential $Credential -Body $Body -ContentType "application/json" | Select-Object -ExpandProperty Result
}
