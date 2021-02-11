Function Get-ServiceNowAttachmentDetail {
    <#
    .SYNOPSIS
    List details for ServiceNow attachments associated with a ticket number.

    .DESCRIPTION
    List details for ServiceNow attachments associated with a ticket number.

    .PARAMETER Number
    ServiceNow ticket number

    .PARAMETER Table
    ServiceNow ticket table name

    .PARAMETER FileName
    Filter for one or more file names.  Works like a 'match' where partial file names are valid.

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number $Number -Table $Table

    List attachment details

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number $Number -Table $Table -FileName filename.txt,report.csv

    List details for only filename.txt and report.csv (if they exist).

    .OUTPUTS
    System.Management.Automation.PSCustomObject

    .NOTES

    #>

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText','')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidGlobalVars','')]

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName = 'UseConnectionObject')]
    Param(
        # Object number
        [Parameter(Mandatory=$true)]
        [string]$Number,

        # Table containing the entry
        [Parameter(Mandatory=$true)]
        [string]$Table,

        # Filter results by file name
        [parameter(Mandatory=$false)]
        [string[]]$FileName,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string]$ServiceNowURL,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName='UseConnectionObject')]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection = $script:ConnectionObj
    )

	begin {}
	process	{
        Try {
            # Use the number and table to determine the sys_id
            $getServiceNowTableEntrySplat = @{
                Table         = $Table
                MatchExact    = @{number = $number}
                ErrorAction   = 'Stop'
            }

            # Update the splat if the parameters have values
            if ($null -ne $PSBoundParameters.Connection) {
                $getServiceNowTableEntrySplat.Add('Connection', $Connection)
            }
            elseif ($null -ne $PSBoundParameters.Credential -and $null -ne $PSBoundParameters.ServiceNowURL) {
                $getServiceNowTableEntrySplat.Add('Credential', $Credential)
                $getServiceNowTableEntrySplat.Add('ServiceNowURL', $ServiceNowURL)
            }

            $TableSysID = Get-ServiceNowTableEntry @getServiceNowTableEntrySplat | Select-Object -Expand sys_id

            # Populate the query
            $Body = @{
                'sysparm_limit' = 500
                'table_name'    = $Table
                'table_sys_id'  = $TableSysID
                'sysparm_query' = 'ORDERBYfile_name^ORDERBYDESC'
            }

            # Build Attachment URI because table endpoint not used for this API call
            $Uri = 'https://{0}/api/now/v1/attachment' -f $connection.uri

            $headers = @{
                Accept        = 'application/json'
                Authorization = 'Bearer {0}' -f $Connection['AccessToken']
            }

            $invokeRestMethodSplat = @{
                Uri         = $Uri
                Body        = $Body
                Credential  = $Credential
                ContentType = 'application/json'
                Headers     = $headers
            }
            $Result = (Invoke-RestMethod @invokeRestMethodSplat).Result

            # Filter for requested file names
            If ($FileName) {
                $Result = $Result | Where-Object {$PSItem.file_name -match ($FileName -join '|')}
            }

            $Result | Update-ServiceNowDateTimeField
        }
        Catch {
            Write-Error $PSItem
        }
    }
	end {}
}
