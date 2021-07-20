Function Remove-ServiceNowAttachment {
    <#
    .SYNOPSIS
    Remove a ServiceNow attachment by sys_id.

    .DESCRIPTION
    Remove a ServiceNow attachment by sys_id.

    .EXAMPLE
    Remove-ServiceNowAttachment -SysID $SysID

    Removes the attachment with the associated sys_id

    .EXAMPLE
    Get-ServiceNowAttachmentDetail -Number CHG0000001 | Remove-ServiceNowAttachment

    Removes all attachments from CHG0000001

    .INPUTS
    SysId

    .OUTPUTS
    None

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        # Attachment sys_id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {}

    process	{

        $params = @{
            Method            = 'Delete'
            UriLeaf           = "/attachment/$SysId"
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("SysId $SysId", 'Remove attachment')) {
            Invoke-ServiceNowRestMethod @params
        }
    }

    end {}
}
