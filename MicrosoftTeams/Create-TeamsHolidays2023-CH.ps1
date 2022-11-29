################################################################################
# Create MicrosoftTeamsHolidays 2023
# 24.11.2022 - V1.0 - Initial Version - Andres Bohren
################################################################################

#List of Holidays in Teams
Connect-MicrosoftTeams
$Schedule = Get-CsOnlineSchedule | Where-Object {$_.Type -eq "Fixed"}
$Schedule
$Schedule.FixedSchedule
$Schedule.FixedSchedule.DateTimeRanges

#Feiertage 2023
#https://www.ferienwiki.ch/feiertage/2023/ch
#https://www.feiertagskalender.ch/index.php?jahr=2023&geo=3056&klasse=5&hl=de&hidepast=1



#Neujahr 01.01.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-01-01T00:00:00" -End "2023-01-02T00:00:00"
New-CsOnlineSchedule -Name "Neujahr" -FixedSchedule -DateTimeRanges @($DateRange)

#Berchtoldstag 02.01.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-01-02T00:00:00" -End "2023-01-03T00:00:00"
New-CsOnlineSchedule -Name "Berchtoldstag" -FixedSchedule -DateTimeRanges @($DateRange)

#Heilige Drei Könige 06.01.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-01-06T00:00:00" -End "2023-01-07T00:00:00"
New-CsOnlineSchedule -Name "Heilige Drei Könige" -FixedSchedule -DateTimeRanges @($DateRange)

#St. Josef 19.03.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-03-19T00:00:00" -End "2023-03-20T00:00:00"
New-CsOnlineSchedule -Name "St. Josef" -FixedSchedule -DateTimeRanges @($DateRange)

#Karfreitag 07.04.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-04-07T00:00:00" -End "2023-04-08T00:00:00"
New-CsOnlineSchedule -Name "Karfreitag" -FixedSchedule -DateTimeRanges @($DateRange)

#Ostersonntag 09.04.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-04-09T00:00:00" -End "2023-04-10T00:00:00"
New-CsOnlineSchedule -Name "Ostersonntag" -FixedSchedule -DateTimeRanges @($DateRange)

#Sechseläuten 17.04.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-04-17T00:00:00" -End "2023-04-18T00:00:00"
New-CsOnlineSchedule -Name "Sechseläuten" -FixedSchedule -DateTimeRanges @($DateRange)

#Auffahrt 18.05.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-05-18T00:00:00" -End "2023-05-19T00:00:00"
New-CsOnlineSchedule -Name "Auffahrt" -FixedSchedule -DateTimeRanges @($DateRange)

#Pfingstmontag 29.05.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-05-29T00:00:00" -End "2023-05-30T00:00:00"
New-CsOnlineSchedule -Name "Pfingstmontag" -FixedSchedule -DateTimeRanges @($DateRange)

#Fronleichnam 08.06.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-06-08T00:00:00" -End "2023-06-09T00:00:00"
New-CsOnlineSchedule -Name "Fronleichnam" -FixedSchedule -DateTimeRanges @($DateRange)

#Peter und Paul 29.06.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-06-29T00:00:00" -End "2023-06-30T00:00:00"
New-CsOnlineSchedule -Name "Peter und Paul" -FixedSchedule -DateTimeRanges @($DateRange)

#Bundesfeier 01.08.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-08-01T00:00:00" -End "2023-08-02T00:00:00"
New-CsOnlineSchedule -Name "Bundesfeier" -FixedSchedule -DateTimeRanges @($DateRange)

#Mariä Himmelfahrt 15.08.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-08-15T00:00:00" -End "2023-08-16T00:00:00"
New-CsOnlineSchedule -Name "Mariä Himmelfahrt" -FixedSchedule -DateTimeRanges @($DateRange)

#Genfer Bettag 07.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-09-07T00:00:00" -End "2023-09-08T00:00:00"
New-CsOnlineSchedule -Name "Genfer Bettag" -FixedSchedule -DateTimeRanges @($DateRange)

#Knabenschiessen 11.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-09-11T00:00:00" -End "2023-09-12T00:00:00"
New-CsOnlineSchedule -Name "Knabenschiessen" -FixedSchedule -DateTimeRanges @($DateRange)

#Eidgenössischer Dank-, Buss- und Bettag 17.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-09-17T00:00:00" -End "2023-09-18T00:00:00"
New-CsOnlineSchedule -Name "Eidgenössischer Dank-, Buss- und Bettag" -FixedSchedule -DateTimeRanges @($DateRange)

#Mauritiustag 22.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-09-22T00:00:00" -End "2023-09-23T00:00:00"
New-CsOnlineSchedule -Name "Mauritiustag" -FixedSchedule -DateTimeRanges @($DateRange)

