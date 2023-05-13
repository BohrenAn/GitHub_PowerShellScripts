# Active Directory PowerShell
Here are some Examples for PowerShell Querys with Active Directory

## Install 

### Windows 10 / Windows 11
You need to install the RSAT (Remote Server Administration Tools) for Active Directory

```pwsh
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State
Add-WindowsCapability –online –Name “Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0”
```

### Windows Server 
```pwsh
Install-WindowsFeature -Name "RSAT-AD-PowerShell" #-IncludeAllSubFeature
```

## AD Forest
```pwsh
Get-ADForest
```

## Active Directory Domain
```pwsh
Get-ADDomain
```

## User
```pwsh
$SamAccountName = "a.bohren"
$ADUser = Get-ADUser -Identity $SamAccountName
$ADUser = Get-ADUser -Filter {Surname -eq "Bohren"}
$ADuser = Get-ADUser -LDAPFilter "(Objectclass=User)"
```

## Group
```pwsh
Get-ADGroup
```

## Contact
```pwsh
Get-ADContact
```

