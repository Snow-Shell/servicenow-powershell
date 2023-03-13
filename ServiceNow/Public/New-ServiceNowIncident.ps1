<#
.SYNOPSIS
Generates a new ServiceNow Incident

.DESCRIPTION
Generates a new ServiceNow Incident using predefined or other field values

.PARAMETER Caller
    Full name or sys_id of the caller

.PARAMETER ShortDescription
    Short description

.PARAMETER Description
   Long description

.PARAMETER AssignmentGroup
    Full name or sys_id of the assignment group

.PARAMETER Comment
    Comment to include

.PARAMETER Category
    Category name

.PARAMETER Subcategory
    Subcategory name

.PARAMETER ConfigurationItem
    Full name or sys_id of the configuration item to be associated with the change

.PARAMETER InputData
    Field values which aren't one of the built in function properties

.PARAMETER ServiceNowSession
ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER PassThru
    If provided, the new record will be returned

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
            InputData = @{u_custom1 = "Custom Field Entry"
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
        [hashtable] $InputData,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    begin {}

    process {
        $values = @{}
        Switch ($PSBoundParameters.Keys) {
            AssignmentGroup { $values['assignment_group'] = $AssignmentGroup }
            Caller { $values['caller_id'] = $Caller }
            Category { $values['category'] = $Category }
            Comment { $values['comments'] = $Comment }
            ConfigurationItem { $values['cmdb_ci'] = $ConfigurationItem }
            Description { $values['description'] = $Description }
            ShortDescription { $values['short_description'] = $ShortDescription }
            Subcategory { $values['subcategory'] = $Subcategory }
            ModelID { $values['chg_model'] = $ModelID }
            TemplateID { $values['std_change_producer_version'] = $TemplateID; $values['type'] = 'Standard' }
        }

        # add custom fields
        $duplicateValues = ForEach ($Key in $InputData.Keys) {
            If ( $values.ContainsKey($Key) ) {
                $Key
            }
            Else {
                $values.Add($Key, $InputData[$Key])
            }
        }

        # Throw an error if duplicate fields were provided
        If ( $duplicateValues ) {
            Throw ('Fields may only be used once and the following were duplicated: {0}' -f $duplicateValues -join ",")
        }

        # Table Entry Splat
        $params = @{
            Table             = 'incident'
            Values            = $values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
            PassThru          = $true
        }

        If ( $PSCmdlet.ShouldProcess($ShortDescription, 'Create new Incident') ) {
            $response = New-ServiceNowRecord @params
            If ( $PassThru ) {
                $response.PSObject.TypeNames.Insert(0, "ServiceNow.Incident")
                $response
            }
        }
    }
}

