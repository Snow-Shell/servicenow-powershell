<#
.SYNOPSIS
Export an attachment

.DESCRIPTION
Export an attachment identified by its attachment table sys_id.
The contents will be saved to a file by default, but can also be outputted directly.

.PARAMETER ID
The attachment table sys_id of the file

.PARAMETER FileName
File name the file is saved as.  Do not include the path.

.PARAMETER Destination
Path the file is saved to.  Do not include the file name.

.PARAMETER AllowOverwrite
Allows the function to overwrite the existing file.

.PARAMETER AppendNameWithSysID
Adds the SysID to the file name.  Intended for use when a ticket has multiple files with the same name.

.PARAMETER AsValue
Instead of writing to a file, return the attachment contents

.EXAMPLE
Export-ServiceNowAttachment -ID $SysID -FileName 'mynewfile.txt'

Save the attachment with the specified sys_id with a name of 'mynewfile.txt'

.EXAMPLE
Get-ServiceNowAttachment -ID INC1234567 | Export-ServiceNowAttachment

Save all attachments from the ticket.
Filenames will be assigned from the attachment name.

.EXAMPLE
Get-ServiceNowAttachment -ID INC1234567 | Export-ServiceNowAttachment -AppendNameWithSysID

Save all attachments from the ticket.
Filenames will be assigned from the attachment name and appended with the sys_id.

.EXAMPLE
Get-ServiceNowAttachment -ID INC1234567 | Export-ServiceNowAttachment -Destination $path -AllowOverwrite

Save all attachments from the ticket to the destination allowing for overwriting the destination file.

.EXAMPLE
Export-ServiceNowAttachment -ID $ID -AsValue

Return the contents of the attachment instead of writing to a file

#>
Function Export-ServiceNowAttachment {

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ToFile')]

    Param(

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                if ( $_ -match '^[a-zA-Z0-9]{32}$' ) {
                    $true
                }
                else {
                    throw '-ID must be a sys_id 32 character alphanumeric'
                }
            })]
        [Alias('sys_id', 'SysID')]
        [string] $ID,

        [Parameter(ParameterSetName = 'ToFile', ValueFromPipelineByPropertyName)]
        [Alias('file_name')]
        [string] $FileName,

        # Out path to download files
        [parameter(ParameterSetName = 'ToFile')]
        [ValidateScript( {
                Test-Path $_
            })]
        [string] $Destination = $PWD.Path,

        # Options impacting downloads
        [parameter(ParameterSetName = 'ToFile')]
        [switch] $AllowOverwrite,

        # Options impacting downloads
        [parameter(ParameterSetName = 'ToFile')]
        [switch] $AppendNameWithSysId,

        [Parameter(ParameterSetName = 'ToPipeline', Mandatory)]
        [switch] $AsValue,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {
        $authParams = Get-ServiceNowAuth -C $Connection -S $ServiceNowSession
    }

    process	{

        $params = $authParams.Clone()

        $params.Uri += '/attachment/' + $ID + '/file'

        # if not to file, attachment contents to output
        if ( $PSCmdlet.ParameterSetName -eq 'ToFile' ) {
            $thisFileName = $FileName
            If ( $AppendNameWithSysId ) {
                $thisFileName = "{0}_{1}{2}" -f [io.path]::GetFileNameWithoutExtension($thisFileName), $ID, [io.path]::GetExtension($thisFileName)
            }
            $outFile = Join-Path $Destination $thisFileName

            If ((Test-Path $outFile) -and -not $AllowOverwrite ) {
                throw ('The file ''{0}'' already exists.  Please choose a different name, use the -AppendNameWithSysID switch parameter, or use the -AllowOverwrite switch parameter to overwrite the file.' -f $OutFile)
            }

            $params.OutFile = $outFile
        }

        If ($PSCmdlet.ShouldProcess($ID, "Export attachment")) {
            Invoke-RestMethod @params
        }
    }
}
