###############################################################################
# Export Exchange ApplicationAccessPolicy
# V0.1 27.05.2026 - Initial Version - Andres Bohren
# V0.2 03.06.2026 - Updated to include Owner and Tags - Andres Bohren
# V0.3 22.06.2026 - Updated to include ScopeObjectID - Andres Bohren
# V0.4 09.09.2026 - Updated to include AppOwnersTags - Andres Bohren
# V0.5 15.09.2026 - Fixed NonExisting Apps / Changed Variables to Scope - Andres Bohren
###############################################################################
# Reqired Modules:
# - ExchangeOnlineManagement
# - Microsoft.Graph
# Required Permissions:
# - Exchange Administrator (Exchange Online)
# - Application.Read.All (Microsoft Graph)
###############################################################################
# Install-PSResource -Name DllPickle -Scope CurrentUser
#Write-Host "Import DLLPickle Module"
#Import-Module DLLPickle
#$Null = Import-DPLibrary

#$TenantId = "TenantName.onmicrosoft.com"
#$AppID = "8b47c606-291f-4c20-8221-02791d8e2823"
#$CertificateThumbprint = "7E8432FCDE36868735484C560CCDCB2FF00AF5F4"

# Connect to Microsoft Graph
Write-Host "Connect to Microsoft Graph"
Disconnect-MgGraph -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes Application.Read.All -NoWelcome
#Connect-MgGraph -ClientId $AppID -CertificateThumbprint $CertificateThumbprint -TenantId $TenantId -NoWelcome

# Check Exchange Online Connection
$Connection = Get-ConnectionInformation -ErrorAction SilentlyContinue
if ($Connection) {
    Write-Host "Already connected to Exchange Online"
} else {
    Write-Host "Connect to Exchange Online"
    Connect-ExchangeOnline -Showbanner:$false
    #Connect-ExchangeOnline -AppID $AppID -CertificateThumbprint $CertificateThumbprint -Organization $TenantId -ShowBanner:$false
}


# Get All Graph Application Permissions
$uri = "https://graph.microsoft.com/v1.0/servicePrincipals(appId='00000003-0000-0000-c000-000000000000')?`$select=id,appId,displayName,appRoles,oauth2PermissionScopes,resourceSpecificApplicationPermissions"
$AllPermissions = Invoke-MgGraphRequest -uri $uri -Method "GET"

# Get all Application Access Policies in Exchange Online
[Array]$AAPolicies = Get-ApplicationAccessPolicy

