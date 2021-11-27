
@{

# Script module or binary module file associated with this manifest.
RootModule = 'ServiceNow.psm1'

# Version number of this module.
ModuleVersion = '3.1.3'

# ID used to uniquely identify this module
GUID = 'b90d67da-f8d0-4406-ad74-89d169cd0633'

# Author of this module
Author = 'Sam Martin', 'Rick Arroues', 'Greg Brownstein'

# Company or vendor of this module
CompanyName = 'None'

# Copyright statement for this module
Copyright = '(c) 2015-2021 Snow-Shell. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Automate against ServiceNow service and asset management.  This module can be used standalone or with Azure Automation.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = 'None'

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @('ServiceNow.format.ps1xml')

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @()

# Functions to export from this module
    FunctionsToExport = @('Get-ServiceNowRecordInterim','New-ServiceNowConfigurationItem','Get-ServiceNowRecord','New-ServiceNowSession','Add-ServiceNowAttachment','Get-ServiceNowAttachment','Export-ServiceNowAttachment','Get-ServiceNowChangeRequest','Get-ServiceNowConfigurationItem','Get-ServiceNowIncident','Get-ServiceNowRequest','Get-ServiceNowRequestedItem','Get-ServiceNowTable','Get-ServiceNowTableEntry','Get-ServiceNowUser','Get-ServiceNowUserGroup','New-ServiceNowChangeRequest','New-ServiceNowIncident','New-ServiceNowQuery','New-ServiceNowRecord','Remove-ServiceNowAttachment','Remove-ServiceNowRecord','Update-ServiceNowChangeRequest','Update-ServiceNowIncident','Update-ServiceNowRequestedItem','Update-ServiceNowRecord')

    # Variables to export from this module
    VariablesToExport = @('ServiceNowSession', 'ServiceNowOperator', 'ServiceNowTable')

    AliasesToExport = @('gsnr','Get-ServiceNowIncident','Get-ServiceNowChangeRequest', 'Get-ServiceNowConfigurationItem', 'Get-ServiceNowRequest', 'Get-ServiceNowRequestedItem', 'Get-ServiceNowUser', 'Get-ServiceNowUserGroup','Update-ServiceNowNumber')

    # List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
         Tags = @('Azure','Automation','ServiceNow','PSModule')

        # A URL to the license for this module.
         LicenseUri = 'https://github.com/Snow-Shell/servicenow-powershell/blob/master/LICENSE'

        # A URL to the main website for this project.
         ProjectUri = 'https://github.com/Snow-Shell/servicenow-powershell'

            ReleaseNotes = 'https://github.com/Snow-Shell/servicenow-powershell/blob/master/CHANGELOG.md'
    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = 'https://github.com/Snow-Shell/servicenow-powershell'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
