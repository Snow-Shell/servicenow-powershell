function Remove-ServiceNowAuth{
   
    Remove-Variable -Name ServiceNowURL -Scope Global
    Remove-Variable -Name ServiceNowRESTURL -Scope Global
    Remove-Variable -Name ServiceNowCredentials -Scope Global

    return $true;
}
