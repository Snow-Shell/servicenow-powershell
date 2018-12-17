function Get-ServiceNowTableEntry {
    <#
    .SYNOPSIS
        Wraps Get-ServiceNowQuery & Get-ServiceNowTable for easier custom table queries
    .DESCRIPTION
        Wraps Get-ServiceNowQuery & Get-ServiceNowTable for easier custom table queries.  No formatting is provided on output.  Every property is returned by default.
    .EXAMPLE
        Get-ServiceNowTableEntry -Table sc_req_item -Limit 1

        Returns one request item (RITM) from the sc_req_item table
    .EXAMPLE
        $Record = Get-ServiceNowTableEntry -Table u_customtable -MatchExact @{number=$Number}
        Update-ServiceNowTableEntry -SysID $Record.sys_id -Table u_customtable -Values @{comments='Ticket updated'}

        Utilize the returned object data with to provide the sys_id property required for updates and removals
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    .NOTES

    #>

    [CmdletBinding(DefaultParameterSetName)]
    param(
        # Table containing the entry we're deleting
        [parameter(mandatory=$true)]
        [string]$Table,

        # Machine name of the field to order by
        [parameter(mandatory = $false)]
        [string]$OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [parameter(mandatory = $false)]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection = 'Desc',

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory = $false)]
        [hashtable]$MatchExact = @{},

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory = $false)]
        [hashtable]$MatchContains = @{},

        # Whether or not to show human readable display values instead of machine values
        [parameter(mandatory = $false)]
        [ValidateSet("true", "false", "all")]
        [string]$DisplayValues = 'true',

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServiceNowCredential')]
        [PSCredential]$Credential,

        [Parameter(ParameterSetName = 'SpecifyConnectionFields', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        [Parameter(ParameterSetName = 'UseConnectionObject', Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Connection
    )

    Try {
        # Query Splat
        $newServiceNowQuerySplat = @{
            OrderBy        = $OrderBy
            MatchExact     = $MatchExact
            OrderDirection = $OrderDirection
            MatchContains  = $MatchContains
            ErrorAction    = 'Stop'
        }
        $Query = New-ServiceNowQuery @newServiceNowQuerySplat

        # Table Splat
        $getServiceNowTableSplat = @{
            Table         = $Table
            Query         = $Query
            Limit         = $Limit
            DisplayValues = $DisplayValues
            ErrorAction   = 'Stop'
        }

        # Update the Table Splat if an applicable parameter set name is in use
        Switch ($PSCmdlet.ParameterSetName) {
            'SpecifyConnectionFields' {
                $getServiceNowTableSplat.Add('ServiceNowCredential', $Credential)
                $getServiceNowTableSplat.Add('ServiceNowURL', $ServiceNowURL)
            }
            'UseConnectionObject' {
                $getServiceNowTableSplat.Add('Connection', $Connection)
            }
            Default {}
        }

        # Add all provided paging parameters
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | Foreach-Object {
            $getServiceNowTableSplat.Add($_, $PSCmdlet.PagingParameters.$_)
        }

        # Perform table query and return each object.  No fancy formatting here as this can pull tables with unknown default properties
        Get-ServiceNowTable @getServiceNowTableSplat
    }
    Catch {
        Write-Error $PSItem
    }
}
