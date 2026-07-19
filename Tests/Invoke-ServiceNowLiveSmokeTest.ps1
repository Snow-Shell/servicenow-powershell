<#
.SYNOPSIS
    Exercise every public function of the ServiceNow module against a real, live instance.

.DESCRIPTION
    This is NOT a Pester test and is never auto-discovered by `Invoke-Pester` (it does not match
    *.Tests.ps1), so it will never run in CI and can't hang a normal test run.

    It is meant to be run interactively, by hand, against a dev/sub-production instance
    (an instance where it's safe to create and delete a handful of throwaway records).
    It authenticates once via New-ServiceNowSession and then walks through every public
    function in the module, creating and cleaning up its own test data as it goes.

    Each step is isolated - a failure in one step is reported and the script moves on to the
    next so you get a full picture of what works and what doesn't in one run. All records this
    script creates are tracked and removed in a `finally` block at the end, even if the script
    is interrupted (Ctrl+C) or a step throws.

.PARAMETER Url
    ServiceNow instance domain, eg. dev12345.service-now.com

.PARAMETER Credential
    Basic auth credential. If not supplied you will be prompted securely.

.PARAMETER GraphQLApplication
    Application namespace for a Scripted GraphQL API you've already configured on your instance.
    The GraphQL API is a "bring your own schema" feature (see the .LINK) - there is no generic
    built-in schema, so this step is skipped by default unless you provide Application, Schema,
    and Query for a Scripted GraphQL API you control.

.PARAMETER GraphQLSchema
    Schema namespace matching -GraphQLApplication.

.PARAMETER GraphQLQuery
    Inner query string matching -GraphQLApplication/-GraphQLSchema, eg.
    'findById (id: "INC0010001") {sys_id {value}}'

.PARAMETER SkipCatalog
    Skip the service catalog cart steps (Get-ServiceNowCart, New-ServiceNowCartItem,
    Remove-ServiceNowCartItem, Submit-ServiceNowCart). Use this if your instance has no
    active catalog items available to order.

.EXAMPLE
    ./Tests/Invoke-ServiceNowLiveSmokeTest.ps1 -Url dev409606.service-now.com

.EXAMPLE
    ./Tests/Invoke-ServiceNowLiveSmokeTest.ps1 -Url dev409606.service-now.com -Credential $cred -GraphQLApplication myapp -GraphQLSchema incident -GraphQLQuery 'findById (id: "INC0010001") {sys_id {value}}'

.LINK
    https://docs.servicenow.com/bundle/sandiego-application-development/page/integrate/graphql/concept/scripted-graph-ql.html
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Url,

    [Parameter()]
    [PSCredential] $Credential,

    [Parameter()]
    [string] $GraphQLApplication,

    [Parameter()]
    [string] $GraphQLSchema,

    [Parameter()]
    [string] $GraphQLQuery,

    [Parameter()]
    [switch] $SkipCatalog
)

$ProjectRoot = Resolve-Path "$PSScriptRoot/.."
$ModulePsd = (Resolve-Path "$ProjectRoot/ServiceNow/ServiceNow.psd1").Path

Get-Module 'ServiceNow' | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $ModulePsd -Force

if (-not $Credential) {
    $Credential = Get-Credential -Message "Credentials for $Url"
}

# results + cleanup tracking
$script:Results = [System.Collections.Generic.List[pscustomobject]]::new()
$script:CleanupActions = [System.Collections.Generic.List[scriptblock]]::new()

function Invoke-SmokeStep {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Test,
        [switch] $Skip,
        [string] $SkipReason
    )

    if ($Skip) {
        Write-Host "[SKIP] $Name $(if ($SkipReason) { "- $SkipReason" })" -ForegroundColor Yellow
        $script:Results.Add([pscustomobject]@{ Name = $Name; Status = 'SKIP'; Detail = $SkipReason })
        return $null
    }

    try {
        $result = & $Test
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $script:Results.Add([pscustomobject]@{ Name = $Name; Status = 'PASS'; Detail = $null })
        return $result
    }
    catch {
        Write-Host "[FAIL] $Name - $($_.Exception.Message)" -ForegroundColor Red
        $script:Results.Add([pscustomobject]@{ Name = $Name; Status = 'FAIL'; Detail = $_.Exception.Message })
        return $null
    }
}

