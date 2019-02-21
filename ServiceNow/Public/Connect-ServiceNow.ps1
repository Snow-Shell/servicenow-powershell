function Connect-ServiceNow {
    [CmdletBinding(DefaultParameterSetName = 'AccessToken')]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('ServiceNowUrl')]
        [string]$Url,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Credential')]
        [Alias('Credentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [System.Management.Automation.PSCredential]
        $ClientCredential,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'AccessToken')]
        [System.Management.Automation.PSCredential]
        $UserCredential
    )
    
    $Script:ConnectionObj = @{
        Uri = $Url
    }

    if ($Pscmdlet.ParameterSetName -eq 'AccessToken') {
        $AccessToken = Get-ServiceNowOAuthToken -Url $Url -ClientCredential $ClientCredential -UserCredential $UserCredential -Verbose
        $Script:ConnectionObj.Add('AccessToken', $AccessToken)
    }
    else {
        $Script:ConnectionObj.Add('Credential', $Credential)
    }
}