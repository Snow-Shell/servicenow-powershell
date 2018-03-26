function Get-ServiceNowVariables{
    param(
        # Machine name of the field to order by
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$OrderBy='opened_at',
        
        # Direction of ordering (Desc/Asc)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection='Desc',

        # Maximum number of records to return
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [int]$Limit=1000,
        
        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$MatchExact=@{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$MatchContains=@{},

        # Whether or not to show human readable display values instead of machine values
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [ValidateSet("true","false", "all")]
        [string]$DisplayValues='true',

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

    # Query Splat
    $newServiceNowQuerySplat = @{
        OrderBy = $OrderBy
        OrderDirection = $OrderDirection
        MatchExact = $MatchExact
        MatchContains = $MatchContains
    }
    $Query = New-ServiceNowQuery @newServiceNowQuerySplat

    # Table Splat 
    $getServiceNowTableSplat = @{
        Table = 'sc_item_option_mtom'
        Query = $Query
        Limit = $Limit
        DisplayValues = $DisplayValues
    }
    
    # Update the splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection)
    {     
        $getServiceNowTableSplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL) 
    {
         $getServiceNowTableSplat.Add('ServiceNowCredential',$ServiceNowCredential)
         $getServiceNowTableSplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    # Perform query and return each object in the format.ps1xml format
    $QAResult = Get-ServiceNowTable @getServiceNowTableSplat
    $QAResult | ForEach-Object{$_.PSObject.TypeNames.Insert(0,"ServiceNow.Incident")}
    $QAResult > $null

    #Create QA Table, will be array of hash tables in case there are duplicates
    $QA = @{}

    #Extract Questions and Answers
    #Inform user of how many links to fetch, for fun?
    [int]$numberOfLinks = $QAResult.sc_item_option.link.count*2
    Write-Host "Number of links to fetch for Variables: "$numberOfLinks -ForegroundColor Green

    foreach($link in $QAResult.sc_item_option.link){
        
        #Must use invoke-webrequest as the api doesn't seem to work here, that means tokens DON'T work either
         $answer = ((Invoke-WebRequest -Uri $link -ContentType "application/XML" -Credential $ServiceNowCredentials).Content | ConvertFrom-Json)
         $answerResult = $answer.result.value

        #Get Question
         $question = ((Invoke-WebRequest -Uri $answer.Result.item_option_new.link -ContentType "application/XML" -Credential $serviceNowCredentials).Content | ConvertFrom-Json).result.question_text
         
        #Store hash table array in $QA
        $QA + @{$question = $answerResult}
    }

    return $QA
}
