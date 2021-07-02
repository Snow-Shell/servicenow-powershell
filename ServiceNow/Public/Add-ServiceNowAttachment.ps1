Function Add-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Attaches a file to an existing ticket.

    .DESCRIPTION
    Attaches a file to an existing ticket.

    .PARAMETER Number
    ServiceNow ticket number

    .PARAMETER Table
    ServiceNow ticket table name

    .PARAMETER File
    A valid path to the file to attach

    .EXAMPLE
    Add-ServiceNowAttachment -Number $Number -Table $Table -File .\File01.txt, .\File02.txt
    
    Upload one or more files to a ServiceNow ticket by specifing the number and table

    .EXAMPLE
    New-ServiceNowIncident @params -PassThru | Add-ServiceNowAttachment -File File01.txt
    
    Create a new incident and add an attachment

    .EXAMPLE
    Add-ServiceNowAttachment -Number $Number -Table $Table -File .\File01.txt -ContentType 'text/plain'
    
    Upload a file and specify the MIME type (content type).  Should only be required if the function cannot automatically determine the type.

    .EXAMPLE
    Add-ServiceNowAttachment -Number $Number -Table $Table -File .\File01.txt -PassThru

    Upload a file and receive back the file details.

    .OUTPUTS
    System.Management.Automation.PSCustomObject if -PassThru provided
    #>

    [OutputType([PSCustomObject[]])]
    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]
    Param(
        # Table containing the entry
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string]$Table,

        # Object number
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $Number,

        # Filter results by file name
        [parameter(Mandatory)]
        [ValidateScript( {
                Test-Path $_
            })]
        [string[]] $File,

        # Content (MIME) type - if not automatically determined
        [Parameter()]
        [string] $ContentType,

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
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        # Allow the results to be shown
        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process	{

        $getSysIdParams = @{
            Table             = $Table
            Query             = (New-ServiceNowQuery -Filter @('number', '-eq', $number))
            Properties        = 'sys_id'
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        # Use the number and table to determine the sys_id
        $sysId = Invoke-ServiceNowRestMethod @getSysIdParams | Select-Object -ExpandProperty sys_id

        $auth = Get-ServiceNowAuth -C $Connection -S ServiceNowSession

        ForEach ($Object in $File) {
            $FileData = Get-ChildItem $Object -ErrorAction Stop
            If (-not $ContentType) {
                # Thanks to https://github.com/samuelneff/MimeTypeMap/blob/master/MimeTypeMap.cs from which
                # MimeTypeMap.json was adapted
                $ContentTypeHash = ConvertFrom-Json (Get-Content "$PSScriptRoot\..\config\MimeTypeMap.json" -Raw)

                $Extension = [IO.Path]::GetExtension($FileData.FullName)
                $ContentType = $ContentTypeHash.$Extension
            }

            # POST: https://instance.service-now.com/api/now/attachment/file?table_name=incident&table_sys_id=d71f7935c0a8016700802b64c67c11c6&file_name=Issue_screenshot
            # $Uri = "{0}/file?table_name={1}&table_sys_id={2}&file_name={3}" -f $ApiUrl, $Table, $TableSysID, $FileData.Name
            $invokeRestMethodSplat = $auth
            $invokeRestMethodSplat.Uri += '/attachment/file?table_name={0}&table_sys_id={1}&file_name={2}' -f $Table, $sysId, $FileData.Name
            $invokeRestMethodSplat.Headers += @{'Content-Type' = $ContentType }
            $invokeRestMethodSplat.UseBasicParsing = $true
            $invokeRestMethodSplat += @{
                Method = 'POST'
                InFile = $FileData.FullName
            }

            If ($PSCmdlet.ShouldProcess("$Table $Number", 'Add attachment')) {
                Write-Verbose ($invokeRestMethodSplat | ConvertTo-Json)
                $response = Invoke-WebRequest @invokeRestMethodSplat

                if ( $response.Content ) {
                    if ( $PassThru.IsPresent ) {
                        $content = $response.content | ConvertFrom-Json
                        $content.result
                    }
                }
                else {
                    # invoke-webrequest didn't throw an error, but we didn't get content back either
                    throw ('"{0} : {1}' -f $response.StatusCode, $response | Out-String )
                }
            }
        }
    }

    end {}
}
