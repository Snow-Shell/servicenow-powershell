<#
.SYNOPSIS
    Build query string for api call

.DESCRIPTION
    Build query string for api call, there are basic and advanced methods; see the different parameter sets.

    Basic allows you to look for exact matches as well as fields that are like a value; these are all and'd together.
    You can also sort your results, ascending or descending, by 1 field.

    Advanced allows you to perform the (almost) complete set of operations that ServiceNow has.
    The comparison operators have been made to mimic powershell itself so the code should be easy to understand.
    You can use a very large set of comparison operators (see the script variable ServiceNowOperator),
    and, or, and grouping joins, as well as multiple sorting parameters.

.PARAMETER Filter
    Array or multidimensional array of fields and values to filter on.
    Each array should be of the format @(field, comparison operator, value) separated by a join, either 'and', 'or', or 'group'.
    For a complete list of comparison operators, see $script:ServiceNowOperator and use Name in your filter.
    See the examples.
    Also, see https://docs.servicenow.com/bundle/quebec-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html
    for how to represent dates.

.PARAMETER Sort
    Array or multidimensional array of fields to sort on.
    Each array should be of the format @(field, asc/desc).

.EXAMPLE
    New-ServiceNowQuery -MatchExact @{field_name=value}
    Get query string where field name exactly matches the value

.EXAMPLE
    New-ServiceNowQuery -MatchContains @{field_name=value}
    Get query string where field name contains the value

.EXAMPLE
    New-ServiceNowQuery -Filter @('state', '-eq', '1'), 'or', @('short_description','-like', 'powershell')
    Get query string where state equals New or short description contains the word powershell

.EXAMPLE
    $filter = @('state', '-eq', '1'),
                'and',
              @('short_description','-like', 'powershell'),
              'group',
              @('state', '-eq', '2')
    PS > New-ServiceNowQuery -Filter $filter
    Get query string where state equals New and short description contains the word powershell or state equals In Progress.
    The first 2 filters are combined and then or'd against the last.

.EXAMPLE
    New-ServiceNowQuery -Filter @('state', '-eq', '1') -Sort @('opened_at', 'desc'), @('state')
    Get query string where state equals New and first sort by the field opened_at descending and then sort by the field state ascending

.EXAMPLE
    New-ServiceNowQuery -Filter @('opened_at', '-ge', 'javascript:gs.daysAgoEnd(30)')
    Get query string where the record was opened in the last 30 days

.INPUTS
    None

.OUTPUTS
    String
