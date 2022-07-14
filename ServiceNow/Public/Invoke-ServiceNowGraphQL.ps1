<#
.SYNOPSIS
    Retrieve or update data via GraphQL - still a work in progress :)

.DESCRIPTION
    Retrieve or update data via GraphQL.
    Ensure you create a new session with -GraphQL.

.PARAMETER Operation
    Allowed values are 'query' or 'mutation'.
    The default is query.

.PARAMETER Application
    Application namespace for your API

.PARAMETER Schema
    Schema namespace for your API

.PARAMETER Query
    Inner query string.  Operation, application, and schema will be added automatically.

.PARAMETER Variable
    Currently only supported with -Raw.
    Ensure the query includes the operation, application, and schema.

.PARAMETER Raw
    Provide the server response as is instead of parsing out the application, schema, and service names.

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    Invoke-ServiceNowGraphQL -Application myapp -Schema incident -Query 'findById (id: "INC0010001") {sys_id {value} description {value}}'

    Perform a query

.OUTPUTS
    PSCustomObject

.LINK
    https://docs.servicenow.com/bundle/sandiego-application-development/page/integrate/graphql/concept/scripted-graph-ql.html
#>
function Invoke-ServiceNowGraphQL {

    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]

    Param (
        [Parameter()]
        [ValidateSet('query', 'mutation')]
        [string] $Operation = 'query',

        [Parameter(Mandatory)]
        [string] $Application,

        [Parameter(Mandatory)]
        [string] $Schema,

        [Parameter(Mandatory)]
        [string] $Query,

        [Parameter()]
        [string] $Variable,

        [Parameter()]
        [switch] $Raw,

        [Parameter()]
        [hashtable] $Connection,

        [Parameter()]
        [hashtable] $ServiceNowSession = $script:ServiceNowSession
    )

    begin {

        Write-Warning 'This function is in beta and subject to change.  Please please feedback/enhancements at https://github.com/Snow-Shell/servicenow-powershell/issues.'

        if ( $Raw ) {
            $fullQuery = $Query
        } else {
            $fullQuery = ('{0} {{ {1} {{ {2} {{ {3} }}}}}}' -f $Operation, $Application, $Schema, $Query)
        }

        $params = Get-ServiceNowAuth -C $Connection -S $ServiceNowSession

        $params.Method = 'Post'
        $params.ContentType = 'application/json'
        $params.UseBasicParsing = $true

        $body = @{
            'query' = $fullQuery
        }

        if ( $Variable ) {
            $body.variables = $Variable
        }

        $params.Body = $body | ConvertTo-Json -Compress
    }

    process {
        Write-Verbose ($params | ConvertTo-Json)
        $result = Invoke-RestMethod @params

        if ( $Raw ) {
            $result
        } else {
            $serviceName = $Query -replace '^(\w*).*', '$1'
            if ( $result.data.$Application.$Schema.$serviceName ) {
                $result.data.$Application.$Schema.$serviceName
            }
        }
    }
}
