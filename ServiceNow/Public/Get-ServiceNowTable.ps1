function Get-ServiceNowTable
{
    [OutputType([Array])]
    Param
    (
        # Name of the table we're querying (e.g. incidents)
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$false)]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,
        
        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$false)]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Query,

        # Maximum number of records to return
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$false)]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [int]$Limit=10,

        # Whether or not to show human readable display values instead of machine values
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$false)]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [ValidateSet("true","false", "all")]
        [string]$DisplayValues='false',
        
        # Credential used to authenticate to ServiceNow  
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $ServiceNowCredential, 

        # The URL for the ServiceNow instance being used  
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceNowURL, 

        #Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)] 
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection
    )

    #Get credential and ServiceNow REST URL
    if ($Connection -ne $null)
    {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $ServiceNowCredential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
        
    } 
    elseif ($ServiceNowCredential -ne $null -and $ServiceNowURL -ne $null)
    {
        $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1'
    }
    elseif((Test-ServiceNowAuthIsSet))
    {
        $ServiceNowCredential = $Global:ServiceNowCredentials
        $ServiceNowURL = $global:ServiceNowRESTURL
    } 
    else 
    {
        throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
    }

    # Populate the query
    $Body = @{'sysparm_limit'=$Limit;'sysparm_display_value'=$DisplayValues}
    if($Query){
        $Body.sysparm_query = $Query
    }
    
    # Fire and return
    $Uri = $ServiceNowURL + "/table/$Table"

    return (Invoke-RestMethod -Uri $Uri -Credential $ServiceNowCredential -Body $Body -ContentType "application/json").result
}
