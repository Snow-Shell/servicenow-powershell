function Test-ServiceNowAuthIsSet{
    if($script:ServiceNowSession.Credential){
        return $true;
    }else{
        return $false;
    }
}
