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
function New-ServiceNowIncident {

    [CmdletBinding(SupportsShouldProcess)]

    Param(

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
        [Alias('CustomFields')]
        [hashtable] $CustomField,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        # Create a hash table of any defined parameters (not CustomField) that have values
        $DefinedIncidentParameters = @('AssignmentGroup', 'Caller', 'Category', 'Comment', 'ConfigurationItem', 'Description', 'ShortDescription', 'Subcategory')
        $TableEntryValues = @{}
        ForEach ($Parameter in $DefinedIncidentParameters) {
            If ($null -ne $PSBoundParameters.$Parameter) {
                # Turn the defined parameter name into the ServiceNow attribute name
                $KeyToAdd = Switch ($Parameter) {
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
        If ($null -ne $PSBoundParameters.CustomField) {
            $DuplicateTableEntryValues = ForEach ($Key in $CustomField.Keys) {
                If (($TableEntryValues.ContainsKey($Key) -eq $False)) {
                    # Add the unique entry to the table entry values hash table
                    $TableEntryValues.Add($Key, $CustomField[$Key])
                }
                Else {
                    # Capture the duplicate key name
                    $Key
                }
            }
        }

        # Throw an error if duplicate fields were provided
        If ($null -ne $DuplicateTableEntryValues) {
            $DuplicateKeyList = $DuplicateTableEntryValues -join ","
            Throw "Ticket fields may only be used once:  $DuplicateKeyList"
        }

        # Table Entry Splat
        $params = @{
            Method            = 'Post'
            Table             = 'incident'
            Values            = $TableEntryValues
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        If ( $PSCmdlet.ShouldProcess($ShortDescription, 'Create new incident') ) {
            $response = Invoke-ServiceNowRestMethod @params
            If ($PassThru.IsPresent) {
                $response.PSObject.TypeNames.Insert(0, "ServiceNow.Incident")
                $response
            }
        }
    }
}
