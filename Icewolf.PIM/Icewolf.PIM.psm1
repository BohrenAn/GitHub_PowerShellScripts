###############################################################################
# Icewolf.PIM Module
# Author: Andres Bohren
# 2025-10-03 v0.1.0 Initial Release - Andres Bohren
# Status: Beta / Development still in progress
###############################################################################

###############################################################################
# Function Enable-PIM
###############################################################################
#https://learn.microsoft.com/en-us/graph/identity-governance-pim-rules-overview

# Add -Groups Parameter to get the PIM Groups
# Connect-MgGraph -Scopes PrivilegedEligibilitySchedule.Read.AzureADGroup,RoleAssignmentSchedule.ReadWrite.Directory -NoWelcome
# Connect-MgGraph -Scopes PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup,RoleAssignmentSchedule.ReadWrite.Directory -NoWelcome
# https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilitySchedules?`$filter=principalid eq '6db8cdd5-8e93-462d-9907-994406c07f60'
# $PIMGroups = Invoke-MgGraphRequest -URI $uri -Method "GET" -ContentType "application/json"
# $PIMGroupDisplayName = (Get-MgGroup -GroupId 932aab78-78d8-428f-a931-7f064a9a491e).DisplayName
# PrivilegedEligibilitySchedule.Read.AzureADGroup	PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup
# $uri = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilitySchedules?$filter=principalid eq '6db8cdd5-8e93-462d-9907-994406c07f60'"
# Invoke-mgGraphRequest -URI $uri -Method "GET" -ContentType "application/json"
Function Enable-PIM
{
	[CmdletBinding()]
	param(
		[switch]$Groups
	)

	#Check if MgGraph is connected and has the right scope
	$Context = Get-MgContext -ErrorAction SilentlyContinue
	If ($Null -ne $Context)
	{
		If ($Context.Scopes -match "RoleAssignmentSchedule.ReadWrite.Directory")
		{
			#
		} else {
			Write-Host "Disconnect-MgGraph missing Scope: RoleAssignmentSchedule.ReadWrite.Directory"
			Disconnect-MgGraph
		}
	} else {
		Connect-MgGraph -Scopes "RoleAssignmentSchedule.ReadWrite.Directory" -NoWelcome
	}

	#Get Current User
	$context = Get-MgContext
	Write-Host "Your Account: $($Context.Account)" -ForegroundColor Cyan
	$currentUser = (Get-MgUser -UserId $context.Account).Id

    if ($Groups.IsPresent) 
	{
		#Get PIM Groups
		Write-Host "Getting PIM Groups"

		$INT = 0
		$URI = "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/eligibilitySchedules?`$filter=principalid eq '" + $currentUser + "'"
		$PIMGroups = Invoke-MgGraphRequest -URI $uri -Method "GET" -ContentType "application/json"
		Foreach ($PIMGroup in $PIMGroups.Value)
		{
			$Int = $Int + 1
			Write-Verbose "GroupID: $($PIMGroup.GroupId)"
			$PIMGroupDisplayName = (Get-MgGroup -GroupId $PIMGroup.GroupId).DisplayName
			Write-Host "$($int). $PIMGroupDisplayName"
		}

		# Prompt the user to select a number
		$selectedNumber = Read-Host "Select a number to proceed"

		$SelectedPIMGroup = $PIMGroups.Value[$SelectedNumber -1]
		$Justification = Read-Host "Justification"

		$params = @{
			accessId = "member"
			principalId = $currentUser
			groupId = $SelectedPIMGroup.GroupId
			action = "selfActivate"
			scheduleInfo = @{
				startDateTime = Get-Date
				expiration = @{
					type = "afterDuration"
					Duration = "PT8H"
				}
			}
		justification = $Justification
		}

		#Debug
		#Write-Debug "Params: $params"
		#$params

		# Activate the Group
		try {
			$Error.Clear()
			$Request = New-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleRequest -BodyParameter $params #-ErrorAction Stop

			# Check if the request was successful
			if ($Error.Count -gt 0) {
				Write-Host "❌ Failed to activate group $groupId."
			} else {
				Write-Host "✅ Activated group $groupId for user $UserUPN"
			}

			Do {
				$RequestStatus = Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -UnifiedRoleAssignmentScheduleRequestId $Request.Id
				Write-Host "Request Status: $($RequestStatus.Status)" -ForegroundColor Green
				Start-Sleep -Seconds 5
			} while ($RequestStatus.Status -ne "Provisioned")

		} catch {
			# Handle the error
			Write-Host "Error: $($error[0].exception.message)" -ForegroundColor Red
			#Write-Host "Error: $($error[0].FullyQualifiedErrorId)" -ForegroundColor Red
			#Write-Host "Error: $($error[0].InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
			#Write-Host "Error: $($error[0].InvocationInfo.PositionMessage)" -ForegroundColor Red
			#Write-Host "Error: $($error[0].InvocationInfo.Line)" -ForegroundColor Red
			#Write-Host "Error: $($error[0].InvocationInfo.ScriptName)" -ForegroundColor Red
		}
    
    } else {
		# Get all available roles
		Write-Host "Getting Eligible Roles"
		$myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$currentuser'"
		#$DisplayNames =  $myRoles.RoleDefinition.DisplayName
		#Get-MgPolicyRoleManagementPolicy -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'"
		#Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $unifiedRoleManagementPolicyId -UnifiedRoleManagementPolicyRuleId $unifiedRoleManagementPolicyRuleId
		#Get PIM Role Rule like Time and Ticketnumber
		#$policy = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/policies/roleManagementPolicies/DirectoryRole_46bbad84-29f0-4e03-8d34-f6841a5071ad_20a5c74b-d9eb-4998-909a-ecba58414f09?$expand=rules"
		#$policy

		
        Write-Progress -Activity "Fetching all active Entra ID roles" -Id 0
        [array]$myActiveRoles = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$currentUser'" -ErrorAction Stop
        Write-Progress -Id 0 -Completed

		$Int =0 
		Foreach ($Role in $MyRoles)
		{
			$Int = $Int + 1
			$RoleDisplayName = $Role.RoleDefinition.DisplayName
			Write-Host "$($int). $RoleDisplayName"
		}

		# Prompt the user to select a number
		$selectedNumber = Read-Host "Select a number to proceed"

		$Role = $myRoles[$SelectedNumber -1]
		$Justification = Read-Host "Justification"

		# Setup parameters for activation
		$params = @{
			Action = "selfActivate"
			PrincipalId = $Role.PrincipalId
			RoleDefinitionId = $Role.RoleDefinitionId
			DirectoryScopeId = $Role.DirectoryScopeId
			Justification = $Justification
			ScheduleInfo = @{
				StartDateTime = Get-Date
				Expiration = @{
					Type = "AfterDuration"
					Duration = "PT8H"
				}
			}
		}

		Write-Debug "Params: $params"

		# Activate the role
		$Request = New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params

		Do {
			$RequestStatus = Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -UnifiedRoleAssignmentScheduleRequestId $Request.Id
			Write-Host "Request Status: $($RequestStatus.Status)" -ForegroundColor Green
			Start-Sleep -Seconds 5
		} while ($RequestStatus.Status -ne "Provisioned")
	}
}


