function CheckServiceNowAuthIsSet{
    if($script:ServiceNowCredentials){
        return $true;
    }else{
        return $false;
    }   
}

function Set-ServiceNowAuth{
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credentials
    )
    $script:ServiceNowURL = 'https://' + $url
    $script:ServiceNowRESTURL = $ServiceNowURL + '/api/now/v1'
    $script:ServiceNowCredentials = $credentials
    return $true;
}

function Get-ServiceNowTable
{
    [OutputType([Array])]
    Param
    (
        # Name of the table we're querying (e.g. incidents)
        [parameter(mandatory=$true)]
        [string]$Table,
        
        # sysparm_query param in the format of a ServiceNow encoded query string (see http://wiki.servicenow.com/index.php?title=Encoded_Query_Strings)
        [parameter(mandatory=$false)]
        [string]$Query,

        # Maximum number of records to return
        [parameter(mandatory=$false)]
        [int]$Limit=10,

        # Whether or not to show human readable display values instead of machine values
        [parameter(mandatory=$false)]
        [ValidateSet("true","false", "all")]
        [string]$DisplayValues='false'
    )

    if(! (CheckServiceNowAuthIsSet)){
        Write-Error "You must run Set-ServiceNowAuth prior to executing this cmdlet in order to provide credentials"
    }

    # Populate the query
    $Body = @{'sysparm_limit'=$Limit;'sysparm_display_value'=$DisplayValues}
    if($Query){
        $Body.sysparm_query = $Query
    }
    
    # Fire and return
    $Uri = $script:ServiceNowRESTURL + "/table/$Table"
    return (Invoke-RestMethod -Uri $uri -Credential $script:ServiceNowCredentials -Body $Body -ContentType "application/json").result
}

<#
.Synopsis
   Returns incidents from the connected ServiceNow instance based (optionally based on criteria)
.NOTES
   You must have invoked Set-ServiceNowAuth prior to executing this cmdlet
.EXAMPLE
    Return the incident whose number is exactly INC0010683
        Get-ServiceNowIncident -MatchExact @{number='INC0010683'}
.EXAMPLE
    Return all incidents where the short description contains the word 'user'
        Get-ServiceNowIncident -MatchContains @{short_description='user'} 
#>

function Get-ServiceNowIncident{
    param(
        # Machine name of the field to order by
        [parameter(mandatory=$false)]
        [string]$OrderBy='opened_at',
        
        # Direction of ordering (Desc/Asc)
        [parameter(mandatory=$false)]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection='Desc',

        # Maximum number of records to return
        [parameter(mandatory=$false)]
        [int]$Limit=10,
        
        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory=$false)]
        [hashtable]$MatchExact,

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory=$false)]
        [hashtable]$MatchContains,

        # Whether or not to show human readable display values instead of machine values
        [parameter(mandatory=$false)]
        [ValidateSet("true","false", "all")]
        [string]$DisplayValues='true'
    )

    # Start the query off with a order direction
    $Query = '';
    if($OrderDirection -eq 'Asc'){
        $Query += 'ORDERBY'
    }else{
        $Query += 'ORDERBYDESC'
    }
    $Query +="$OrderBy"

    # Build the exact matches into the query
    if($MatchExact){
        foreach($Field in $MatchExact.keys){
            $Query += "^$Field="+$MatchExact.$Field
        }
    }

    # Add the values which given fields should contain
    if($MatchContains){
        foreach($Field in $MatchContains.keys){
            $Query += "^$($Field)LIKE"+$MatchContains.$Field
        }
    }
        
    $result = Get-ServiceNowTable -Table 'incident' -Query $Query -Limit $Limit -DisplayValues $DisplayValues;
    
    # Set the default property set for the table view
    $DefaultProperties = @('number', 'short_description', 'opened_at')
    $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$DefaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
    $Result | Add-Member MemberSet PSStandardMembers $PSStandardMembers

    # Return that result!
    return $result
}

#http://wiki.servicenow.com/index.php?title=Tables_and_Classes#gsc.tab=0