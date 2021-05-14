<#
.SYNOPSIS
    Create a new record in any table

.DESCRIPTION
    Create a new record in any table by specifying the table name and values required for that table

.PARAMETER Table
    Name or class name of the table to create the new record

.PARAMETER Values
    Hashtable with all the key/value pairs for the new record

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.PARAMETER PassThru
    If provided, the new record will be returned
    
.EXAMPLE
    New-ServiceNowTableEntry -Table incident -Values @{'Caller'='me';'short_description'='my issue'}
    Create a new record in the incident table

.INPUTS
    None

.OUTPUTS
    PSCustomObject if PassThru provided
#>
function New-ServiceNowRecord {

    [CmdletBinding(DefaultParameterSetName = 'Session', SupportsShouldProcess)]

    Param
    (
        # Name of the table we're inserting into (e.g. incidents)
        [parameter(Mandatory)]
        [string] $Table,

        # Hashtable of values to use as the record's properties
        [parameter(Mandatory)]
        [hashtable] $Values,

        # Credential used to authenticate to ServiceNow
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $ServiceNowCredential,

        # The URL for the ServiceNow instance being used
        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ServiceNowURL,

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

    $invokeParams = $PSBoundParameters
    $invokeParams.Remove('PassThru') | Out-Null

    If ( $PSCmdlet.ShouldProcess($Table, 'Create new entry') ) {
        $response = Invoke-ServiceNowRestMethod @invokeParams -Method 'Post'
        If ($PassThru.IsPresent) {
            $type = $script:ServiceNowTable | Where-Object {$_.Name -eq $Table -or $_.ClassName -eq $Table} | Select-Object -ExpandProperty Type
            if ($type) {
                $response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $type) }
            }
            $response
        }
    }
}
