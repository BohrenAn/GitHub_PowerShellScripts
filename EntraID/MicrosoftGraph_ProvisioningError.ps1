###############################################################################
# Get Azure AD Sync Errors
# 07.06.2022 - Initial Version - Andres Bohren
# Warning: Incomplete and not yet really tested
###############################################################################

Connect-MgGraph -Scopes Group.Read.All,User.Read.All
$Groups = Get-MgGroup -All
$Groups | Where-Object {$_.onPremisesProvisioningErrors -ne $null} | Format-List

$Users = Get-MgUser -All
$Users | Where-Object {$_.onPremisesProvisioningErrors -ne $null} | Format-List


#Graph Explorer
https://developer.microsoft.com/en-us/graph/graph-explorer


#Test Querys
https://graph.microsoft.com/v1.0/users?$filter=provisionedPlans/any(p:p/provisioningStatus eq 'Error')&$count=true
ConsistencyLevel: eventual

https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/any(o:o/category)
https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/any(p:p/category eq 'PropertyConflict')&$count=true
https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/any(s:s/category eq 'PropertyConflict')&$count=true

https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/any(a:a/category eq 'PropertyConflict')&$count=true
https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/any(c:c/category eq 'PropertyConflict')&$count=true

https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/category ne null&$count=true
https://graph.microsoft.com/beta/groups?$filter=onPremisesProvisioningErrors/category eq 'PropertyConflict'&$count=true

PropertyConflict
"onPremisesProvisioningErrors": [
    {
        "value": "SMTP:IcewolfDemo@icewolf.ch",
        "category": "PropertyConflict",
        "propertyCausingError": "ProxyAddresses",
        "occurredDateTime": "2022-06-27T10:29:29.0922053Z"
    }
],

Get-MgGroup -Filter "onPremisesProvisioningErrors ne null"
Get-MgGroup -Filter "onPremisesProvisioningErrors ne null" -CountVariable CountVar -ConsistencyLevel eventual

