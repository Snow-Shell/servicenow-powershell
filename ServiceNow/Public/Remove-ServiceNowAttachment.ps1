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

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess, ConfirmImpact = 'High')]
    Param(
        # Attachment sys_id
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('sys_id')]
        [string] $SysId,

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

        $params = @{
            Method            = 'Delete'
            UriLeaf           = "/attachment/$SysId"
            Connection        = $Connection
            Credential        = $Credential
            ServiceNowUrl     = $ServiceNowURL
            ServiceNowSession = $ServiceNowSession
        }

        If ($PSCmdlet.ShouldProcess("SysId $SysId", 'Remove attachment')) {
            Invoke-ServiceNowRestMethod @params
        }
    }

    end {}
}
