<#
.SYNOPSIS
Generates a new configuration item

.DESCRIPTION
Generates a new ServiceNow Incident using predefined or custom fields by invoking the ServiceNow API

.PARAMETER Name
    Name of the ci
    
.EXAMPLE
Generate a basic Incident attributed to the caller "UserName" with descriptions, categories, assignment groups and CMDB items set.
    New-ServiceNowIncident -Caller "UserName" -ShortDescription = "New PS Incident" -Description = "This incident was created from Powershell" -AssignmentGroup "ServiceDesk" -Comment "Inline Comment" -Category "Office" -Subcategory "Outlook" -ConfigurationItem UserPC1

.EXAMPLE
#>
function New-ServiceNowConfigurationItem {

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]

    Param(

        [parameter(Mandatory)]
        [string] $Name,

        [parameter(Mandatory)]
        [string] $Class,

        [parameter()]
        [string] $Description,

        [parameter()]
        [string] $OperationalStatus,

        [parameter()]
        [string] $Environment,

        [parameter()]
        [string] $FQDN,

        [parameter()]
        [ipaddress] $IpAddress,

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
        $definedParams = @{
            'Name' = 'name'
        }
        $tableEntryValues = @{}
        foreach ($key in $PSBoundParameters.Keys) {
            if ($definedParams.$key) {
                $tableEntryValues.Add($definedParams.$key, $PSBoundParameters.$key)
            }
        }

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
            throw ('You are attempting to redefine a value, ''{0}'', with $CustomFields that is already set' -f ($dupes -join ","))
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
