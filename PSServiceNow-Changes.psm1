function Get-ServiceNowChangeRequest {
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

    $private:Query = New-ServiceNowQuery -OrderBy $private:OrderBy -OrderDirection $private:OrderDirection -MatchExact $private:MatchExact -MatchContains $private:MatchContains
        
    $private:result = Get-ServiceNowTable -Table 'change_request' -Query $private:Query -Limit $private:Limit -DisplayValues $private:DisplayValues;

    # Add the custom type to the change request to enable a view
    $private:result | %{$_.psobject.TypeNames.Insert(0, "PSServiceNow.ChangeRequest")}
    return $private:result
}