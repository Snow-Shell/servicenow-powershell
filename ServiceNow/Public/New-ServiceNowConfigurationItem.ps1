<#
.SYNOPSIS
Generates a new configuration item

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
        AssignmentGroup "ServiceDesk"
        Comment "Inline Comment"
        Category "Office"
        Subcategory "Outlook"
        ConfigurationItem UserPC1
        CustomFields = @{u_custom1 = "Custom Field Entry"
                        u_another_custom = "Related Test"}
        }
    New-ServiceNowIncident @Params

#>
function New-ServiceNowConfigurationItem {

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]

    Param(

        # sys_id of the caller of the incident (user Get-ServiceNowUser to retrieve this)
        [parameter(Mandatory)]
        [string] $Name,

        # Short description of the incident
        [parameter(Mandatory)]
        [string] $ShortDescription,

        # Long description of the incident
        [parameter()]
        [string] $Description,

        # sys_id of the assignment group (use Get-ServiceNowUserGroup to retrieve this)
        [parameter()]
        [string] $AssignmentGroup,

        # Comment to include in the ticket
        [parameter()]
        [string] $Comment,

        # Category of the incident (e.g. 'Network')
        [parameter()]
        [string] $Category,

        # Subcategory of the incident (e.g. 'Network')
        [parameter()]
        [string] $Subcategory,

        # sys_id of the configuration item of the incident
        [parameter()]
        [string] $ConfigurationItem,

        # custom fields as hashtable
        [parameter()]
        [hashtable] $CustomFields,

        #Azure Automation Connection object containing username, password, and URL for the ServiceNow instance
        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Hashtable] $Connection,

        [Parameter(ParameterSetName = 'Session')]
        [ValidateNotNullOrEmpty()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        # Create a hash table of any defined parameters (not CustomFields) that have values
        # $DefinedIncidentParameters = @('AssignmentGroup', 'Caller', 'Category', 'Comment', 'ConfigurationItem', 'Description', 'ShortDescription', 'Subcategory')
        $definedParams = @{
            'Name' = 'name'
        }
        $tableEntryValues = @{}
        foreach ($key in $PSBoundParameters.Keys) {
            if ($definedParams.$key) {
                $tableEntryValues.Add($definedParams.$key, $PSBoundParameters.$key)
            }
        }
        # ForEach ($Parameter in $DefinedIncidentParameters) {
        #     If ($null -ne $PSBoundParameters.$Parameter) {
        #         # Turn the defined parameter name into the ServiceNow attribute name
        #         $KeyToAdd = Switch ($Parameter) {
        #             AssignmentGroup { 'assignment_group'; break }
        #             Caller { 'caller_id'; break }
        #             Category { 'category'; break }
        #             Comment { 'comments'; break }
        #             ConfigurationItem { 'cmdb_ci'; break }
        #             Description { 'description'; break }
        #             ShortDescription { 'short_description'; break }
        #             Subcategory { 'subcategory'; break }
        #         }
        #         $TableEntryValues.Add($KeyToAdd, $PSBoundParameters.$Parameter)
        #     }
        # }

        # Add CustomFields hash pairs to the Table Entry Values hash table
        $dupes = ForEach ($Key in $CustomFields.Keys) {
            If ($TableEntryValues.ContainsKey($Key)) {
                # Capture the duplicate key name
                $Key
            }
            Else {
                # Add the unique entry to the table entry values hash table
                $TableEntryValues.Add($Key, $CustomFields[$Key])
            }
        }

        # Throw an error if duplicate fields were provided
        If ($dupes) {
            throw ('Ticket fields may only be used once and you have redefined ''{0}'' in $CustomFields' -f ($dupes -join ","))
        }

        # Table Entry Splat
        $params = @{
            Table             = 'cmdb_ci'
            Values            = $TableEntryValues
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
            PassThru          = $true
        }

        If ( $PSCmdlet.ShouldProcess($Name, 'Create new configuration item') ) {
            $response = New-ServiceNowRecord @params
            # $response = Invoke-ServiceNowRestMethod @params
            If ($PassThru.IsPresent) {
                $response.PSObject.TypeNames.Insert(0, "ServiceNow.ConfigurationItem")
                $response
            }
        }
    }
}
