[cmdletbinding()]
param()

Write-Verbose $PSScriptRoot

$config = ConvertFrom-Json (Get-Content "$PSScriptRoot\config\main.json" -Raw)
$Script:ServiceNowOperator = $config.FilterOperators
[System.Collections.ArrayList] $script:ServiceNowTable = $config.Tables

Export-ModuleMember -Variable ServiceNowOperator, ServiceNowTable

$script:catalogItems = [System.Collections.Generic.List[object]]::new()

$tableLookupArgCompleterSb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    switch ($parameterName) {
        'CatalogItem' {
            if ( $script:catalogItems.Count -eq 0 ) {
                $allItems = Get-ServiceNowRecord -Table sc_cat_item -Property sys_id, name, short_description -IncludeTotalCount -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -ServiceNowSession $script:ServiceNowSession
                $script:catalogItems.AddRange($allItems)
            }

            $out = $script:catalogItems
            if ( $wordToComplete ) {
                $out = $script:catalogItems | Where-Object {
                    ($_.sys_id -like ('{0}*' -f $wordToComplete.Trim("'"))) -or
                    ($_.name -like ('{0}*' -f $wordToComplete.Trim("'")))
                }
            }
            $out | ForEach-Object {
                $itemText = "'{0}'" -f $_.name
                $itemDescription = if ($_.short_description) { $_.short_description } else { ' ' }
                [System.Management.Automation.CompletionResult]::new($itemText, $_.name, 'ParameterValue', $itemDescription)
            }
        }
    }
}

Register-ArgumentCompleter -CommandName 'New-ServiceNowCartItem' -ParameterName 'CatalogItem' -ScriptBlock $tableLookupArgCompleterSb


$script:tableField = @{}

$propSb = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $t = $fakeBoundParameters.Table

    if ( $t ) {
        if ( -not $script:tableField.$t) {
            # first time with this table
            $tableItem = Get-ServiceNowRecord -Table $t -First 1
            $properties = $tableItem.psobject.Properties | Select-Object Name, TypeNameOfValue, Value
            $script:tableField.Add($t, $properties)
        }

        $script:tableField.$t | Where-Object { $_ -like ('{0}*' -f $wordToComplete.Trim("'")) } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', ('{0}, ex: {1}' -f $_.TypeNameOfValue, $_.Value))
        }
    }
}

Register-ArgumentCompleter -CommandName 'Get-ServiceNowRecord' -ParameterName 'Property' -ScriptBlock $propSb

$tableArgCompleterSb = {
    $ServiceNowTable | ForEach-Object {
        if ( $_.ClassName ) {
            '''{0}''' -f $_.ClassName
        }
        else {
            '''{0}''' -f $_.Name
        }
    }
}

# assign the table arg completer to functions
@(
    'Get-ServiceNowRecord',
    'Get-ServiceNowAttachment',
    'Add-ServiceNowAttachment',
    'New-ServiceNowRecord',
    'Update-ServiceNowRecord',
    'Remove-ServiceNowRecord',
    'Export-ServiceNowRecord'
) | ForEach-Object {
    Register-ArgumentCompleter -CommandName $_ -ParameterName 'Table' -ScriptBlock $tableArgCompleterSb
}

Write-Verbose 'Import everything in sub folders folder'
foreach ($Folder in @('Private', 'Public')) {
    $Root = Join-Path -Path $PSScriptRoot -ChildPath $Folder
    if (Test-Path -Path $Root) {
        Write-Verbose "processing folder $Root"
        $Files = Get-ChildItem -Path $Root -Filter *.ps1 -Recurse

        # dot source each file
        $Files | Where-Object { $_.name -NotLike '*.Tests.ps1' } |
        ForEach-Object { Write-Verbose $_.basename; . $PSItem.FullName }
    }
}

Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1").BaseName

$Script:ServiceNowSession = @{}
Export-ModuleMember -Variable ServiceNowSession

$aliases = @{
    'gsnr' = 'Get-ServiceNowRecord'
}
$aliases.GetEnumerator() | ForEach-Object {
    Set-Alias -Name $_.Key -Value $_.Value
}
Export-ModuleMember -Alias *
