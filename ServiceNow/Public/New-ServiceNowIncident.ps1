function New-ServiceNowIncident {
    <#
    .SYNOPSIS
        Generates a new ServiceNow Incident

    .DESCRIPTION
        Generates a new ServiceNow Incident using predefined or custom fields by invoking the ServiceNow API

    .EXAMPLE
        Generate a basic Incident attributed to the caller "UserName" with descriptions, categories, assignment groups and CMDB items set.
        New-ServiceNowIncident -Caller "UserName" -ShortDescription = "New PS Incident" -Description = "This incident was created from Powershell" -AssignmentGroup "ServiceDesk" -Comment "Inline Comment" -Category "Office" -Subcategory "Outlook" -ConfigurationItem UserPC1

    .EXAMPLE
        Generate an Incident by "Splatting" all fields used in the 1st example plus some additional custom ServiceNow fields (These must exist in your ServiceNow Instance):

            $IncidentParams = @{Caller = "UserName"
                ShortDescription = "New PS Incident"
                Description = "This incident was created from Powershell"
                AssignmentGroup = "ServiceDesk"
                Comment = "Inline Comment"
                Category = "Office"
                Subcategory = "Outlook"
                ConfigurationItem = "UserPC1"
                CustomFields = @{u_custom1 = "Custom Field Entry"
                                u_another_custom = "Related Test"}
                }
            New-ServiceNowIncident @IncidentParams

    #>

    [CmdletBinding(SupportsShouldProcess)]

    Param(
        # sys_id of the caller of the incident (user Get-ServiceNowUser to retrieve this)
        [Parameter(Mandatory)]
        [string] $Caller,

        # Short description of the incident
        [Parameter(Mandatory)]
        [string] $ShortDescription,

        # Long description of the incident
        [Parameter()]
        [string] $Description,

        # sys_id of the assignment group (use Get-ServiceNowUserGroup to retrieve this)
        [Parameter()]
        [string] $AssignmentGroup,

        # Comment to include in the ticket
        [Parameter()]
        [string] $Comment,

        # Category of the incident (e.g. 'Network')
        [Parameter()]
        [string] $Category,

        # Subcategory of the incident (e.g. 'Network')
        [Parameter()]
        [string] $Subcategory,

        # sys_id of the configuration item of the incident
        [Parameter()]
        [string] $ConfigurationItem,

        # custom fields as hashtable
        [Parameter()]
        [Alias('CustomFields')]
        [Hashtable] $CustomField,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        # Create a hash table of any defined parameters (not CustomField) that have values
        $DefinedIncidentParameters = @('AssignmentGroup', 'Caller', 'Category', 'Comment', 'ConfigurationItem', 'Description', 'ShortDescription', 'Subcategory')
        $TableEntryValues = @{}
        foreach ($Parameter in $DefinedIncidentParameters) {
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

        # Add CustomField hash pairs to the Table Entry Values hash table
        if ($null -ne $PSBoundParameters.CustomField) {
            $DuplicateTableEntryValues = foreach ($Key in $CustomField.Keys) {
                if (($TableEntryValues.ContainsKey($Key) -eq $false)) {
                    # Add the unique entry to the table entry values hash table
                    $TableEntryValues.Add($Key, $CustomField[$Key])
                } else {
                    # Capture the duplicate key name
                    $Key
                }
            }
        }

        # Throw an error if duplicate fields were provided
        if ($null -ne $DuplicateTableEntryValues) {
            $DuplicateKeyList = $DuplicateTableEntryValues -join ','
            throw "Ticket fields may only be used once:  $DuplicateKeyList"
        }

        # Table Entry Splat
        $Params = @{
            Method            = 'Post'
            Table             = 'incident'
            Values            = $TableEntryValues
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ( $PSCmdlet.ShouldProcess($ShortDescription, 'Create new incident') ) {
            $Response = Invoke-ServiceNowRestMethod @Params
            if ($PassThru.IsPresent) {
                $Response.PSObject.TypeNames.Insert(0, 'ServiceNow.Incident')
                $Response
            }
        }
    }
}
