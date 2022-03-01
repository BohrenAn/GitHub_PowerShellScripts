######################################################################
# Create Microsoft Teams AutoAttendand and CallQueue
# https://blog.icewolf.ch/archive/2021/01/30/create-teams-auto-attendant-and-call-queue-with-powershell.aspx
######################################################################
Import-Module MicrosoftTeams
Connect-MicrosoftTeams

######################################################################
# Create Resource Account
# New-CsOnlineApplicationInstance
# https://docs.microsoft.com/en-us/powershell/module/skype/new-csonlineapplicationinstance?view=skype-ps
######################################################################
#ApplicationID
#Auto Attendant: ce933385-9390-45d1-9512-c8d228074e07
#Call Queue: 11cd3e2e-fccb-42ad-ad00-878b93575e07

#CallQueue
New-CsOnlineApplicationInstance -UserPrincipalName CallQueueDemo02@icewolf.ch -DisplayName "CallQueueDemo02" -ApplicationId "11cd3e2e-fccb-42ad-ad00-878b93575e07"

#AutoAttendant
New-CsOnlineApplicationInstance -UserPrincipalName AutoattendantDemo02@icewolf.ch -DisplayName "AutoattendantDemo02@icewolf.ch" -ApplicationId "ce933385-9390-45d1-9512-c8d228074e07"

######################################################################
# Connect AzureAD
######################################################################
Import-Module AzureADPreview
Connect-AzureAD

######################################################################
# Assign PhoneSystem Virtual Licence and Location
# Configure Microsoft 365 user account properties with PowerShell
# https://docs.microsoft.com/en-us/microsoft-365/enterprise/configure-user-account-properties-with-microsoft-365-powershell?view=o365-worldwide
######################################################################
$User = Get-AzureADUser -ObjectId "CallQueueDemo02@icewolf.ch" 
$User | Set-AzureADUser -UsageLocation "CH"

#Set-AzureADUserLicense
#https://docs.microsoft.com/en-us/powershell/module/azuread/set-azureaduserlicense?view=azureadps-2.0
 
$User = Get-AzureADUser -ObjectId "CallQueueDemo02@icewolf.ch" 
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = "440eaaa8-b3e0-484b-a8be-62870b9ba70a"
$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$LicensesToAssign.AddLicenses = $License
Set-AzureADUserLicense -ObjectId $User.ObjectId -AssignedLicenses $LicensesToAssign
 
$User = Get-AzureADUser -ObjectId "AutoAttendantDemo02@icewolf.ch" 
$User | Set-AzureADUser -UsageLocation "CH"
 
$User = Get-AzureADUser -ObjectId "AutoAttendantDemo02@icewolf.ch" 
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = "440eaaa8-b3e0-484b-a8be-62870b9ba70a"
$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$LicensesToAssign.AddLicenses = $License
Set-AzureADUserLicense -ObjectId $User.ObjectId -AssignedLicenses $LicensesToAssign

######################################################################
# Assign Number to Resource Account
######################################################################
#AutoAttendant
Set-CsOnlineApplicationInstance -Identity AutoAttendantDemo02@icewolf.ch -OnpremPhoneNumber +41215553973
#CallQueue
Set-CsOnlineApplicationInstance -Identity CallQueueDemo02@icewolf.ch -OnpremPhoneNumber +41215553974

Get-CsOnlineApplicationInstance


######################################################################
# Im GUI kann man Files bis 5MB hochladen. In PowerShell sind das anscheinend nur 850 KB
# Import-CsOnlineAudioFile
# https://docs.microsoft.com/en-us/powershell/module/skype/import-csonlineaudiofile?view=skype-ps
#Upload Audio File Import-CsOnlineAudioFile
######################################################################

$content = Get-Content "E:\Temp\CallQueueDemo02.mp3" -Encoding byte -ReadCount 0
$audioFile = Import-CsOnlineAudioFile -ApplicationId "HuntGroup" -FileName "CallQueueDemo02.mp3" -Content $content
$audioFile


######################################################################
# New-CsCallQueue
# https://docs.microsoft.com/en-us/powershell/module/skype/new-CsCallQueue?view=skype-ps
######################################################################

New-CsCallQueue -Name "CallQueueDemo02" -LanguageId "de-DE" -UseDefaultMusicOnHold $true -RoutingMethod Attendant -Users @("6db8cdd5-8e93-462d-9907-994406c07f60") -AllowOptOut $true -AgentAlertTime 30 -OverflowThreshold 50 -OverflowAction DisconnectWithBusy -TimeoutThreshold 1200 -TimeoutAction Disconnect

New-CsCallQueue -Name "CallQueueDemo02" -LanguageId "de-DE" -WelcomeMusicAudioFileId $audioFile.ID -UseDefaultMusicOnHold $true -RoutingMethod Attendant -Users @("6db8cdd5-8e93-462d-9907-994406c07f60") -AllowOptOut $true -AgentAlertTime 30 -OverflowThreshold 50 -OverflowAction DisconnectWithBusy -TimeoutThreshold 1200 -TimeoutAction Disconnect

######################################################################
#Assign ResourceAccount to Callqueue
######################################################################
#get application id and call queue id
$applicationInstanceId = (Get-CsOnlineUser "CallQueueDemo02@icewolf.ch")[-1].ObjectId
$callQueueId = (Get-CsCallQueue -NameFilter "CallQueueDemo02").Identity

#make the connection
New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $callQueueId -ConfigurationType CallQueue


