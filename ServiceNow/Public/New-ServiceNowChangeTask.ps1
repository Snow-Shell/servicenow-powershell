function New-ServiceNowChangeTask {
    <#
    .SYNOPSIS
        Create a new change task

    .DESCRIPTION
        Create a new change task

    .PARAMETER ChangeRequest
        sys_id or number of parent change request

    .PARAMETER ShortDescription
        Short description of the change task

    .PARAMETER Description
       Long description of the change task

    .PARAMETER AssignmentGroup
        sys_id or name of the assignment group

    .PARAMETER AssignedTo
        sys_id or name of the assigned user

    .PARAMETER CustomField
        Other key/value pairs to create the task which are not one of the existing parameters

    .PARAMETER PassThru
        Return the newly created item details

    .EXAMPLE
        New-ServiceNowChangeTask -ChangeRequest CHG0010001 -ShortDescription 'New PS change request' -Description 'This change request was created from Powershell' -AssignmentGroup ServiceDesk

        Create a new task

    .EXAMPLE
        New-ServiceNowChangeTask -ShortDescription 'New' -Description 'Longer description' -CustomField @{'impact'='3'}

        Create a new task with additional fields
     #>

    [CmdletBinding(SupportsShouldProcess)]

    Param(

        [Parameter(Mandatory)]
        [string] $ShortDescription,

        [parameter(Mandatory)]
        [string] $Description,

        [Parameter()]
        [string] $ChangeRequest,

        [Parameter()]
        [string] $AssignmentGroup,

        [Parameter()]
        [string] $AssignedTo,

        [Parameter()]
        [hashtable] $CustomField,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $createValues = @{}
    }

    process {

        switch ($PSBoundParameters.Keys) {
            'ChangeRequest' {
                $createValues.parent = $ChangeRequest
                $createValues.change_request = $ChangeRequest
            }

            'ShortDescription' {
                $createValues.short_description = $ShortDescription
            }

            'Description' {
                $createValues.description = $Description
            }

            'AssignmentGroup' {
                $createValues.assignment_group = $AssignmentGroup
            }

            'AssignedTo' {
                $createValues.assigned_to = $AssignedTo
            }
        }

        foreach ($key in $CustomField.Keys) {
            if ( $createValues.$key ) {
                Write-Warning "Custom field '$key' has already been provided via one of the dedicated parameters"
            } else {
                $createValues.Add($key, $CustomField.$key)
            }
        }

        $params = @{
            Method            = 'Post'
            Table             = 'change_task'
            Values            = $createValues
            ServiceNowSession = $ServiceNowSession
        }

        If ( $PSCmdlet.ShouldProcess($ShortDescription, 'Create new change task') ) {
            $response = Invoke-ServiceNowRestMethod @params
            If ( $PassThru ) {
                $response.PSObject.TypeNames.Insert(0, "ServiceNow.ChangeTask")
                $response
            }
        }
    }

    end {}
}
