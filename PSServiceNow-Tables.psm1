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

function New-ServiceNowTableEntry{
    Param
    (
        # Name of the table we're inserting into (e.g. incidents)
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,
        
        # Hashtable of values to use as the record's properties
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$Values,
        
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

    
    $Body = $Values | ConvertTo-Json;

    #Convert to UTF8 array to support special chars such as the danish "�","�","�"
    $utf8Bytes = [System.Text.Encoding]::UTf8.GetBytes($Body)

    # Fire and return
    $Uri = $ServiceNowURL + "/table/$Table"
    return (Invoke-RestMethod -Uri $uri -Method Post -Credential $ServiceNowCredential -Body $utf8Bytes -ContentType "application/json" -UseBasicParsing).result
}

<#
.COMMENT
    Untested
#>
function Remove-ServiceNowTableEntry{
    [CmdletBinding(ConfirmImpact='High')]
    Param(
        # sys_id of the entry we're deleting
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$SysId,
        
        # Table containing the entry we're deleting
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,
        
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
        $ConnectionInfo = Get-ConnectionInfo -Connection $Connection
    }
    elseif ($ServiceNowCredential -ne $null -and $ServiceNowURL -ne $null) 
    {
        $ConnectionInfo = Get-ConnectionInfo -ServiceNowCredential $ServiceNowCredential -ServiceNowURL $ServiceNowURL
    }
    else 
    {
        $ConnectionInfo = Get-ConnectionInfo -UseGlobalAuth $true
    }
    
   
    # Fire and return
    $Uri = $ConnectionInfo["URL"] + "/table/$Table/$SysID"
    return (Invoke-RestMethod -Uri $uri -Method Delete -Credential $ConnectionInfo["Credential"] -Body $Body -ContentType "application/json" -UseBasicParsing).result
}


function Get-ConnectionInfo 
{
   [OutputType([HashTable])]
    param (
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
        $Connection,
        
        [Parameter(ParameterSetName='SetGlobalAuth', Mandatory=$True)] 
        [ValidateNotNullOrEmpty()]
        [Bool]
        $UseGlobalAuth

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

    $Connectioninfo = @{}
    $ConnectionInfo.Add("Credential", $ServiceNowCredential)
    $Connectioninfo.Add("URL", $ServiceNowURL)

    return $Connectioninfo
}