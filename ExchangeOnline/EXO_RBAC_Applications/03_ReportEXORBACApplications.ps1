###############################################################################
# Export Exchange RBAC for Applications
# V0.1 22.06.2026 - Initial Version - Andres Bohren
###############################################################################
# Reqired Modules:
# - ExchangeOnlineManagement
# - Microsoft.Graph
# - DLLPickle
# Required Permissions:
# - Exchange Administrator (Exchange Online)
# - Application.Read.All (Microsoft Graph)
###############################################################################
# Install-PSResource -Name DllPickle -Scope CurrentUser
Write-Host "Import DLLPickle Module"
Import-Module DLLPickle
$Null = Import-DPLibrary

# Run Garbage Collection
[System.GC]::Collect()

Write-Host "Connect to Exchange Online"
Connect-ExchangeOnline -Showbanner:$false

Write-Host "Connect to Microsoft Graph"
Connect-MgGraph -Scopes Application.Read.All -NoWelcome

# Get Exchange Application Access Policies
[Array]$AAPolicies = Get-ApplicationAccessPolicy

# Get Exchange Service Principals
[Array]$ServicePrincipals = Get-Serviceprincipal

# Loop through Exchange Service Principals
[Array]$ObjectArray = @()
Foreach ($SP in $ServicePrincipals)
{
    $AppID = $SP.AppId
    $SPObjectID = $SP.ObjectId
    Write-Host "AppID: $AppID" -ForegroundColor Green

    If ($AAPolicies.AppId -match $AppId)
    {
       Write-Host "Application Access Policy exists for this AppID" -ForegroundColor Cyan
    } else {
        
        [Array]$EXORoleAssignments = Get-ManagementRoleAssignment | Where-Object {$_.App -eq "$SPObjectID"}
        Foreach ($EXORoleAssignment in $EXORoleAssignments)
        {
            $ApplicationPermissions = $EXORoleAssignment.Role
            $ManagementScope = $EXORoleAssignment.CustomResourceScope
            If ($Null -ne $ManagementScope)
            {
                Write-Host "Management Scope: $ManagementScope" -ForegroundColor Cyan
                $ManagementScopeDetails = Get-ManagementScope -Identity "$ManagementScope"
                [String]$RecipientFilter = $ManagementScopeDetails.RecipientFilter
                Write-Host "Recipient Filter: $RecipientFilter" -ForegroundColor Cyan
            }
            
            If ($EXORoleAssignment.RecipientWriteScope -eq "Group")
            {
                $GroupName = $EXORoleAssignment.CustomResourceScope
                $Group = Get-DistributionGroup -Identity $GroupName
                If ($null -ne $Group)
                {
                    [String]$GroupDisplayName = $Group.DisplayName
                    #$GroupObjectID = $Group.ExternalDirectoryObjectId
                    Write-Host "GroupObjectID: $GroupObjectID" -ForegroundColor Cyan
                    $GroupMembers = Get-DistributionGroupMember -Identity $Group
                    [Array]$GroupMembersPrimarySmtpAddress = @()
                    Foreach ($GroupMember in $GroupMembers)
                    {
                        $GroupMembersPrimarySmtpAddress += $GroupMember.PrimarySmtpAddress
                    }
                }
            }

            #Role                         : Application Mail.Send
            #CustomResourceScope          : AllRooms
            #RecipientWriteScope          : CustomRecipientScope
            #RecipientWriteScope          : Group
            #CustomResourceScope          : PostmasterGraphRestriction
        
            # Get Graph Application
            $EntraApp = Get-MgApplication -Filter "AppId eq '$AppID'" -Property Id,DisplayName,Tags
            [Array]$OwnerUPNArray = @()
            IF ($Null -ne $EntraApp)
            {
                $AppDisplayName = $EntraApp.DisplayName            
            
                [Array]$Tags = $EntraApp.Tags

                [Array]$OwnerArray = Get-MgApplicationOwner -ApplicationId $EntraApp.Id
                Foreach ($Owner in $OwnerArray)
                {
                    $OwnerUPN = $Owner.AdditionalProperties.userPrincipalName
                    Write-Host "OwnerUPN: $OwnerUPN" -ForegroundColor Yellow
                    $OwnerUPNArray += $OwnerUPN
                }
            }

            $AppDetails = [PSCustomObject]@{
                AppID                             = $AppID
                AppDisplayName                    = $AppDisplayName
                AppOwners                         = $OwnerUPNArray -join "#"
                AppTags                           = $Tags -join "#"
                ApplicationPermissions            = $ApplicationPermissions
                ManagementScope                   = $ManagementScope
                RecipientFilter                   = $RecipientFilter
                GroupDisplayName                  = $GroupDisplayName
                GroupObjectId                     = $GroupObjectID
                GroupMembersPrimarySmtpAddress    = $GroupMembersPrimarySmtpAddress -join "#"
            }

            # Add AppDetails to ObjectArray
            $ObjectArray += $AppDetails
        }
    }
}

#$ObjectArray
Write-Host "Exporting to CSV"
$ObjectArray | Export-Csv -Path "$PSScriptRoot\EXORBACApplications.csv" -Encoding UTF8

$MultilineString = @"
In Excel:
Ctrl + H. In the "Find what" box, type the character "#" in "Replace with", use the keyboard shortcut Ctrl + J for a line break
"@
Write-Host $MultilineString -ForegroundColor Green
