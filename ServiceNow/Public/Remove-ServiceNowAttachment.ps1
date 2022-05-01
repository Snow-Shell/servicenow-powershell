function Remove-ServiceNowAttachment {
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
    param(
        # Attachment sys_id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {}

    process	{

        $Params = @{
            Method            = 'Delete'
            UriLeaf           = "/attachment/$SysId"
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ($PSCmdlet.ShouldProcess("SysId $SysId", 'Remove attachment')) {
            Invoke-ServiceNowRestMethod @Params
        }
    }

    end {}
}