# Loop through Application Access Policies
[Array]$ObjectArray = @()
Foreach ($AAPolicy in $AAPolicies)
{

    #Reset Variables
    $AppID = ""
    $AppDisplayName = ""
    $OwnerUPNArray = @()
    $AppOwnersTags = @()
    $ScopeDisplayName = ""
    $ScopeObjectID = ""
    $ScopeObjectType = ""
    $ScopeMembersPrimarySmtpAddress = @()
    $ApplicationPermissions = @()
    $DelegatedPermissions = @()

    $AppID = $AAPolicy.AppID
    Write-Host "AppID: $AppID" -ForegroundColor Green
    $ScopeObjectID = $AAPolicy.ScopeIdentityRaw.Split(";")[1]

    $EntraApp = Get-MgApplication -Filter "AppId eq '$AppID'" -Property Id,DisplayName,Tags
    [Array]$OwnerUPNArray = @()
    IF ($Null -ne $EntraApp)
    {
        
        # Get Owners via Graph API
        [Array]$OwnerArray = Get-MgApplicationOwner -ApplicationId $EntraApp.Id
        Foreach ($Owner in $OwnerArray)
        {
            $OwnerUPN = $Owner.AdditionalProperties.userPrincipalName
            #Write-Host "OwnerUPN: $OwnerUPN" -ForegroundColor Yellow
            $OwnerUPNArray += $OwnerUPN
        }

        # Get Owner via Tags in App Manifest)
        if ($Null -ne $EntraApp.Tags) 
        {
            $TagOwners = $EntraApp.Tags | Where-Object { $_ -like "Owner*" }
             foreach ($Tag in $TagOwners) {
                $AppOwnersTags += $Tag
            }
        } else {
            $AppOwnersTags = @()
        }

        # Get Service Principal
        $SP = Get-MgServicePrincipal -Filter "appId eq '$AppID'" -ErrorAction SilentlyContinue
        If ($Null -ne $SP)
        {
            $AppDisplayName = $SP.AppDisplayName
            Write-Host "AppDisplayName: $AppDisplayName" -ForegroundColor Green
        } else {
            Write-Host "Could not find ServicePrincipal" -ForegroundColor Red
        }

    } else {
        Write-Host "APP $APPID does not EXIST" -ForegroundColor Yellow
        $AppDisplayName = "ENTRA APP DELETED"
    }

    # Get Scope Object
    $ScopeDisplayName = ""
    [Array]$ScopeMembersPrimarySmtpAddress = @()
    $Group = Get-DistributionGroup -Identity $ScopeObjectID -ErrorAction SilentlyContinue
    If ($Null -ne $Group)
    {
        $ScopeDisplayName = $Group.DisplayName
        $ScopeObjectType = "Group"
        Write-Host "ScopeDisplayName $ScopeDisplayName" -ForegroundColor Magenta
        
        #Get Group Members
        $GroupMembers = Get-DistributionGroupMember -Identity $ScopeObjectID
        If ($Null -ne $GroupMembers)
        {
            Foreach ($Member in $GroupMembers)
            {
                $PrimarySmtpAddress = $Member.PrimarySmtpAddress
                Write-Host "PrimarySmtpAddress: $PrimarySmtpAddress" -ForegroundColor Cyan
                $ScopeMembersPrimarySmtpAddress += $PrimarySmtpAddress
            }
        }
    } else {
        # Check if it's a User
        $MgUser = Get-MgUser -UserId $ScopeObjectID
        If ($Null -ne $MgUser)
        {
            Write-Host "Restriction Object > USER" -ForegroundColor Yellow
            $ScopeObjectType = "User"
            $ScopeDisplayName = $MgUser.DisplayName
            $ScopeObjectID = $MgUser.id
            $ScopeMembersPrimarySmtpAddress = $MgUser.Mail
        } else {

            Write-Host "Restriction Object not found (Group / User) " -ForegroundColor Red
        }
    }
    
    [Array]$DelegatedPermissions = @()
    [Array]$ApplicationPermissions = @()
    If ($Null -ne $SP)
    {
        # Get App Permissions
        $Permissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $SP.Id
        Foreach ($Permission in $Permissions)
        {
            #Application Permissions
            $AppRoleId = $Permission.AppRoleID
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
        AppOwnersTags                     = $AppOwnersTags -join "#"
        ScopeDisplayName                  = $ScopeDisplayName
        ScopeObjectID                     = $ScopeObjectID
        ScopeObjectType                   = $ScopeObjectType
        ScopeMembersPrimarySmtpAddress    = $ScopeMembersPrimarySmtpAddress -join "#"
        ApplicationPermissions            = $ApplicationPermissions -join "#"
        DelegatedPermissions              = $DelegatedPermissions -join "#"
    }

    # Add AppDetails to ObjectArray
    $ObjectArray += $AppDetails
}

#$ObjectArray
Write-Host "Exporting to CSV"
$ObjectArray | Export-Csv -Path "$PSScriptRoot\ApplicationAccessPolicies.csv" -Delimiter ";" -Encoding UTF8 -NoTypeInformation

$MultilineString = @"
In Excel:
Ctrl + H. In the "Find what" box, type the character "#" in "Replace with", use the keyboard shortcut Ctrl + J for a line break
"@
Write-Host $MultilineString -ForegroundColor Green