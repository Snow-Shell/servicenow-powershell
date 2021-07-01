
Function Get-ServiceNowAttachment {
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
    [CmdletBinding(DefaultParameterSetName = 'BySysId')]

    Param(
        # Table containing the entry
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        # Object number
        [Parameter(ParameterSetName = 'ByNumber', Mandatory)]
        [string] $Number,

        [Parameter(ParameterSetName = 'BySysId', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        # Filter results by file name
        [parameter()]
        [string[]] $FileName,

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
        $getAuth = @{
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowUrl
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }
        $params = Get-ServiceNowAuth @getAuth

        # URI format:  https://tenant.service-now.com/api/now/attachment/{sys_id}/file
        $params.Uri += '/attachment/' + $SysID + '/file'
        $params.UseBasicParsing = $true

        if ( $PSCmdlet.ParameterSetName -eq 'ByNumber' ) {
            $getSysIdParams = @{
                Table             = $Table
                Query             = (New-ServiceNowQuery -Filter @('number', '-eq', $number))
                Properties        = 'sys_id'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }
    
            # Use the number and table to determine the sys_id
            $sysId = Invoke-ServiceNowRestMethod @getSysIdParams | Select-Object -ExpandProperty sys_id
        }

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
            ServiceNowSession = $ServiceNowSession
        }
        $response = Invoke-ServiceNowRestMethod @params

        if ( $FileName ) {
            # TODO: move into query
            $response | Where-Object { $_.file_name -in $FileName }
        }
        else {
            $response
        }

        # $response | Update-ServiceNowDateTimeField
    }

    end {}
}