try {

    # ------------------------------------------------------------------
    # Session / auth
    #
    # Deliberately NOT using -PassThru here: PassThru returns the session object without
    # setting it as the module's default ($script:ServiceNowSession), which every other
    # function falls back to. We want that default set so the rest of this script (and any
    # ad-hoc commands you run afterward in the same shell) can call functions without having
    # to pass -ServiceNowSession explicitly every time.
    # ------------------------------------------------------------------
    Invoke-SmokeStep -Name 'New-ServiceNowSession' -Test {
        New-ServiceNowSession -Url $Url -Credential $Credential
    } | Out-Null

    $snowModule = Get-Module 'ServiceNow'
    if (-not (& $snowModule { $script:ServiceNowSession })) {
        throw 'Unable to establish a session, aborting remaining tests.'
    }

    # ------------------------------------------------------------------
    # New-ServiceNowQuery / Get-ServiceNowRecord (read-only)
    # ------------------------------------------------------------------
    Invoke-SmokeStep -Name 'New-ServiceNowQuery' -Test {
        $query = New-ServiceNowQuery -Filter @('active', '-eq', 'true')
        if ($query -ne 'active=true') { throw "Unexpected query string '$query'" }
    }

    Invoke-SmokeStep -Name 'Get-ServiceNowRecord (Table + Filter)' -Test {
        $null = Get-ServiceNowRecord -Table incident -Filter @('active', '-eq', 'true') -First 5
    }

    # ------------------------------------------------------------------
    # New-ServiceNowRecord / New-ServiceNowIncident (writes)
    # ------------------------------------------------------------------
    $incident = Invoke-SmokeStep -Name 'New-ServiceNowIncident' -Test {
        New-ServiceNowIncident -Caller $Credential.UserName -ShortDescription 'Live smoke test incident' -Description 'Created by Invoke-ServiceNowLiveSmokeTest.ps1' -PassThru
    }
    if ($incident) {
        $script:CleanupActions.Add({ Remove-ServiceNowRecord -Table incident -ID $incident.sys_id -Confirm:$false -ErrorAction SilentlyContinue }.GetNewClosure())
    }

    Invoke-SmokeStep -Name 'New-ServiceNowRecord (generic table)' -Test {
        $rec = New-ServiceNowRecord -Table incident -InputData @{ short_description = 'Live smoke test - generic record' } -PassThru
        $script:CleanupActions.Add({ Remove-ServiceNowRecord -Table incident -ID $rec.sys_id -Confirm:$false -ErrorAction SilentlyContinue }.GetNewClosure())
    }

    # ------------------------------------------------------------------
    # Update / Get by ID
    # ------------------------------------------------------------------
    Invoke-SmokeStep -Name 'Update-ServiceNowRecord' -Skip:(-not $incident) -SkipReason 'no incident created' -Test {
        Update-ServiceNowRecord -Table incident -ID $incident.sys_id -InputData @{ description = 'Updated by smoke test' } -Confirm:$false
    }

    Invoke-SmokeStep -Name 'Get-ServiceNowRecord (by ID)' -Skip:(-not $incident) -SkipReason 'no incident created' -Test {
        # a raw sys_id requires -Table; only numbered ids (eg. INC0010001) can auto-resolve the table
        $fetched = Get-ServiceNowRecord -Table incident -ID $incident.sys_id
        if (-not $fetched) { throw 'Record not found by sys_id' }
    }

    # ------------------------------------------------------------------
    # Attachments
    # ------------------------------------------------------------------
    $attachmentFile = Join-Path ([System.IO.Path]::GetTempPath()) 'smoke-test-attachment.txt'
    'live smoke test attachment content' | Set-Content -Path $attachmentFile

    $attachment = Invoke-SmokeStep -Name 'Add-ServiceNowAttachment' -Skip:(-not $incident) -SkipReason 'no incident created' -Test {
        Add-ServiceNowAttachment -Table incident -ID $incident.sys_id -File $attachmentFile -PassThru
    }

    Invoke-SmokeStep -Name 'Get-ServiceNowAttachment' -Skip:(-not $incident) -SkipReason 'no incident created' -Test {
        $atts = Get-ServiceNowAttachment -Table incident -ID $incident.sys_id
        if (-not $atts) { throw 'No attachments returned' }
    }

    $exportDir = Join-Path ([System.IO.Path]::GetTempPath()) ('smoke-test-export-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $exportDir | Out-Null

    Invoke-SmokeStep -Name 'Export-ServiceNowAttachment' -Skip:(-not $attachment) -SkipReason 'no attachment created' -Test {
        Export-ServiceNowAttachment -ID $attachment.sys_id -FileName 'downloaded.txt' -Destination $exportDir
        if (-not (Test-Path (Join-Path $exportDir 'downloaded.txt'))) { throw 'Downloaded file not found' }
    }

    Invoke-SmokeStep -Name 'Remove-ServiceNowAttachment' -Skip:(-not $attachment) -SkipReason 'no attachment created' -Test {
        Remove-ServiceNowAttachment -SysID $attachment.sys_id -Confirm:$false
    }

    # ------------------------------------------------------------------
    # Export-ServiceNowRecord
    # ------------------------------------------------------------------
    Invoke-SmokeStep -Name 'Export-ServiceNowRecord' -Skip:(-not $incident) -SkipReason 'no incident created' -Test {
        # a raw sys_id requires -Table; only numbered ids (eg. INC0010001) can auto-resolve the table
        $exportPath = Join-Path $exportDir 'incident.csv'
        Export-ServiceNowRecord -Table incident -ID $incident.sys_id -Path $exportPath
        if (-not (Test-Path $exportPath)) { throw 'Export file not found' }
    }

    # ------------------------------------------------------------------
    # Change request / change task
    # ------------------------------------------------------------------
    $changeRequest = Invoke-SmokeStep -Name 'New-ServiceNowChangeRequest' -Test {
        New-ServiceNowChangeRequest -ShortDescription 'Live smoke test change' -Description 'Created by Invoke-ServiceNowLiveSmokeTest.ps1' -PassThru
    }
    if ($changeRequest) {
        $script:CleanupActions.Add({ Remove-ServiceNowRecord -Table change_request -ID $changeRequest.sys_id -Confirm:$false -ErrorAction SilentlyContinue }.GetNewClosure())
    }

    $changeTask = Invoke-SmokeStep -Name 'New-ServiceNowChangeTask' -Skip:(-not $changeRequest) -SkipReason 'no change request created' -Test {
        New-ServiceNowChangeTask -ChangeRequest $changeRequest.sys_id -ShortDescription 'Live smoke test change task' -Description 'Created by Invoke-ServiceNowLiveSmokeTest.ps1' -PassThru
    }
    if ($changeTask) {
        $script:CleanupActions.Add({ Remove-ServiceNowRecord -Table change_task -ID $changeTask.sys_id -Confirm:$false -ErrorAction SilentlyContinue }.GetNewClosure())
    }

    # ------------------------------------------------------------------
    # Configuration item
    # ------------------------------------------------------------------
    $configItem = Invoke-SmokeStep -Name 'New-ServiceNowConfigurationItem' -Test {
        New-ServiceNowConfigurationItem -Name ('Live Smoke Test CI ' + [guid]::NewGuid()) -Class 'cmdb_ci' -PassThru
    }
    if ($configItem) {
        $script:CleanupActions.Add({ Remove-ServiceNowRecord -Table cmdb_ci -ID $configItem.sys_id -Confirm:$false -ErrorAction SilentlyContinue }.GetNewClosure())
    }

    # ------------------------------------------------------------------
    # Remove-ServiceNowRecord (explicit, dedicated record so we validate the function itself)
    # ------------------------------------------------------------------
    Invoke-SmokeStep -Name 'Remove-ServiceNowRecord' -Test {
        $toRemove = New-ServiceNowRecord -Table incident -InputData @{ short_description = 'Live smoke test - to be removed' } -PassThru
        Remove-ServiceNowRecord -Table incident -ID $toRemove.sys_id -Confirm:$false
        $stillThere = Get-ServiceNowRecord -Table incident -Filter @('sys_id', '-eq', $toRemove.sys_id)
        if ($stillThere) { throw 'Record still exists after removal' }
    }

    # ------------------------------------------------------------------
    # Service catalog cart lifecycle
    #
    # Not every catalog item can be ordered without additional input (some require mandatory
    # variables to be supplied). Rather than fail the whole cart lifecycle on an item that
    # happens to need extra input, sample a handful of active items and use the first one that
    # can be added with no extra values. This also naturally exercises New-ServiceNowCartItem.
    # ------------------------------------------------------------------
    $orderableCatalogItem = if (-not $SkipCatalog) {
        Invoke-SmokeStep -Name 'New-ServiceNowCartItem (find + add an orderable item)' -Test {
            $candidates = Get-ServiceNowRecord -Table sc_cat_item -Filter @('active', '-eq', 'true') -First 10
            if (-not $candidates) { throw 'No active catalog items found on this instance' }

            $found = $null
            foreach ($candidate in $candidates) {
                try {
                    New-ServiceNowCartItem -CatalogItem $candidate.sys_id -Confirm:$false -ErrorAction Stop
                    $found = $candidate
                    break
                }
                catch {
                    Write-Verbose "Catalog item '$($candidate.sys_id)' requires additional input and was skipped: $($_.Exception.Message)"
                }
            }

            if (-not $found) {
                throw ('None of the {0} sampled catalog items could be added to the cart without additional mandatory variables.' -f $candidates.Count)
            }

            $found
        }
    }

    Invoke-SmokeStep -Name 'Get-ServiceNowCart' -Skip:($SkipCatalog -or -not $orderableCatalogItem) -SkipReason 'catalog skipped or no orderable catalog item found' -Test {
        $cart = Get-ServiceNowCart
        if (-not $cart) { throw 'Cart is empty after adding an item' }
    }

    Invoke-SmokeStep -Name 'Remove-ServiceNowCartItem (empty cart)' -Skip:($SkipCatalog -or -not $orderableCatalogItem) -SkipReason 'catalog skipped or no orderable catalog item found' -Test {
        Remove-ServiceNowCartItem -All -Confirm:$false
    }

    Invoke-SmokeStep -Name 'Submit-ServiceNowCart' -Skip:($SkipCatalog -or -not $orderableCatalogItem) -SkipReason 'catalog skipped or no orderable catalog item found' -Test {
        New-ServiceNowCartItem -CatalogItem $orderableCatalogItem.sys_id -Confirm:$false
        $order = Submit-ServiceNowCart -PassThru -Confirm:$false
        if ($order.request_id) {
            $script:CleanupActions.Add({ Remove-ServiceNowRecord -Table sc_request -ID $order.request_id -Confirm:$false -ErrorAction SilentlyContinue }.GetNewClosure())
        }
    }

    # ------------------------------------------------------------------
    # GraphQL - "bring your own schema". There is no generic built-in GraphQL schema on a vanilla
    # instance, so this only runs if you've supplied Application/Schema/Query for a Scripted
    # GraphQL API you've already set up.
    # ------------------------------------------------------------------
    $graphQLConfigured = $GraphQLApplication -and $GraphQLSchema -and $GraphQLQuery
    Invoke-SmokeStep -Name 'Invoke-ServiceNowGraphQL' -Skip:(-not $graphQLConfigured) -SkipReason 'no -GraphQLApplication/-GraphQLSchema/-GraphQLQuery provided (requires a Scripted GraphQL API already configured on your instance)' -Test {
        Invoke-ServiceNowGraphQL -Application $GraphQLApplication -Schema $GraphQLSchema -Query $GraphQLQuery
    }

}
finally {
    if ($script:CleanupActions.Count -gt 0) {
        Write-Host "`nCleaning up $($script:CleanupActions.Count) test record(s)..." -ForegroundColor Cyan
        # clean up in reverse (LIFO) order - eg. remove a change task before its parent change
        # request, since removing a parent can cascade-delete children on some instances and
        # leave the later, now-stale cleanup action to harmlessly 404
        for ($i = $script:CleanupActions.Count - 1; $i -ge 0; $i--) {
            try { & $script:CleanupActions[$i] }
            catch {
                if ($_.Exception.Message -match '404') {
                    Write-Verbose "  already removed (404), skipping: $($_.Exception.Message)"
                }
                else {
                    Write-Host "  cleanup warning: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
    }
    if (Test-Path Variable:exportDir) {
        Remove-Item -Path $exportDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path Variable:attachmentFile) {
        Remove-Item -Path $attachmentFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n===== Summary =====" -ForegroundColor Cyan
$script:Results | Format-Table -AutoSize

$failed = $script:Results | Where-Object { $_.Status -eq 'FAIL' }
$passed = $script:Results | Where-Object { $_.Status -eq 'PASS' }
$skipped = $script:Results | Where-Object { $_.Status -eq 'SKIP' }
Write-Host "Passed: $($passed.Count)  Failed: $($failed.Count)  Skipped: $($skipped.Count)" -ForegroundColor $(if ($failed.Count) { 'Red' } else { 'Green' })

if ($failed.Count -gt 0) {
    exit 1
}
