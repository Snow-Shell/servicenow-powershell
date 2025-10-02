<#
.SYNOPSIS
    Submit a catalog request using Service Catalog API

.DESCRIPTION
    Create a new catalog item request using Service Catalog API. Reference: https://www.servicenow.com/community/itsm-articles/submit-catalog-request-using-service-catalog-api/ta-p/2305836

.PARAMETER CatalogItemName
    Name of the catalog item that will be created

.PARAMETER CatalogItemID
    SysID of the catalog item that will be created

.PARAMETER Variables
    Key/value pairs of variable names and their values

.PARAMETER PassThru
    If provided, the new record will be returned

.PARAMETER Connection
    Azure Automation Connection object containing username, password, and URL for the ServiceNow instance

.PARAMETER ServiceNowSession
    ServiceNow session created by New-ServiceNowSession.  Will default to script-level variable $ServiceNowSession.

.EXAMPLE
    New-ServiceNowRecord -CatalogItemName "Standard Laptop" -Variables @{'acrobat' = 'true'; 'photoshop' = 'true'; ' Additional_software_requirements' = 'Testing Service catalog API' }

    Raise a new catalog request using Item Name

.EXAMPLE
    New-ServiceNowRecord -CatalogItemID "04b7e94b4f7b42000086eeed18110c7fd" -Variables @{'acrobat' = 'true'; 'photoshop' = 'true'; ' Additional_software_requirements' = 'Testing Service catalog API' }

    Raise a new catalog request using Item ID

.INPUTS
    InputData

.OUTPUTS
    PSCustomObject if PassThru provided
#>
function New-ServiceNowCatalogItem {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ID')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]$CatalogItemName,
        [Parameter(Mandatory, ParameterSetName = 'ID')]
        [string]$CatalogItemID,
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ParameterSetName = 'ID')]
        [Alias('Variables')]
        [hashtable]$InputData,
        [Parameter()][Hashtable]$Connection,
        [Parameter()][hashtable]$ServiceNowSession = $script:ServiceNowSession,
        [Parameter()][switch]$PassThru
    )

    begin {
        if ($CatalogItemName) {
            #Lookup the sys_id of the Catalog Item name
            $CatalogItemID = (Get-ServiceNowRecord -Table sc_cat_item -AsValue -Filter @('name', '-eq', $CatalogItemName )).sys_id
            if ([string]::IsNullOrEmpty($CatalogItemID)) { throw "Unable to find catalog item by name '$($catalogitemname)'" } else { Write-Verbose "Found $($catalogitemid) via lookup from '$($CatalogItemName)'" }
        }
    }
    process {

        $AddItemToCart = @{
            Method            = 'Post'
            UriLeaf           = "/servicecatalog/items/{0}/add_to_cart" -f $CatalogItemID
            Values            = @{'sysparm_quantity' = 1; 'variables' = $InputData }
            Namespace         = 'sn_sc'
            Connection        = $Connection
            ServiceNowSession = $ServiceNowSession
        }

        if ( $PSCmdlet.ShouldProcess($CatalogItemID, 'Create new catalog item request') ) {

            $AddItemCartResponse = Invoke-ServiceNowRestMethod @AddItemToCart

            if ($AddItemCartResponse.cart_id) {
                $SubmitOrder = @{
                    Method            = 'Post'
                    UriLeaf           = "/servicecatalog/cart/submit_order"
                    Namespace         = 'sn_sc'
                    Connection        = $Connection
                    ServiceNowSession = $ServiceNowSession
                }

                $SubmitOrderResponse = Invoke-ServiceNowRestMethod @SubmitOrder
            }
            if ( $PassThru ) {
                $SubmitOrderResponse
            }
        }
    }
}
