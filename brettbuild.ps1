[cmdletbinding()]
param (
    $SourcePath,
    $OutputFolder = 'output'
)

# Get the module manifest information
$moduleManifest = Get-ChildItem -Path $SourcePath -Filter *.psd1

# Convert the manifest to a usable psobject
$manifestInfo = Import-PowerShellDataFile -Path $moduleManifest.FullName

# Set the paths for
$destinationPath = Join-Path -Path $SourcePath -ChildPath $OutputFolder
$destinationModule = Join-Path -Path $destinationPath -ChildPath $manifestInfo.RootModule
$formatsFile = $manifestInfo.FormatsToProcess

$publicFunctions = Get-ChildItem -Path $SourcePath -Include 'Public' -Recurse |
    Get-ChildItem -Filter *.ps1


# Remove out directory to allow rebuilding
if (Test-Path -Path $destinationPath) {
    Remove-Item -Path $destinationPath -Force -Confirm:$false -Recurse
}

# Create the new output directory
$null = New-Item -ItemType Directory -Name $OutputFolder -Path $SourcePath

# Get the content of the manifest and add the public functions to be exported
$manifestContent = Get-Content $moduleManifest.FullName
$null = $manifestContent -replace "^(#? ?FunctionsToExport = )((@\(\))*|'[*]')$",
    ("FunctionsToExport = @({1}    '{0}'{1})" -f ($publicFunctions.BaseName -join "',`r`n    '"), [System.Environment]::NewLine) |
        Set-Content -Path (Join-Path -Path $destinationPath -ChildPath $moduleManifest.Name)

# Copy all functions to a single psm1 file
Get-ChildItem -Path $SourcePath -Recurse -Include *.ps1 -Exclude build.ps1 | ForEach-Object {
    "Adding {0} to the psm1 file" -f $_.BaseName | Write-Verbose
    Get-Content -Path $_.FullName | Add-Content -Path $destinationModule
    "" | Add-Content -Path $destinationModule
}

Copy-Item -Path $SourcePath\$formatsFile -Destination $destinationPath