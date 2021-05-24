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
    #>

    [OutputType([System.Management.Automation.PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName)]
    Param(
        # Table containing the entry
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        # Object number
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Number,

        # Filter results by file name
        [parameter()]
        [string[]] $FileName,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential] $Credential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateScript( { $_ | Test-ServiceNowURL })]
        [ValidateNotNullOrEmpty()]
        [Alias('Url')]
        [string] $ServiceNowURL,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {}

    process	{

        $getSysIdParams = @{
            Table             = $Table
            Query             = (New-ServiceNowQuery -Filter @('number', '-eq', $number))
            Properties        = 'sys_id'
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }

        # Use the number and table to determine the sys_id
        $sysId = Invoke-ServiceNowRestMethod @getSysIdParams | Select-Object -ExpandProperty sys_id

        $params = @{
            Uri               = '/attachment'
            Query             = (
                New-ServiceNowQuery -Filter @(
                    @('table_name', '-eq', $Table),
                    'and',
                    @('table_sys_id', '-eq', $sysId)
                )
            )
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }
        $response = Invoke-ServiceNowRestMethod @params

        if ( $FileName ) {
            $response | Where-Object { $_.file_name -in $FileName }
        }
        else {
            $response
        }

        # $response | Update-ServiceNowDateTimeField
    }

    end {}
}
