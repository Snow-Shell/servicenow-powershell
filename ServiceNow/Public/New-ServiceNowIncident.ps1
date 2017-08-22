function New-ServiceNowIncident{
    Param(

        # sys_id of the caller of the incident (user Get-ServiceNowUser to retrieve this)
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$true)]
        [parameter(ParameterSetName='UseConnectionObject', mandatory=$true)]
        [parameter(ParameterSetName='SetGlobalAuth', mandatory=$true)]
        [string]$Caller,
        
        # Short description of the incident
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$true)]
        [parameter(ParameterSetName='UseConnectionObject', mandatory=$true)]
        [parameter(ParameterSetName='SetGlobalAuth', mandatory=$true)]
        [string]$ShortDescription,

        # Long description of the incident
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Description,

        # sys_id of the assignment group (use Get-ServiceNowUserGroup to retrieve this)
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$AssignmentGroup,

        # Comment to include in the ticket
        [parameter(mandatory=$false)]        
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Comment,

        # Category of the incident (e.g. 'Network')
        [parameter(mandatory=$false)]        
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Category,

        # Subcategory of the incident (e.g. 'Network')
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Subcategory,

        # sys_id of the configuration item of the incident
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ConfigurationItem,

        # custom fields as hashtable 
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$CustomFields,

        # Credential used to authenticate to ServiceNow  
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $ServiceNowCredential, 

        # The URL for the ServiceNow instance being used (eg: instancename.service-now.com)
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

   
    $Values = @{
        'caller_id' = $Caller
        'short_description' = $ShortDescription
        'description' = $Description
        'assignment_group' = $AssignmentGroup
        'comments' = $Comment
        'category' = $Category
        'subcategory' = $Subcategory
        'cmdb_ci' = $ConfigurationItem
    }
    
    if($CustomFields)
    {
        $Values += $CustomFields 
    }
    
    if ($Connection -ne $null)
    {
       New-ServiceNowTableEntry -Table 'incident' -Values $Values -Connection $Connection
    }
    elseif ($ServiceNowCredential -ne $null -and $ServiceNowURL -ne $null) 
    {
       New-ServiceNowTableEntry -Table 'incident' -Values $Values -ServiceNowCredential $ServiceNowCredential -ServiceNowURL $ServiceNowURL
    }
    else 
    {
       New-ServiceNowTableEntry -Table 'incident' -Values $Values   
    } 

}
