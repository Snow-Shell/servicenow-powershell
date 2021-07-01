Function Export-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .DESCRIPTION
    Save a ServiceNow attachment identified by its sys_id property and saved as the filename specified.

    .PARAMETER SysID
    The ServiceNow sys_id of the file

    .PARAMETER FileName
    File name the file is saved as.  Do not include the path.

    .PARAMETER Destination
    Path the file is saved to.  Do not include the file name.

    .PARAMETER AllowOverwrite
    Allows the function to overwrite the existing file.

    .PARAMETER AppendNameWithSysID
    Adds the SysID to the file name.  Intended for use when a ticket has multiple files with the same name.

    .EXAMPLE
    Get-ServiceNowAttachment -SysID $SysID -FileName 'mynewfile.txt'

    Save the attachment with the specified sys_id with a name of 'mynewfile.txt'

    .EXAMPLE
    Get-ServiceNowAttachment -Number $Number -Table $Table | Get-ServiceNowAttachment

    Save all attachments from the ticket.  Filenames will be assigned from the attachment name.

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number $Number -Table $Table | Get-ServiceNowAttachment -AppendNameWithSysID

    Save all attachments from the ticket.  Filenames will be assigned from the attachment name and appended with the sys_id.

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number $Number -Table $Table | Get-ServiceNowAttachment -Destination $Destination -AllowOverwrite

    Save all attachments from the ticket to the destination allowing for overwriting the destination file.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Table', SupportsShouldProcess = $true)]
    Param(
        
        [Parameter(ParameterSetName = 'Table', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_class_name')]
        [string] $Table,

        [Parameter(ParameterSetName = 'Table', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $TableId,

        [Parameter(ParameterSetName = 'Attachment', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter(ParameterSetName = 'Attachment', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('file_name')]
        [string] $FileName,

        # Out path to download files
        [parameter()]
        [ValidateScript( {
                Test-Path $_
            })]
        [string] $Destination = $PWD.Path,

        # Options impacting downloads
        [parameter()]
        [switch] $AllowOverwrite,

        # Options impacting downloads
        [parameter()]
        [switch] $AppendNameWithSysId,

        # Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {
        $authParams = Get-ServiceNowAuth -C $Connection -S ServiceNowSession
    }

    process	{

        # URI format:  https://tenant.service-now.com/api/now/attachment/{sys_id}/file
        $params = $authParams.Clone()

        # if table record provided, get the attachment details
        if ( $PSCmdlet.ParameterSetName -eq 'Table' ) {

            $attachmentListParams = @{
                Table             = $Table
                Connection        = $Connection
                ServiceNowSession = $ServiceNowSession
            }

            # determine if tableid is the number or sysid
            try {
                [guid] $TableId
                $attachmentListParams.SysId = $TableId
            }
            catch {
                $attachmentListParams.Number = $TableId
            }
        }

        $params.Uri += '/attachment/' + $SysID + '/file'

        If ($AppendNameWithSysId.IsPresent) {
            $FileName = "{0}_{1}{2}" -f [io.path]::GetFileNameWithoutExtension($FileName), $SysID, [io.path]::GetExtension($FileName)
        }
        $OutFile = $Null
        $OutFile = Join-Path $Destination $FileName

        If ((Test-Path $OutFile) -and -not $AllowOverwrite.IsPresent) {
            throw ('The file ''{0}'' already exists.  Please choose a different name, use the -AppendNameWithSysID switch parameter, or use the -AllowOverwrite switch parameter to overwrite the file.' -f $OutFile)
        }

        $params.OutFile = $OutFile

        If ($PSCmdlet.ShouldProcess("SysId $SysId", "Save attachment to file $OutFile")) {
            Invoke-WebRequest @params
        }
    }
    end {}
}
