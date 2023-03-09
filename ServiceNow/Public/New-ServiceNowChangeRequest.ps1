function New-ServiceNowChangeRequest {
    <#
    .SYNOPSIS
        Generates a new ServiceNow change request

    .DESCRIPTION
        Generates a new ServiceNow change request directly with values or via a change model or template.

    .PARAMETER ModelID
        Name or sys_id of the change model to use

    .PARAMETER TemplateID
        Name of sys_id of the standard change template to use

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

    .PARAMETER CustomField
        Custom field values which aren't one of the built in function properties

    .PARAMETER Connection
        Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

    .PARAMETER PassThru
        If provided, the new record will be returned

    .EXAMPLE
        New-ServiceNowChangeRequest -Caller 'Greg Brownstein' -ShortDescription 'New change request'

        Create a basic change request

    .EXAMPLE
        New-ServiceNowChangeRequest -Caller 'Greg Brownstein' -ShortDescription 'New change request' -CustomField @{'urgency'='1'}

        Create a basic change request with custom fields

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

        $values = @{}
        Switch ($PSBoundParameters.Keys) {
            AssignmentGroup { $values['assignment_group'] = $PSBoundParameters.AssignmentGroup }
            Caller { $values['caller_id'] = $PSBoundParameters.Caller }
            Category { $values['category'] = $PSBoundParameters.Category }
            Comment { $values['comments'] = $PSBoundParameters.Comment }
            ConfigurationItem { $values['cmdb_ci'] = $PSBoundParameters.ConfigurationItem }
            Description { $values['description'] = $PSBoundParameters.Description }
            ShortDescription { $values['short_description'] = $PSBoundParameters.ShortDescription }
            Subcategory { $values['subcategory'] = $PSBoundParameters.Subcategory }
            ModelID { $values['chg_model'] = $PSBoundParameters.ModelID }
            TemplateID { $values['std_change_producer_version'] = $PSBoundParameters.TemplateID; $values['type'] = 'Standard' }
        }

        # add custom fields
        $duplicateValues = ForEach ($Key in $CustomField.Keys) {
            If ( $values.ContainsKey($Key) ) {
                $Key
            }
            Else {
                $values.Add($Key, $CustomField[$Key])
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
