#Requires -Version 3.0
[cmdletbinding()]
param()

Write-Verbose $PSScriptRoot

Write-Verbose 'Import everything in sub folders folder'
foreach($Folder in @('Private', 'Public'))
{
    $Root = Join-Path -Path $PSScriptRoot -ChildPath $Folder
    if(Test-Path -Path $Root)
    {
        Write-Verbose "processing folder $Root"
        $Files = Get-ChildItem -Path $Root -Filter *.ps1 -Recurse

        # dot source each file
        $Files | Where-Object{ $_.name -NotLike '*.Tests.ps1'} | 
             ForEach-Object {Write-Verbose $_.basename; . $PSItem.FullName}
    }
}

Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1").BaseName