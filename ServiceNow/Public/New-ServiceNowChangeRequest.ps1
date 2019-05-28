function New-ServiceNowChangeRequest{
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

.PARAMETER ServiceNowCredential
    Credential used to authenticate to ServiceNow

.PARAMETER ServiceNowURL
    The URL for the ServiceNow instance being used (eg: instancename.service-now.com)

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.LINK
    https://github.com/Sam-Martin/servicenow-powershell

.EXAMPLE
    Generate a basic change request attributed to the caller "UserName" with descriptions, categories, assignment groups and CMDB items set.
        New-ServiceNowchange request -Caller "UserName" -ShortDescription = "New PS change request" -Description = "This change request was created from Powershell" -AssignmentGroup "ServiceDesk" -Comment "Inline Comment" -Category "Office" -Subcategory "Outlook" -ConfigurationItem UserPC1

.EXAMPLE
    Generate an Change Request by "Splatting" all fields used in the 1st example plus some additional custom ServiceNow fields (These must exist in your ServiceNow Instance):

        $ChangeRequestParams = @{Caller = "UserName"
            ShortDescription = "New PS Change Request"
            Description = "This change request was created from Powershell"
            AssignmentGroup "ServiceDesk"
            Comment "Inline Comment"
            Category "Office"
            Subcategory "Outlook"
            ConfigurationItem UserPC1
            CustomFields = @{u_custom1 = "Custom Field Entry"
                            u_another_custom = "Related Test"}
            }
        New-ServiceNowChangeRequest @Params
 #>

    Param(
        [parameter(Mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Caller,

        [parameter(Mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ShortDescription,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Description,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$AssignmentGroup,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Comment,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Category,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Subcategory,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ConfigurationItem,

        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$CustomFields,

        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential,

        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )

    # Create a hash table of any defined parameters (not CustomFields) that have values
    $DefinedChangeRequestParameters = @('AssignmentGroup','Caller','Category','Comment','ConfigurationItem','Description','ShortDescription','Subcategory')
    $TableEntryValues = @{}
    ForEach ($Parameter in $DefinedChangeRequestParameters) {
        If ($null -ne $PSBoundParameters.$Parameter) {
            # Turn the defined parameter name into the ServiceNow attribute name
            $KeyToAdd = Switch ($Parameter) {
                AssignmentGroup     {'assignment_group'}
                Caller              {'caller_id'}
                Category            {'category'}
                Comment             {'comments'}
                ConfigurationItem   {'cmdb_ci'}
                Description         {'description'}
                ShortDescription    {'short_description'}
                Subcategory         {'subcategory'}
            }
            $TableEntryValues.Add($KeyToAdd,$PSBoundParameters.$Parameter)
        }
    }

    # Add CustomFields hash pairs to the Table Entry Values hash table
    If ($null -ne $PSBoundParameters.CustomFields) {
        $DuplicateTableEntryValues = ForEach ($Key in $CustomFields.Keys) {
            If (($TableEntryValues.ContainsKey($Key) -eq $False)) {
                # Add the unique entry to the table entry values hash table
                $TableEntryValues.Add($Key,$CustomFields[$Key])
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
    $newServiceNowTableEntrySplat = @{
        Table = 'change_request'
        Values = $TableEntryValues
    }

    # Update the splat if the parameters have values
    if ($null -ne $PSBoundParameters.Connection)
    {
        $newServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL)
    {
        $newServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
        $newServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    # Create the table entry
    New-ServiceNowTableEntry @newServiceNowTableEntrySplat
}
