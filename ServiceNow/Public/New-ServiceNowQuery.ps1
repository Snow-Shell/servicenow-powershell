function New-ServiceNowQuery {
    <#
    .SYNOPSIS
        Build query string for api call
    .DESCRIPTION
        Build query string for api call
    .EXAMPLE
        New-ServiceNowQuery -MatchExact @{field_name=value}

        Get query string where field name exactly matches the value
    .EXAMPLE
        New-ServiceNowQuery -MatchContains @{field_name=value}

        Get query string where field name contains the value
    .INPUTS
        None
    .OUTPUTS
        String
    #>

    # This function doesn't change state.  Doesn't justify ShouldProcess functionality
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions','')]

    [CmdletBinding()]
    [OutputType([System.String])]

    param(
        # Machine name of the field to order by
        [parameter(mandatory=$false)]
        [string]$OrderBy='opened_at',

        # Direction of ordering (Desc/Asc)
        [parameter(mandatory=$false)]
        [ValidateSet("Desc", "Asc")]
        [string]$OrderDirection='Desc',

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(mandatory=$false)]
        [hashtable]$MatchExact,

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(mandatory=$false)]
        [hashtable]$MatchContains
    )

    Try {
        # Create StringBuilder
        $Query = New-Object System.Text.StringBuilder

        # Start the query off with a order direction
        $Order = Switch ($OrderDirection) {
            'Asc'   {'ORDERBY'}
            Default {'ORDERBYDESC'}
        }
        [void]$Query.Append($Order)

        # Add OrderBy
        [void]$Query.Append($OrderBy)

        # Build the exact matches into the query
        If ($MatchExact) {
            ForEach ($Field in $MatchExact.keys) {
                $ExactString = "^{0}={1}" -f $Field.ToString().ToLower(), ($MatchExact.$Field)
                [void]$Query.Append($ExactString)
            }
        }

        # Add the values which given fields should contain
        If ($MatchContains) {
            ForEach ($Field in $MatchContains.keys) {
                $ContainsString = "^{0}LIKE{1}" -f $Field.ToString().ToLower(), ($MatchContains.$Field)
                [void]$Query.Append($ContainsString)
            }
        }

        # Output StringBuilder to string
        $Query.ToString()
    }
    Catch {
        Write-Error $PSItem
    }
}
