@{

# Script module or binary module file associated with this manifest.
RootModule = 'Icewolf.PIM.psm1'

# Version number of this module.
ModuleVersion = '0.1.0'

# Supported PSEditions
CompatiblePSEditions = @('Core', 'Desktop')

# ID used to uniquely identify this module
GUID = '9a6849f5-585b-47ce-9ab4-c6e8c13ce1b2'

# Author of this module
Author = 'Andres Bohren'

# Company or vendor of this module
CompanyName = 'icewolf.ch'

# Copyright statement for this module
Copyright = '(c) 2025 Andres Bohren'

# Description of the functionality provided by this module
Description = 'Enable Privileged Identity Management (PIM) for Azure AD roles and Groups, check PIM status and disable PIM for Azure AD roles and Groups.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()
RequiredModules = @(@{ModuleName = 'Microsoft.PowerShell.PSResourceGet'; GUID = 'e4e0bda1-0703-44a5-b70d-8fe704cd0643'; ModuleVersion = '1.1.1'; })

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Enable-PIM','Get-PIMStatus', 'Disable-PIM')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

	PSData = @{

		# Tags applied to this module. These help with module discovery in online galleries.
		Tags = @('Entra ID', 'PIM', 'PIM Groups', 'Privileged Identity Management')

		# A URL to the license for this module.
		# LicenseUri = ''

		# A URL to the main website for this project.
		ProjectUri = 'https://github.com/BohrenAn/GitHub_PowerShellScripts/Icewolf.PIM'

		# A URL to an icon representing this module.
		#IconUri = 'https://raw.githubusercontent.com/fabrisodotps1/M365PSProfile/develop/M365PSProfile.png'

 		# Set to a prerelease string value if the release should be a prerelease.
 		#Prerelease = 'Preview2'

		# ReleaseNotes of this module
		ReleaseNotes = '
---------------------------------------------------------------------------------------------
Whats new in this release:
V0.1.0
- Added Privileged Identity Management (PIM) Functions
    - Enable-PIM
    - Get-PIMStatus
    - Disable-PIM
---------------------------------------------------------------------------------------------
'
} # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

