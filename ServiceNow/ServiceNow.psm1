[cmdletbinding()]
param()

Write-Verbose $PSScriptRoot

$config = ConvertFrom-Json (Get-Content "$PSScriptRoot\config\main.json" -Raw)
$Script:ServiceNowOperator = $config.FilterOperators
[System.Collections.ArrayList] $script:ServiceNowTable = $config.Tables

Export-ModuleMember -Variable ServiceNowOperator, ServiceNowTable

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
