function New-ServiceNowTableEntry{
    Param
    (
        # Name of the table we're inserting into (e.g. incidents)
        [parameter(Mandatory)]
        [string] $Table,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory)]
        [hashtable] $Values,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $ServiceNowCredential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceNowURL,

        #Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    Invoke-ServiceNowRestMethod @PSBoundParameters -Method 'Post'
}
