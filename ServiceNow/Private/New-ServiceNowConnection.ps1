function New-ServiceNowConnection {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [string]$Table,

        [hashtable]$ConnectionObject = $Script:ConnectionObj,

        [string]$SysId
    )
    If ($SysId) {
        $uri = Get-ServiceNowFullUri -Uri $ConnectionObject['Uri'] -Table $Table -SysId $SysId
    }
    else {
        $uri = Get-ServiceNowFullUri -Uri $ConnectionObject['Uri'] -Table $Table
    }

    if ($ConnectionObject.ContainsKey('AccessToken')) {
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
        @{
            Credential = $credObject
            Uri = $uri

        }
    }
    else {
        $ConnectionObject.uri = $uri
        $ConnectionObject
    }
}