###############################################################################
# Function Get-PIMStatus
###############################################################################
#RoleSettings
<#
{
    "roleDefinitionId": "810a2642-a034-447f-a5e8-41beaa378541",
    "resourceId": "46bbad84-29f0-4e03-8d34-f6841a5071ad",
    "subjectId": "6db8cdd5-8e93-462d-9907-994406c07f60",
    "assignmentState": "Active",
    "type": "UserAdd",
    "reason": "Yammer",
    "ticketNumber": "",
    "ticketSystem": "",
    "schedule": {
        "type": "Once",
        "startDateTime": null,
        "endDateTime": null,
        "duration": "PT480M"
    },
    "linkedEligibleRoleAssignmentId": "QiYKgTSgf0Sl6EG-qjeFQdXNuG2Tji1GmQeZRAbAf2A-1-e",
    "scopedResourceId": ""
}
#>

Function Get-PIMStatus
{
	[CmdletBinding()]
	param(
		[switch]$Groups
	)

	#Check if MgGraph is connected and has the right scope
	$Context = Get-MgContext -ErrorAction SilentlyContinue
	If ($Null -ne $Context)
	{
		If ($Context.Scopes -match "RoleAssignmentSchedule.ReadWrite.Directory")
		{
			#
		} else {
			Write-Host "Disconnect-MgGraph missing Scope: RoleAssignmentSchedule.ReadWrite.Directory"
			Disconnect-MgGraph
		}
	} else {
		Connect-MgGraph -Scopes "RoleAssignmentSchedule.ReadWrite.Directory" -NoWelcome
	}

	#Get Current User
	$context = Get-MgContext
	Write-Host "Your Account: $($Context.Account)" -ForegroundColor Cyan
	$currentUser = (Get-MgUser -UserId $context.Account).Id

	If ($Groups.IsPresent) 
	{
		#Get PIM Groups
	} else {

		# Get all available roles
		Write-Host "Getting Eligible Roles"
		$myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$currentuser'"
		#$DisplayNames =  $myRoles.RoleDefinition.DisplayName

		$Int =0 
		$RoleArray = @()
		Foreach ($Role in $MyRoles)
		{
			$Int = $Int + 1
			$Filter = "Roledefinitionid eq '" + $Role.Roledefinitionid +"'"
			Write-Verbose "Filter: $Filter"

			$RoleStatus = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -Filter $Filter -Top 1
			$RoleDisplayName = $Role.RoleDefinition.DisplayName
			$AssignmentType = $RoleStatus.AssignmentType
			$StartDateTime = $RoleStatus.StartDateTime
			$EndDateTime = $RoleStatus.EndDateTime
			#Write-Host "$($int). $RoleDisplayName Status: $AssignmentType Start: $StartDateTime End: $EndDateTime"


			$MyRoleObject = [PSCustomObject]@{
				#RoleStatus      = $RoleStatus
				RoleDisplayName = $RoleDisplayName
				AssignmentType  = $AssignmentType
				StartDateTime   = $StartDateTime
				EndDateTime     = $EndDateTime
			}
			$RoleArray += $MyRoleObject

		}
		$RoleArray | Format-Table
	}
}