#St. Leodegar 02.10.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-10-02T00:00:00" -End "2023-10-03T00:00:00"
New-CsOnlineSchedule -Name "St. Leodegar" -FixedSchedule -DateTimeRanges @($DateRange)

#Allerheiligen 01.11.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-11-01T00:00:00" -End "2023-11-02T00:00:00"
New-CsOnlineSchedule -Name "Allerheiligen" -FixedSchedule -DateTimeRanges @($DateRange)

#Mariä Empfängnis 08.12.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-12-08T00:00:00" -End "2023-12-09T00:00:00"
New-CsOnlineSchedule -Name "Mariä Empfängnis" -FixedSchedule -DateTimeRanges @($DateRange)

#Weihnachten 25.12.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-12-25T00:00:00" -End "2023-12-26T00:00:00"
New-CsOnlineSchedule -Name "Weihnachten" -FixedSchedule -DateTimeRanges @($DateRange)

#Stephanstag 26.12.2023
$DateRange = New-CsOnlineDateTimeRange -Start "2023-12-26T00:00:00" -End "2023-12-27T00:00:00"
New-CsOnlineSchedule -Name "Stephanstag" -FixedSchedule -DateTimeRanges @($DateRange)

#Show global Holidays
$Schedule = Get-CsOnlineSchedule | Where-Object {$_.Type -eq "Fixed"}
$Schedule | Select-Object Name,  @{label="Start";expression={$_.FixedSchedule.DateTimeRanges[0].Start}}, @{label="End";expression={$_.FixedSchedule.DateTimeRanges[0].End}} | Sort-Object Start

#Add Holiday to AutoAttendant
$AutoAttendantName = "AutoAttendantDemo01"
$HolidayName = "Berchtoldstag"
$HolidaySchedule = Get-CsOnlineSchedule | Where-Object {$_.Name -eq $HolidayName}
$HolidayScheduleName = $HolidaySchedule.Name
$GreetingPrompt = New-CsAutoAttendantPrompt -TextToSpeechPrompt "An Feiertagen sind wir nicht erreichbar"
$MenuOption = New-CsAutoAttendantMenuOption -Action DisconnectCall -DtmfResponse Automatic 
$Menu = New-CsAutoAttendantMenu -Name $HolidayScheduleName -MenuOptions @($MenuOption)
$CallFlow = New-CsAutoAttendantCallFlow -Name $HolidayScheduleName -Menu $Menu -Greetings $GreetingPrompt
$CallHandlingAssociation = New-CsAutoAttendantCallHandlingAssociation -Type Holiday -ScheduleId $HolidaySchedule.Id -CallFlowId $CallFlow.Id
$AutoAttendant = Get-CsAutoAttendant -NameFilter $AutoAttendantName
$AutoAttendant.CallFlows += @($CallFlow)
$AutoAttendant.CallHandlingAssociations += @($CallHandlingAssociation)
Set-CsAutoAttendant -Instance $AutoAttendant

#Remove Holiday from AutoAttendant
$AutoAttendantName = "AutoAttendantDemo01"
$HolidayName = "Neujahr"
$AutoAttendant = Get-CsAutoAttendant -NameFilter $AutoAttendantName
$CallFlows = $AutoAttendant.CallFlows | Where-Object {$_.Name -ne $HolidayName}
$CallFlow = $AutoAttendant.CallFlows | Where-Object {$_.Name -eq $HolidayName}
$CallHandlingAssociations = $AutoAttendant.CallHandlingAssociations | Where-Object {$_.CallFlowId -ne $CallFlow.Id}
$AutoAttendant.CallFlows = @($CallFlows)
$AutoAttendant.CallHandlingAssociations = @($CallHandlingAssociations)
Set-CsAutoAttendant -Instance $AutoAttendant


#Show Holidays from Autoattendant
$AutoAttendantName = "AutoAttendantDemo01"
$AutoAttendant = Get-CsAutoAttendant -NameFilter $AutoAttendantName
$AutoAttendant.Schedule
$AutoAttendantHolidays = Get-CsAutoAttendantHolidays -Identity $AutoAttendant.Identity
$AutoAttendantHolidays
$AutoAttendantHolidays.DateTimeRanges


#Update Holiday 2024
$HolidayName = "Neujahr"
$DateRange = New-CsOnlineDateTimeRange -Start "2024-01-01T00:00:00" -End "2024-01-02T00:00:00"
$Neujahr = Get-CsOnlineSchedule | Where-Object {$_.Name -eq $HolidayName}
$Neujahr.FixedSchedule.DateTimeRanges = $DateRange
Set-CsOnlineSchedule -Instance $Neujahr