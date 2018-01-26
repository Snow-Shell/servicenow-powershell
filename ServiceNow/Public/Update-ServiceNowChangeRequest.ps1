<#
.EXAMPLE
    Update-ServiceNowChangeRequest -Values @{ 'state' = 3 } -SysId <sysid>
#>
function Update-ServiceNowChangeRequest
{
    Param(
        # sys_id of the caller of the incident (use Get-ServiceNowUser to retrieve this)
        [parameter(Mandatory=$true)]        
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]       
        [string]$SysId,

         # Hashtable of values to use as the record's properties        
        [parameter(Mandatory=$true)]        
        [hashtable]$Values,

         # Credential used to authenticate to ServiceNow  
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential, 

        # The URL for the ServiceNow instance being used (eg: instancename.service-now.com)
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL, 

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )                      

    $updateServiceNowTableEntrySplat = @{
        SysId = $SysId
        Table = 'change_request'
        Values = $Values
    }
    
    # Update the splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection)
    {     
        $updateServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL) 
    {
         $updateServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
         $updateServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }
       
    Update-ServiceNowTableEntry @updateServiceNowTableEntrySplat   
}
