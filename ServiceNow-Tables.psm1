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

    if(! (Test-ServiceNowAuthIsSet)){
        Write-Error "You must run Set-ServiceNowAuth prior to executing this cmdlet in order to provide credentials"
    }

    # Populate the query
    $Body = @{'sysparm_limit'=$Limit;'sysparm_display_value'=$DisplayValues}
    if($Query){
        $Body.sysparm_query = $Query
    }
    
    # Fire and return
    $Uri = $global:ServiceNowRESTURL + "/table/$Table"
    return (Invoke-RestMethod -Uri $uri -Credential $global:ServiceNowCredentials -Body $Body -ContentType "application/json").result
}

function New-ServiceNowTableEntry{
    Param
    (
        # Name of the table we're inserting into (e.g. incidents)
        [parameter(mandatory=$true)]
        [string]$Table,
        
        # Hashtable of values to use as the record's properties
        [parameter(mandatory=$false)]
        [hashtable]$Values
    )

    if(! (Test-ServiceNowAuthIsSet)){
        Write-Error "You must run Set-ServiceNowAuth prior to executing this cmdlet in order to provide credentials"
    }

    $Body = $Values | ConvertTo-Json;

    # Fire and return
    $Uri = $global:ServiceNowRESTURL + "/table/$Table"
    return (Invoke-RestMethod -Uri $uri -Method Post -Credential $global:ServiceNowCredentials -Body $Body -ContentType "application/json").result
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
        [string]$SysId,
        
        # Table containing the entry we're deleting
        [parameter(mandatory=$true)]
        [string]$Table
    )

    # Fire and return
    $Uri = $global:ServiceNowRESTURL + "/table/$Table/$SysID"
    return (Invoke-RestMethod -Uri $uri -Method Delete -Credential $global:ServiceNowCredentials -Body $Body -ContentType "application/json").result
}