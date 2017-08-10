function Update-ServiceNowIncident {
    Param
    (   # sys_id of the caller of the incident (user Get-ServiceNowUser to retrieve this)
        [parameter(mandatory=$true)]        
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$true)]
        [parameter(ParameterSetName='UseConnectionObject', mandatory=$true)]
        [parameter(ParameterSetName='SetGlobalAuth', mandatory=$true)]       
        [string]$SysId,

         # Hashtable of values to use as the record's properties        
        [parameter(mandatory=$true)]        
        [hashtable]$Values,

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

    if ($Connection -ne $null)
    {
       Update-ServiceNowTableEntry -Table 'incident' -Values $Values -Connection $Connection -SysId $SysId 
    }
    elseif ($ServiceNowCredential -ne $null -and $ServiceNowURL -ne $null) 
    {
       Update-ServiceNowTableEntry -Table 'incident' -Values $Values -ServiceNowCredential $ServiceNowCredential -ServiceNowURL $ServiceNowURL -SysId $SysId 
    }
    else 
    {
       Update-ServiceNowTableEntry -Table 'incident' -Values $Values -SysId $SysId   
    }     
}