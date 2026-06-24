###############################################################################
# Export Exchange ApplicationAccessPolicy
# V0.1 27.05.2026 - Initial Version - Andres Bohren
# V0.2 03.06.2026 - Updated to include Owner and Tags - Andres Bohren
# V0.3 22.06.2026 - Updated to include GroupObjectID - Andres Bohren
###############################################################################
# Reqired Modules:
# - ExchangeOnlineManagement
# - Microsoft.Graph
# Required Permissions:
# - Exchange Administrator (Exchange Online)
# - Application.Read.All (Microsoft Graph)
###############################################################################
Write-Host "Connect to Exchange Online"
Connect-ExchangeOnline -Showbanner:$false
[Array]$AAPolicies = Get-ApplicationAccessPolicy

Write-Host "Connect to Microsoft Graph"
Connect-MgGraph -Scopes Application.Read.All -NoWelcome

# Get All Graph Application Permissions
$uri = "https://graph.microsoft.com/v1.0/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')?`$select=id,appId,displayName,appRoles,oauth2PermissionScopes,resourceSpecificApplicationPermissions"
$AllPermissions = Invoke-MgGraphRequest -uri $uri -Method "GET"

# Loop through Application Access Policies
[Array]$ObjectArray = @()
Foreach ($AAPolicy in $AAPolicies)
{
    $AppID = $AAPolicy.AppID
    Write-Host "AppID: $AppID" -ForegroundColor Green
    $GroupObjectID = $AAPolicy.ScopeIdentityRaw.Split(";")[1]

    $EntraApp = Get-MgApplication -Filter "AppId eq '$AppID'" -Property Id,DisplayName,Tags
    [Array]$OwnerUPNArray = @()
    IF ($Null -ne $EntraApp)
    {
        [Array]$Tags = $EntraApp.Tags

        [Array]$OwnerArray = Get-MgApplicationOwner -ApplicationId $EntraApp.Id
        Foreach ($Owner in $OwnerArray)
        {
            $OwnerUPN = $Owner.AdditionalProperties.userPrincipalName
            Write-Host "OwnerUPN: $OwnerUPN" -ForegroundColor Yellow
            $OwnerUPNArray += $OwnerUPN
        }
    }

    $SP = Get-MgServicePrincipal -Filter "appId eq '$AppID'" -ErrorAction SilentlyContinue
    If ($Null -ne $SP)
    {
        $AppDisplayName = $SP.AppDisplayName
        Write-Host "AppDisplayName: $AppDisplayName" -ForegroundColor Green
    } else {
        Write-Host "Could not find ServicePrincipal" -ForegroundColor Red
    }
    
    # Get Group
    $GroupDisplayName = ""
    [Array]$GroupMembersPrimarySmtpAddress = @()
    $Group = Get-DistributionGroup -Identity $GroupObjectID -ErrorAction SilentlyContinue
    If ($Null -ne $Group)
    {
        $GroupDisplayName = $Group.DisplayName
        Write-Host "GroupDisplayName $GroupDisplayName" -ForegroundColor Magenta
        
        #Get Group Members
        $GroupMembers = Get-DistributionGroupMember -Identity $GroupObjectID
        If ($Null -ne $GroupMembers)
        {
            Foreach ($Member in $GroupMembers)
            {
                $PrimarySmtpAddress = $Member.PrimarySmtpAddress
                Write-Host "PrimarySmtpAddress: $PrimarySmtpAddress" -ForegroundColor Cyan
                $GroupMembersPrimarySmtpAddress += $PrimarySmtpAddress
            }
        }
    } else {
        Write-Host "No Group found" -ForegroundColor Red
    }
    
    [Array]$DelegatedPermissions = @()
    [Array]$ApplicationPermissions = @()
    If ($Null -ne $SP)
    {
        # Get App Permissions
        $Permissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $SP.Id
        Foreach ($Permission in $Permissions)
        {
            
            $AppRoleId = $Permission.AppRoleId
            #Write-Host "AppRoleId: $AppRoleId)"
            
            #Application Permissions
            $AppPermission = ($AllPermissions.appRoles | Where-Object {$_.id -eq "$AppRoleId"}).value
            If ($Null -ne $AppPermission)
            {
                Write-Host "App: $AppPermission"
                $ApplicationPermissions += $AppPermission
            }
        }

        # Delegated Permissions
        Write-Host "SPID: $($SP.Id)"
        [Array]$Permissions = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $SP.Id
        If ($Null -ne $Permissions)
        {
            
            [array]$MyDelegatedPermissions = $Permissions[0].Scope.split(" ")
            Foreach ($Permission in $MyDelegatedPermissions)
            {
                Write-Host "Delegated: $Permission"
                $DelegatedPermissions += $Permission
            }
        }
    }    

    $AppDetails = [PSCustomObject]@{
        AppID                             = $AppID
        AppDisplayName                    = $AppDisplayName
        AppOwners                         = $OwnerUPNArray -join "#"
        AppTags                           = $Tags -join "#"
        GroupDisplayName                  = $GroupDisplayName
        GroupObjectId                     = $GroupObjectID
        GroupMembersPrimarySmtpAddress    = $GroupMembersPrimarySmtpAddress -join "#"
        ApplicationPermissions            = $ApplicationPermissions -join "#"
        DelegatedPermissions              = $DelegatedPermissions -join "#"
    }

    # Add AppDetails to ObjectArray
    $ObjectArray += $AppDetails
}

#$ObjectArray
Write-Host "Exporting to CSV"
$ObjectArray | Export-Csv -Path "$PSScriptRoot\ApplicationAccessPolicies.csv" -Encoding UTF8

$MultilineString = @"
In Excel:
Ctrl + H. In the "Find what" box, type the character "#" in "Replace with", use the keyboard shortcut Ctrl + J for a line break
"@
Write-Host $MultilineString -ForegroundColor Green


