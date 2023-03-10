<#
.SYNOPSIS
    Create a new record in any table

.DESCRIPTION
    Create a new record in any table by specifying the table name and values required for that table

.PARAMETER Table
    Name or class name of the table to create the new record

.PARAMETER Values
    Hashtable with all the key/value pairs for the new record

.PARAMETER PassThru
    If provided, the new record will be returned

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    New-ServiceNowRecord -Table incident -Values @{'Caller'='me';'short_description'='my issue'}

    Create a new record in the incident table

.INPUTS
    None

.OUTPUTS
    PSCustomObject if PassThru provided
#>
function New-ServiceNowRecord {

    [CmdletBinding(SupportsShouldProcess)]

    Param
    (
        [parameter(Mandatory)]
        [string] $Table,

        [parameter(Mandatory)]
        [hashtable] $Values,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    $invokeParams = $PSBoundParameters
    $null = $invokeParams.Remove('PassThru')

    If ( $PSCmdlet.ShouldProcess($Table, 'Create new record') ) {

        $response = Invoke-ServiceNowRestMethod @invokeParams -Method 'Post'

        If ( $PassThru ) {
            $type = $script:ServiceNowTable | Where-Object { $_.Name -eq $Table -or $_.ClassName -eq $Table } | Select-Object -ExpandProperty Type
            if ($type) {
                $response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $type) }
            }
            $response
        }
    }
}
