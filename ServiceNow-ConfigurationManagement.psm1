function Get-ServiceNowConfigurationItem {
    param(
        # Machine name of the field to order by
        [parameter(mandatory=$false)]
        [string]$OrderBy='name',
        
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
        
    $result = Get-ServiceNowTable -Table 'cmdb_ci' -Query $Query -Limit $Limit -DisplayValues $DisplayValues;

    # Set the default property set for the table view
    $DefaultProperties = @('name', 'category', 'subcategory')
    $DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$DefaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
    $Result | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    return $result
}