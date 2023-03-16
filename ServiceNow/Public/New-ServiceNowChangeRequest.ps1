<#
.SYNOPSIS
    Generates a new ServiceNow change request

.DESCRIPTION
    Generates a new ServiceNow change request directly with values or via a change model or template.

.PARAMETER ModelID
    Name or sys_id of the change model to use

.PARAMETER TemplateID
    Name or sys_id of the standard change template to use

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
    New-ServiceNowChangeRequest -Caller 'Greg Brownstein' -ShortDescription 'New change request'

    Create a basic change request

.EXAMPLE
    New-ServiceNowChangeRequest -Caller 'Greg Brownstein' -ShortDescription 'New change request' -InputData @{'urgency'='1'}

    Create a basic change request with other fields

.EXAMPLE
    New-ServiceNowChangeRequest -TemplateID 'Change VLAN on a Cisco switchport - 1'

    Create a change request from a standard change template

.EXAMPLE
    New-ServiceNowChangeRequest -ModelID 'Normal' -ShortDescription 'make this change' -ConfigurationItem dbserver1

    Create a change request from a change model

.EXAMPLE
    New-ServiceNowChangeRequest -Caller 'Greg Brownstein' -ShortDescription 'New change request' -PassThru

    Create a change request and return the newly created record

 #>
function New-ServiceNowChangeRequest {

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'direct')]

    Param(
        [parameter(Mandatory, ParameterSetName = 'model')]
        [string] $ModelID,

        [parameter(Mandatory, ParameterSetName = 'template')]
        [string] $TemplateID,

        [parameter()]
        [string] $Caller,

        [parameter()]
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
            Table             = 'change_request'
            Values            = $values
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
            PassThru          = $true
        }

        If ( $PSCmdlet.ShouldProcess('', 'Create new change request') ) {
            $response = New-ServiceNowRecord @params
            If ( $PassThru ) {
                $response.PSObject.TypeNames.Insert(0, "ServiceNow.ChangeRequest")
                $response
            }
        }
    }

    end {}
}