#>
function New-ServiceNowQuery {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'No state is actually changing')]

    [CmdletBinding()]
    [OutputType([System.String])]

    param(
        # Machine name of the field to order by
        [parameter(ParameterSetName = 'Basic')]
        [string] $OrderBy = 'opened_at',

        # Direction of ordering (Desc/Asc)
        [parameter(ParameterSetName = 'Basic')]
        [ValidateSet("Desc", "Asc")]
        [string] $OrderDirection = 'Desc',

        # Hashtable containing machine field names and values returned must match exactly (will be combined with AND)
        [parameter(ParameterSetName = 'Basic')]
        [hashtable] $MatchExact,

        # Hashtable containing machine field names and values returned rows must contain (will be combined with AND)
        [parameter(ParameterSetName = 'Basic')]
        [hashtable] $MatchContains,

        [parameter(ParameterSetName = 'Advanced')]
        [System.Collections.ArrayList] $Filter,

        [parameter(ParameterSetName = 'Advanced')]
        [System.Collections.ArrayList] $Sort

    )

    Write-Verbose ('{0} - {1}' -f $MyInvocation.MyCommand, $PSCmdlet.ParameterSetName)

    if ( $PSCmdlet.ParameterSetName -eq 'Advanced' ) {
        if ( $Filter ) {
            $filterList = $Filter
            # see if we're working with 1 array or multidimensional array
            # we want multidimensional so convert if not
            if ($Filter[0].GetType().Name -eq 'String') {
                $filterList = @(, $Filter)
            }

            $query = for ($i = 0; $i -lt $filterList.Count; $i++) {
                $thisFilter = $filterList[$i]

                # allow passing of string instead of array
                # useful for joins
                if ($thisFilter.GetType().Name -eq 'String') {
                    $thisFilter = @(, $thisFilter)
                }

                switch ($thisFilter.Count) {
                    0 {
                        # nothing to see here
                        Continue
                    }

                    1 {
                        # should be a join

                        switch ($thisFilter[0]) {
                            { $_ -in 'and', '-and' } {
                                '^'
                            }

                            { $_ -in 'or', '-or' } {
                                '^OR'
                            }

                            { $_ -in 'group', '-group' } {
                                '^NQ'
                            }

                            Default {
                                throw "Unsupported join operator '$($thisFilter[0])'.  'and', 'or', and 'group' are supported."
                            }
                        }

                        # make sure we don't end on a join
                        if ( $i -eq $filterList.Count - 1) {
                            throw '$Filter cannot end with a join'
                        }

                        break
                    }

                    { $_ -ne 1 } {
                        # perform data validation on all filters other than a join operator
                        $thisOperator = $script:ServiceNowOperator | Where-Object { $_.Name -eq $thisFilter[1] }
                        if ( -not $thisOperator ) {
                            throw ('Operator ''{0}'' is not valid' -f $thisFilter[1])
                        }
                        if ( $thisOperator.NumValues -ne $thisFilter.Count - 2 ) {
                            throw ('Operator ''{0}'' requires 1 field name and {1} value(s)' -f $thisFilter[1], $thisOperator.NumValues)
                        }
                    }

                    2 {
                        # should be a non-value operator, eg. ='' / ISEMPTY
                        '{0}{1}' -f $thisFilter[0], $thisOperator.QueryOperator
                        break
                    }

                    3 {
                        # should be format - field operator value

                        if ( $thisFilter[2] -is [DateTime] ) {
                            $dateGen = "'{0}','{1}'" -f $thisFilter[2].ToString('yyyy-MM-dd'), $thisFilter[2].ToString('HH:mm:ss')
                            '{0}{1}javascript:gs.dateGenerate({2})' -f $thisFilter[0], $thisOperator.QueryOperator, $dateGen
                        }
                        else {
                            '{0}{1}{2}' -f $thisFilter[0], $thisOperator.QueryOperator, $thisFilter[2]
                        }

                        break
                    }

                    4 {
                        # should be format - field operator value1 value2, where applicable, eg. between

                        if ( $thisFilter[2] -is [DateTime] ) {
                            $dateGen1 = "'{0}','{1}'" -f $thisFilter[2].ToString('yyyy-MM-dd'), $thisFilter[2].ToString('HH:mm:ss')
                            $dateGen2 = "'{0}','{1}'" -f $thisFilter[3].ToString('yyyy-MM-dd'), $thisFilter[3].ToString('HH:mm:ss')
                            '{0}{1}javascript:gs.dateGenerate({2})@javascript:gs.dateGenerate({3})' -f $thisFilter[0], $thisOperator.QueryOperator, $dateGen1, $dateGen2
                        }
                        else {
                            '{0}{1}{2}@{3}' -f $thisFilter[0], $thisOperator.QueryOperator, $thisFilter[2], $thisFilter[3]
                        }

                        break
                    }

                    Default {
                        throw ('Too many filter items for {0}, see the help' -f $thisFilter[0])
                    }
                }
            }
        }

        # force query to an array in case we only got one item and its a string
        # otherwise below add to query won't work as expected
        $query = @($query)

        if ($query) {
            $query += '^'
        }

        $orderList = $Sort

        if ( $Sort ) {
            # see if we're working with 1 array or multidimensional array
            # we want multidimensional so convert if not
            if ($Sort[0].GetType().Name -eq 'String') {
                $orderList = @(, $Sort)
            }
        }

        $query += for ($i = 0; $i -lt $orderList.Count; $i++) {
            $thisOrder = $orderList[$i]
            if ( $orderList.Count -gt 1 -and $i -gt 0 ) {
                '^'
            }

            switch ($thisOrder.Count) {
                0 {
                    # nothing to see here
                    Continue
                }

                1 {
                    # should be field, default to ascending
                    'ORDERBY'
                    $thisOrder[0]
                }

                2 {
                    switch ($thisOrder[1]) {
                        'asc' {
                            'ORDERBY'
                        }

                        'desc' {
                            'ORDERBYDESC'
                        }

                        Default {
                            throw "Invalid order direction '$_'.  Provide either 'asc' or 'desc'."
                        }
                    }
                    $thisOrder[0]
                }

                Default {
                    throw ('Too many items for {0}, see the help' -f $thisOrder[0])
                }
            }
        }

        ($query -join '').Trim('^')

    }
    else {
        # Basic parameter set

        # Create StringBuilder
        $Query = New-Object System.Text.StringBuilder

        # Start the query off with a order direction
        $direction = Switch ($OrderDirection) {
            'Asc' { 'ORDERBY'; break }
            Default { 'ORDERBYDESC' }
        }
        [void]$Query.Append($direction)

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
}