######################################################################
#AudioFile for AutoAttendant
######################################################################
#Upload Audio File Import-CsOnlineAudioFile
$content = Get-Content "E:\Temp\AutoAttendantDemo02.mp3" -Encoding byte -ReadCount 0
$GreetingAudioFile = Import-CsOnlineAudioFile -ApplicationId "HuntGroup" -FileName "AutoAttendantDemo02.mp3" -Content $content
$GreetingAudioFile

######################################################################
# Default Call Flow
# New-CsAutoAttendantCallFlow
# https://docs.microsoft.com/en-us/powershell/module/skype/new-csautoattendantcallflow?view=skype-ps
######################################################################
$callableEntityId = (Find-CsOnlineApplicationInstance -SearchQuery "CallQueueDemo02") | Select-Object -Property Id
$CallTarget= New-CsAutoAttendantCallableEntity -Identity $callableEntityId.id -Type ApplicationEndpoint
$menuOption = New-CsAutoAttendantMenuOption -Action TransferCallToTarget -DtmfResponse Automatic -CallTarget $CallTarget

$AAMenu = New-CsAutoAttendantMenu -Name "Default Menu" -MenuOptions @($menuOption) -DirectorySearchMethod None
$WelcomePrompt = New-CsAutoAttendantPrompt -AudioFilePrompt $GreetingAudioFile
$DefaultCallFlow = New-CsAutoAttendantCallFlow -Name "AutoAttendantDemo02 Default call flow" -Menu $AAMenu -Greetings @($WelcomePrompt)

######################################################################
#After Hours Call Flow
######################################################################
#TimeRange
#New-CsOnlineTimeRange
#https://docs.microsoft.com/en-us/powershell/module/skype/new-csonlinetimerange?view=skype-ps

$trMorning = New-CsOnlineTimeRange -Start 08:00 -End 12:00
$trAfternoon = New-CsOnlineTimeRange -Start 13:00 -End 17:00

#Business Hours
#New-CsOnlineSchedule
#https://docs.microsoft.com/en-us/powershell/module/skype/new-csonlineschedule?view=skype-ps

$AfterHoursShedule = New-CsOnlineSchedule -Name "BusinessHours" -WeeklyRecurrentSchedule -MondayHours @($trMorning,$trAfternoon) -TuesdayHours @($trMorning,$trAfternoon) -WednesdayHours @($trMorning,$trAfternoon) -ThursdayHours @($trMorning,$trAfternoon) -FridayHours @($trMorning,$trAfternoon) -Complement

#Upload Audio File Import-CsOnlineAudioFile
$content = Get-Content "E:\Temp\AutoAttendantDemo02OOF.mp3" -Encoding byte -ReadCount 0
$GreetingAudioFileOOF = Import-CsOnlineAudioFile -ApplicationId "HuntGroup" -FileName "AutoAttendantDemo02OOF.mp3" -Content $content
$GreetingAudioFileOOF
$OOFPrompt = New-CsAutoAttendantPrompt -AudioFilePrompt $GreetingAudioFileOOF

#Menu
$menuOption = New-CsAutoAttendantMenuOption -Action DisconnectCall -DtmfResponse Automatic
$afterHoursMenu = New-CsAutoAttendantMenu -Name "After Hours Call Flow" -MenuOptions @($menuOption) -DirectorySearchMethod None
$afterHoursCallFlow = New-CsAutoAttendantCallFlow -Name "AutoAttendantDemo02 After hours call flow" -Menu $afterHoursMenu -Greetings @($OOFPrompt)

#CallHandlingAssociation
#New-CsAutoAttendantCallHandlingAssociation
#https://docs.microsoft.com/en-us/powershell/module/skype/new-csautoattendantcallhandlingassociation?view=skype-ps

$AfterHoursSheduleCallHandlingAssociation = New-CsAutoAttendantCallHandlingAssociation -Type AfterHours -ScheduleId $AfterHoursShedule.Id -CallFlowId $afterHoursCallFlow.Id

#TimeZone
#Get-CsAutoAttendantSupportedTimeZone
#https://docs.microsoft.com/en-us/powershell/module/skype/get-csautoattendantsupportedtimezone?view=skype-ps


######################################################################
# Auto Attendant
# New-CsAutoAttendant
# https://docs.microsoft.com/en-us/powershell/module/skype/new-csautoattendant?view=skype-ps
######################################################################
$aaName = "AutoAttendantDemo02"
$language = "de-DE"
$TimeZone = "W. Europe Standard Time"
$CallQueueId = (Get-CsOnlineUser -Identity "CallQueueDemo02@icewolf.ch").ObjectId
New-CsAutoAttendant -Name $aaName -LanguageId $language -CallFlows @($afterHoursCallFlow) -TimeZoneId $TimeZone -DefaultCallFlow $DefaultCallFlow -CallHandlingAssociations @($AfterHoursSheduleCallHandlingAssociation)

######################################################################
#Assign ResourceAccount to AutoAttendant
######################################################################
#get application id and call queue id
$applicationInstanceId = (Get-CsOnlineUser "AutoAttendantDemo02@icewolf.ch")[-1].ObjectId
$AutoAttendantID = (Get-CsAutoAttendant -NameFilter "AutoAttendantDemo02").Identity

#make the connection
New-CsOnlineApplicationInstanceAssociation -Identities @($applicationInstanceId) -ConfigurationId $AutoAttendantID -ConfigurationType AutoAttendant

######################################################################
# Show Auto Attendant
######################################################################
Get-CsAutoAttendant