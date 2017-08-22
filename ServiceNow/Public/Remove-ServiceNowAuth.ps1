function Remove-ServiceNowAuth{

    If (-not (Test-ServiceNowAuthIsSet)) {
        Return $true
    }
    
    Try {
        Remove-Variable -Name ServiceNowURL -Scope Global -ErrorAction Stop
        Remove-Variable -Name ServiceNowRESTURL -Scope Global -ErrorAction Stop
        Remove-Variable -Name ServiceNowCredentials -Scope Global -ErrorAction Stop
    }
    Catch {
        Write-Error $_
        Return $false
    }

    Return $true
}
