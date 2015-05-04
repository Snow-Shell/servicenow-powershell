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
        [hashtable]$MatchExact=@{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory=$false)]
        [hashtable]$MatchContains=@{},

        # Whether or not to show human readable display values instead of machine values
        [parameter(mandatory=$false)]
        [ValidateSet("true","false", "all")]
        [string]$DisplayValues='true'
    )

    $Query = New-ServiceNowQuery -OrderBy $OrderBy -OrderDirection $OrderDirection -MatchExact $MatchExact -MatchContains $MatchContains
        
    $result = Get-ServiceNowTable -Table 'incident' -Query $Query -Limit $Limit -DisplayValues $DisplayValues;
    
    # Set the default property set for the table view
    $DefaultProperties = @('number', 'short_description', 'opened_at')
    $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$DefaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
    $Result | Add-Member MemberSet PSStandardMembers $PSStandardMembers

    # Return that result!
    return $result
}

<#
.EXAMPLE
    New-ServiceNowIncident -ShortDescription "Testing with Pester" `
            -Description "Long description" -AssignmentGroup "e9e9a2406f4c35001855fa0dba3ee4f3" `
            -Category "Internal" -SubCategory "Task" `
            -Comment "Comment" -ConfigurationItem "bee8e0ed6f8475001855fa0dba3ee4ea" `
            -Caller "7a4b573a6f3725001855fa0dba3ee485" `
#>

function New-ServiceNowIncident{
    Param(

        # sys_id of the caller of the incident (user Get-ServiceNowUser to retrieve this)
        [parameter(mandatory=$true)]
        [string]$Caller,
        
        # Short description of the incident
        [parameter(mandatory=$true)]
        [string]$ShortDescription,

        # Long description of the incident
        [parameter(mandatory=$false)]
        [string]$Description,

        # sys_id of the assignment group (use Get-ServiceNowUserGroup to retrieve this)
        [parameter(mandatory=$false)]
        [string]$AssignmentGroup,

        # Comment to include in the ticket
        [parameter(mandatory=$false)]
        [string]$Comment,

        # Category of the incident (e.g. 'Network')
        [parameter(mandatory=$false)]
        [string]$Category,

        # Subcategory of the incident (e.g. 'Network')
        [parameter(mandatory=$false)]
        [string]$Subcategory,

        # sys_id of the configuration item of the incident
        [parameter(mandatory=$false)]
        [string]$ConfigurationItem
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

    New-ServiceNowTableEntry -Table 'incident' -Values $Values

}

