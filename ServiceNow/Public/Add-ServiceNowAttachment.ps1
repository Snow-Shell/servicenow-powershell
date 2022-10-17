Function Add-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Attaches a file to an existing record.

    .DESCRIPTION
    Attaches a file to an existing record.

    .PARAMETER Table
    Name of the table to be queried, by either table name or class name.  Use tab completion for list of known tables.
    You can also provide any table name ad hoc.
    If using pipeline and this is failing, most likely the table name and class do not match.
    In this case, provide this value directly.

    .PARAMETER Id
    Either the record sys_id or number.
    If providing just an Id, not with Table, the Id prefix will be looked up to find the table name.

    .PARAMETER File
    Path to one or more files to attach

    .PARAMETER ContentType
    Content (MIME) type for the file being uploaded.
    This value will be automatically determined by default, but can be overridden with this parameter.

    .PARAMETER PassThru
    Return the newly created attachment details

    .PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

    .PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

    .EXAMPLE
    Add-ServiceNowAttachment -Id INC0000010 -File @('.\File01.txt', '.\File02.txt')

    Upload one or more files by record number

    .EXAMPLE
    Add-ServiceNowAttachment -Table incident -Id 2306c37c1bafc9100774ebd1b24bcb6d -File @('.\File01.txt', '.\File02.txt')

    Upload one or more files by record sys_id

    .EXAMPLE
    New-ServiceNowIncident @params -PassThru | Add-ServiceNowAttachment -File file01.txt

    Create a new incident and add an attachment

    .EXAMPLE
    Add-ServiceNowAttachment -Id INC0000010 -File file01.txt -ContentType 'text/plain'

    Upload a file and specify the MIME type (content type).
    Only required if the function cannot automatically determine the type.

    .EXAMPLE
    Add-ServiceNowAttachment -Id INC0000010 -File file01.txt -PassThru

    Upload a file and receive back the file details

    .INPUTS
    Table, ID

    .OUTPUTS
    System.Management.Automation.PSCustomObject if -PassThru provided
    #>

    [OutputType([PSCustomObject[]])]
    [CmdletBinding(SupportsShouldProcess)]

    Param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ($_ -match '^[a-zA-Z0-9]{32}$' -or $_ -match '^([a-zA-Z]+)[0-9]+$') {
                    $true
                } else {
                    throw 'Id must be either a 32 character alphanumeric, ServiceNow sysid, or prefix/id, ServiceNow number.'
                }
            })]
        [Alias('sys_id', 'SysId', 'number')]
        [string] $ID,

        [Parameter(Mandatory)]
        [ValidateScript( {
                if ( Test-Path $_ ) {
                    $true
                } else {
                    throw 'One or more files do not exist'
                }
            })]
        [string[]] $File,

        # Content (MIME) type - if not automatically determined
        [Parameter()]
        [string] $ContentType,

        # Allow the results to be shown
        [Parameter()]
        [switch] $PassThru,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {
        $auth = Get-ServiceNowAuth -C $Connection -S $ServiceNowSession
        $invokeRestMethodSplat = $auth
        $invokeRestMethodSplat.UseBasicParsing = $true
        $invokeRestMethodSplat.Method = 'POST'
    }

    process	{

        if ( $Table ) {
            $thisTableName = $ServiceNowTable.Where{ $_.ClassName -eq $Table } | Select-Object -ExpandProperty Name
            if ( -not $thisTableName ) {
                $thisTableName = $Table
            }
        }

        if ( $ID -match '^[a-zA-Z0-9]{32}$' ) {
            if ( -not $thisTableName ) {
                Write-Error 'Providing sys_id for -Id requires a value for -Table.  Alternatively, provide an -Id with a prefix, eg. INC1234567, and the table will be automatically determined.'
                Continue
            }

            $thisSysId = $ID

        } else {
            if ( -not $thisTableName ) {
                $thisTable = $ServiceNowTable.Where{ $_.NumberPrefix -and $ID.ToLower().StartsWith($_.NumberPrefix) }
                if ( $thisTable ) {
                    $thisTableName = $thisTable.Name
                } else {
                    Write-Error ('The prefix for Id ''{0}'' was not found and the appropriate table cannot be determined.  Known prefixes are {1}.  Please provide a value for -Table.' -f $ID, ($ServiceNowTable.NumberPrefix.Where( { $_ }) -join ', '))
                    Continue
                }
            }

            $getParams = @{
                Table             = $thisTableName
                Id                = $ID
                Property          = 'sys_id'
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            $tableRecord = Get-ServiceNowRecord @getParams

            if ( -not $tableRecord ) {
                Write-Error "Record not found for Id '$ID'"
                continue
            }

            $thisSysId = $tableRecord.sys_id
        }


        foreach ($thisFile in $File) {

            $thisFileObject = Get-ChildItem $thisFile

            If ( -not $PSBoundParameters.ContainsKey('ContentType') ) {
                # Thanks to https://github.com/samuelneff/MimeTypeMap/blob/master/MimeTypeMap.cs from which
                # MimeTypeMap.json was adapted
                $contentTypes = ConvertFrom-Json (Get-Content "$PSScriptRoot\..\config\MimeTypeMap.json" -Raw)

                $Extension = [IO.Path]::GetExtension($thisFileObject.FullName)
                $ContentType = $contentTypes.$Extension

                if ( -not $ContentType ) {
                    Write-Error ('Content type not found for {0}, the file will not be uploaded' -f $thisFileObject.FullName)
                    Continue
                }
            }

            # POST: https://instance.service-now.com/api/now/attachment/file?table_name=incident&table_sys_id=d71f7935c0a8016700802b64c67c11c6&file_name=Issue_screenshot
            $invokeRestMethodSplat.Uri = '{0}/attachment/file?table_name={1}&table_sys_id={2}&file_name={3}' -f $auth.Uri, $thisTableName, $thisSysId, $thisFileObject.Name
            $invokeRestMethodSplat.ContentType = $ContentType
            $invokeRestMethodSplat.InFile = $thisFileObject.FullName

            If ($PSCmdlet.ShouldProcess(('{0} {1}' -f $thisTableName, $thisSysId), ('Add attachment {0}' -f $thisFileObject.FullName))) {

                Write-Verbose ($invokeRestMethodSplat | ConvertTo-Json)

                $response = Invoke-WebRequest @invokeRestMethodSplat

                if ( $response.Content ) {
                    if ( $PassThru ) {
                        $content = $response.content | ConvertFrom-Json
                        $content.result
                    }
                } else {
                    # invoke-webrequest didn't throw an error, but we didn't get content back either
                    throw ('"{0} : {1}' -f $response.StatusCode, $response | Out-String )
                }
            }
        }
    }
}
