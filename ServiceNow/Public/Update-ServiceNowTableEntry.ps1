function Update-ServiceNowTableEntry{
    [CmdletBinding(DefaultParameterSetName = 'UseConnectionObject', ConfirmImpact='High')]
    Param(
        # sys_id of the entry we're updating
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$SysId,
        
        # Table containing the entry we're updating
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,
        
        # Credential used to authenticate to ServiceNow  
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential, 

        # The URL for the ServiceNow instance being used  
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL, 

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject')] 
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection = $Script:ConnectionObj,

        # Hashtable of values to use as the record's properties
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$Values
    )
    # Convert to UTF8 array to support special chars such as the danish "ï¿½","ï¿½","ï¿½"
    # Could possibly be replaced with ContentType = 'application/json; charset = utf-8' in IRM call instead
    $invokeRestMethodSplat = @{
        Method          = 'Post'
        Body            = if ($Values) { [System.Text.Encoding]::UTf8.GetBytes(($Values | ConvertTo-Json)) } else { $null }
        ContentType     = 'application/json'
        UseBasicParsing = $true
    }

    # Use Connection Object or credentials passed directly but default to access token if nothing passed
    if ($PSCmdlet.ParameterSetName -eq 'UseConnectionObject' -and $Script:ConnectionObj) {
        $connectionOutput = New-ServiceNowConnection -ConnectionObject $Connection -Table $Table -SysId $SysId
        $connectionOutput.GetEnumerator() | ForEach-Object {
            $invokeRestMethodSplat.Add($_.Key, $_.Value)
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'SpecifyConnectionFields') {
        $uri = Get-ServiceNowFullUri -Uri $ServiceNowURL -Table $Table -SysId
        $invokeRestMethodSplat.Add('Uri', $uri)
        $invokeRestMethodSplat.Add('Credential', $Credential)
    }
    else {
        throw "Exception: You need to use Set-ServiceNowAuth or provide the -Credential and -ServiceNowUrl parameter"
    }

    $result = (Invoke-RestMethod @invokeRestMethodSplat).Result
    $result
}
