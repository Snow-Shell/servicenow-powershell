function Test-ServiceNowAuthIsSet{
    if($Global:ServiceNowCredentials){
        return $true;
    }else{
        return $false;
    }   
}
