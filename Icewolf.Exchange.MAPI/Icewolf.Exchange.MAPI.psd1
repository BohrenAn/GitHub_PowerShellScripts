###############################################################################
# Icewolf.Exchange.MAPI Manifest
# V0.1 04.10.2021 - Initial Version - Andres Bohren
# V0.2 10.03.2022 - Updates and Cleaning Code - Andres Bohren
# V0.3 28.12.2022 - Updates and Cleaning Code - Andres Bohren
# V0.4 12.10.2023 - Added Folders "SentItems" and "DeletedItems" to the Default Folder List - Andres Bohren
# V0.5 29.11.2023 - - Added ValidateSet to Folder Parameter - Andres Bohren
###############################################################################

@{

# Script module or binary module file associated with this manifest.
RootModule = 'Icewolf.Exchange.MAPI.psm1'

# Version number of this module.
ModuleVersion = '0.5.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '812b9c18-8669-43fd-aaa8-327200f9f3f3'

# Author of this module
Author = 'Andres Bohren'

# Company or vendor of this module
CompanyName = 'icewolf.ch'

# Copyright statement for this module
Copyright = '(c) 2023 Andres Bohren. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This is a Powershell Module that simplifies the Handling of MAPI Permissions for Exchange and Exchange Online.
	Install-Module Icewolf.Exchange.MAPI'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @(ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '0.4578.0'; Guid = 'B5ECED50-AFA4-455B-847A-D8FB64140A22')
# RequiredModules = @(@{ModuleName = 'ExchangeOnlineManagement'; GUID = 'b5eced50-afa4-455b-847a-d8fb64140a22'; ModuleVersion = '3.0.0'; })

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
#FunctionsToExport = @('Add-MAPIPermission','Export-MAPIPermission','Remove-MAPIPermission','Connect-ExchangeOnline','Disconnect-ExchangeOnline')
FunctionsToExport = @('Add-MAPIPermission','Export-MAPIPermission','Remove-MAPIPermission')

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
		Tags = @('Exchange', 'ExchangeOnline', 'EXO', 'MAPI', 'FolderPermission')

		# A URL to the license for this module.
		# LicenseUri = ''

		# A URL to the main website for this project.
		ProjectUri = 'https://github.com/BohrenAn/GitHub_PowerShellScripts/tree/main/Icewolf.Exchange.MAPI'

		# A URL to an icon representing this module.
		# IconUri = ''

		# ReleaseNotes of this module
		ReleaseNotes = '
---------------------------------------------------------------------------------------------
Whats new in this release:
V0.5.0
- Added ValidateSet to Folder Parameter
---------------------------------------------------------------------------------------------
'

		# Prerelease string of this module
		#Prerelease = 'Preview3'

		# Flag to indicate whether the module requires explicit user acceptance for install/update/save
		RequireLicenseAcceptance = $false

		# External dependent modules of this module
		# ExternalModuleDependencies = @()

	} # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}