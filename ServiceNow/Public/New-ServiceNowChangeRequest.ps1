function New-ServiceNowChangeRequest {
    <#
    .SYNOPSIS
        Generates a new ServiceNow change request

    .DESCRIPTION
        Generates a new ServiceNow change request using predefined or custom fields by invoking the ServiceNow API

    .PARAMETER Caller
        sys_id of the caller of the change request (user Get-ServiceNowUser to retrieve this)

    .PARAMETER ShortDescription
        Short description of the change request

    .PARAMETER Description
       Long description of the change request

    .PARAMETER AssignmentGroup
        sys_id of the assignment group (use Get-ServiceNowUserGroup to retrieve this)

    .PARAMETER Comment
        Comment to include in the ticket

    .PARAMETER Category
        Category of the change request (e.g. 'Network')

    .PARAMETER Subcategory
        Subcategory of the change request (e.g. 'Network')

    .PARAMETER ConfigurationItem
        sys_id of the configuration item of the change request

    .PARAMETER CustomFields
        Custom fields as hashtable

    .PARAMETER Connection
        Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

    .PARAMETER PassThru
        Returns the ticket values after creation

    .LINK
        https://github.com/Snow-Shell/servicenow-powershell

    .EXAMPLE
        Generate a basic change request attributed to the caller "UserName" with descriptions, categories, assignment groups and CMDB items set.

        New-ServiceNowchange request -Caller UserName -ShortDescription 'New PS change request' -Description 'This change request was created from Powershell' -AssignmentGroup ServiceDesk -Comment 'Inline Comment' -Category Office -Subcategory Outlook -ConfigurationItem UserPC1

    .EXAMPLE
        Generate an Change Request by 'splatting' all fields used in the 1st example plus some additional custom ServiceNow fields (These must exist in your ServiceNow instance),  This example uses the caller's sys_id value for identification.

        $newServiceNowChangeRequestSplat = @{
            Caller            = '55ccf91161924edc979d8e7e5627a47d'
            ShortDescription  = 'New PS Change Request'
            Description       = 'This change request was created from Powershell'
            AssignmentGroup   = 'ServiceDesk'
            Comment           = 'Inline Comment'
            Category          = 'Office'
            Subcategory       = 'Outlook'
            ConfigurationItem = 'UserPC1'
            CustomFields      = @{
                u_custom1        = 'Custom Field Entry'
                u_another_custom = 'Related Test'
            }
        }
        New-ServiceNowChangeRequest @newServiceNowChangeRequestSplat
     #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        [parameter(Mandatory)]
        [string] $Caller,

        [parameter(Mandatory)]
        [string] $ShortDescription,

        [parameter()]
        [string] $Description,

        [parameter()]
        [string] $AssignmentGroup,

        [parameter()]
        [string] $Comment,

        [parameter()]
        [string] $Category,

        [parameter()]
        [string] $Subcategory,

        [parameter()]
        [string] $ConfigurationItem,

        [parameter()]
        [Hashtable] $CustomFields,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        # Create a hash table of any defined parameters (not CustomFields) that have values
        $DefinedChangeRequestParameters = @('AssignmentGroup', 'Caller', 'Category', 'Comment', 'ConfigurationItem', 'Description', 'ShortDescription', 'Subcategory')
        $TableEntryValues = @{ }
        foreach ($Parameter in $DefinedChangeRequestParameters) {
            if ($null -ne $PSBoundParameters.$Parameter) {
                # Turn the defined parameter name into the ServiceNow attribute name
                $KeyToAdd = switch ($Parameter) {
                    AssignmentGroup { 'assignment_group'; break }
                    Caller { 'caller_id'; break }
                    Category { 'category'; break }
                    Comment { 'comments'; break }
                    ConfigurationItem { 'cmdb_ci'; break }
                    Description { 'description'; break }
                    ShortDescription { 'short_description'; break }
                    Subcategory { 'subcategory'; break }
                }
                $TableEntryValues.Add($KeyToAdd, $PSBoundParameters.$Parameter)
            }
        }

        # Add CustomFields hash pairs to the Table Entry Values hash table
        if ($null -ne $PSBoundParameters.CustomFields) {
            $DuplicateTableEntryValues = foreach ($Key in $CustomFields.Keys) {
                if (($TableEntryValues.ContainsKey($Key) -eq $false)) {
                    # Add the unique entry to the table entry values hash table
                    $TableEntryValues.Add($Key, $CustomFields[$Key])
                } else {
                    # Capture the duplicate key name
                    $Key
                }
            }
        }

        # Throw an error if duplicate fields were provided
        if ($null -ne $DuplicateTableEntryValues) {
            $DuplicateKeyList = $DuplicateTableEntryValues -join ','
            throw "Ticket fields may only be used once: $DuplicateKeyList"
        }

        # Table Entry Splat
        $Params = @{
            Method            = 'Post'
            Table             = 'change_request'
            Values            = $TableEntryValues
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ( $PSCmdlet.ShouldProcess($ShortDescription, 'Create new change request') ) {
            $Response = Invoke-ServiceNowRestMethod @Params
            if ($PassThru.IsPresent) {
                $Response.PSObject.TypeNames.Insert(0, 'ServiceNow.ChangeRequest')
                $Response
            }
        }
    }

    end {}
}
