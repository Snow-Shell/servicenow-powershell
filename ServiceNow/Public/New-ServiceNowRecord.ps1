function New-ServiceNowRecord {
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

    [CmdletBinding(SupportsShouldProcess)]

    param
    (
        # Name of the table we're inserting into (e.g. incidents)
        [Parameter(Mandatory)]
        [string] $Table,

        # Hashtable of values to use as the record's properties
        [Parameter(Mandatory)]
        [Hashtable] $Values,

        [Parameter()]
        [Hashtable] $Connection,

        [Parameter()]
        [Hashtable] $ServiceNowSession = $script:ServiceNowSession,

        [Parameter()]
        [switch] $PassThru
    )

    $InvokeParams = $PSBoundParameters
    $InvokeParams.Remove('PassThru') | Out-Null

    if ( $PSCmdlet.ShouldProcess($Table, 'Create new entry') ) {
        $Response = Invoke-ServiceNowRestMethod @InvokeParams -Method 'Post'
        if ($PassThru.IsPresent) {
            $Type = $script:ServiceNowTable | Where-Object { $_.Name -eq $Table -or $_.ClassName -eq $Table } | Select-Object -ExpandProperty Type
            if ($Type) {
                $Response | ForEach-Object { $_.PSObject.TypeNames.Insert(0, $Type) }
            }
            $Response
        }
    }
}
