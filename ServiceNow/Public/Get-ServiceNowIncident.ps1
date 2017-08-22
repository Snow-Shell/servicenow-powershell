function Get-ServiceNowIncident{
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
        [int]$Limit=10,
        
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

    $Query = New-ServiceNowQuery -OrderBy $OrderBy -OrderDirection $OrderDirection -MatchExact $MatchExact -MatchContains $MatchContains
    
    if ($Connection -ne $null)
    {     
        $result = Get-ServiceNowTable -Table 'incident' -Query $Query -Limit $Limit -DisplayValues $DisplayValues -Connection $Connection 
    }
    elseif ($ServiceNowCredential -ne $null -and $ServiceNowURL -ne $null) 
    {
        $result = Get-ServiceNowTable -Table 'incident' -Query $Query -Limit $Limit -DisplayValues $DisplayValues -ServiceNowCredential $ServiceNowCredential -ServiceNowURL $ServiceNowURL 
    }
    else 
    {
        $result = Get-ServiceNowTable -Table 'incident' -Query $Query -Limit $Limit -DisplayValues $DisplayValues
    }

    # Set the default property set for the table view
    $DefaultProperties = @('number', 'short_description', 'opened_at')
    $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$DefaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
    $Result | Add-Member MemberSet PSStandardMembers $PSStandardMembers

    # Return that result!
    return $result
}
