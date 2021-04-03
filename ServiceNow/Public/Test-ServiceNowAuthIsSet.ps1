function Test-ServiceNowAuthIsSet{
    if ( $ServiceNowSession.Credential -or $ServiceNowSession.AccessToken ){
        return $true
    }else{
        return $false
    }
}
