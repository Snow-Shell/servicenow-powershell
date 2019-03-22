function New-ServiceNowConnection {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [string]$Table,

        [hashtable]$ConnectionObject = $Script:ConnectionObj
    )

    if ($ConnectionObject.ContainsKey('AccessToken')) {
        $uri = Get-ServiceNowFullUri -Uri $ConnectionObject['Uri'] -Table $Table
        @{
            Headers = @{
                Accept        = 'application/json'
                Authorization = 'Bearer {0}' -f $ConnectionObject['AccessToken']
            }
            Uri = $uri
        }
    }
    elseif ($ConnectionObject.ContainsKey('UserName')) {
        $securePassword = ConvertTo-SecureString -String $ConnectionObject['Password'] -AsPlainText -Force
        $credObject = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $ConnectionObject['UserName']
            $securePassword
        )
        $uri = Get-ServiceNowFullUri -Uri $ConnectionObject['Uri'] -Table $Table
        @{
            Credential = $credObject
            Uri = $uri

        }
    }
    else {
        $ConnectionObject.uri = Get-ServiceNowFullUri -Uri $ConnectionObject['Uri'] -Table $Table
        $ConnectionObject
    }
}