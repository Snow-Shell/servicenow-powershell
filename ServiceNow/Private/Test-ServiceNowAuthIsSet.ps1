function Test-ServiceNowAuthIsSet{
    if($Script:ConnectionObj){
        return $true;
    }else{
        return $false;
    }   
}