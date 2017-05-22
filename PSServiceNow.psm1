function Test-ServiceNowAuthIsSet{
    if($Global:ServiceNowCredentials){
        return $true;
    }else{
        return $false;
    }   
}

function New-ServiceNowQuery{

    param(
        # Machine name of the field to order by
        [parameter(mandatory=$false)]
        [string]$OrderBy='opened_at',
        
        # Direction of ordering (Desc/Asc)
        [parameter(mandatory=$false)]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection='Desc',
        
        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory=$true)]
        [hashtable]$MatchExact,

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory=$true)]
        [hashtable]$MatchContains
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

    return $Query
}

function Set-ServiceNowAuth{
    param(
        [parameter(mandatory=$true)]
        [string]$url,
        
        [parameter(mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credentials
    )
    $Global:ServiceNowURL = 'https://' + $url
    $Global:ServiceNowRESTURL = $ServiceNowURL + '/api/now/v1'
    $Global:ServiceNowCredentials = $credentials
    return $true;
}

<#
.SYNOPSIS
    Cleans up the variables containing your authentication information from your PowerShell session
#>
function Remove-ServiceNowAuth{
   
    Remove-Variable -Name ServiceNowURL -Scope Global
    Remove-Variable -Name ServiceNowRESTURL -Scope Global
    Remove-Variable -Name ServiceNowCredentials -Scope Global

    return $true;
}