###############################################################################
# Disable-PIM
###############################################################################
# Deacitvate Role
<#
{
    "roleDefinitionId": "810a2642-a034-447f-a5e8-41beaa378541",
    "resourceId": "46bbad84-29f0-4e03-8d34-f6841a5071ad",
    "subjectId": "6db8cdd5-8e93-462d-9907-994406c07f60",
    "assignmentState": "Active",
    "type": "UserRemove",
    "reason": "Deactivation request",
    "linkedEligibleRoleAssignmentId": "QiYKgTSgf0Sl6EG-qjeFQdXNuG2Tji1GmQeZRAbAf2A-1",
    "scopedResourceId": null
}
#>
Function Disable-PIM
{
	[CmdletBinding()]
	param(
		[switch]$Groups
	)

	#Check if MgGraph is connected and has the right scope
	$Context = Get-MgContext -ErrorAction SilentlyContinue
	If ($Null -ne $Context)
	{
		If ($Context.Scopes -match "RoleAssignmentSchedule.ReadWrite.Directory")
		{
			#
		} else {
			Write-Host "Disconnect-MgGraph missing Scope: RoleAssignmentSchedule.ReadWrite.Directory"
			Disconnect-MgGraph
		}
	} else {
		Connect-MgGraph -Scopes "RoleAssignmentSchedule.ReadWrite.Directory" -NoWelcome
	}

	#Get Current User
	$context = Get-MgContext
	Write-Host "Your Account: $($Context.Account)" -ForegroundColor Cyan
	$currentUser = (Get-MgUser -UserId $context.Account).Id

    if ($Groups.IsPresent) 
	{
		#Get PIM Groups
	} else {
		# Get all available roles
		Write-Host "Getting Eligible Roles"
		$myRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -All -Filter "principalId eq '$currentuser'"
		#$DisplayNames =  $myRoles.RoleDefinition.DisplayName

		$Int =0 
		Foreach ($Role in $MyRoles)
		{
			$Int = $Int + 1
			$RoleDisplayName = $Role.RoleDefinition.DisplayName
			Write-Host "$($int). $RoleDisplayName"
		}

		# Prompt the user to select a number
		$selectedNumber = Read-Host "Select a number to proceed"

		$Role = $myRoles[$SelectedNumber -1]

		Write-Host "Disabling PIM Role: $($Role.RoleDefinition.DisplayName)" -ForegroundColor Yellow

		try {
			Set-MgRoleManagementDirectoryRoleEligibilitySchedule -UnifiedRoleEligibilityScheduleId $Role.Id -Status "denied" -ErrorAction Stop
			Write-Host "PIM Role disabled successfully." -ForegroundColor Green
		} catch {
			Write-Host "Error disabling PIM Role: $($_.Exception.Message)" -ForegroundColor Red
			return
		}
	}
}