################################################################################
# Create MicrosoftTeamsHolidays 2023
# 24.11.2022 - V1.0 - Initial Version - Andres Bohren
################################################################################

$Shedule = Get-CsOnlineSchedule | Where-Object {$_.Type -eq "Fixed"}
$Shedule.FixedSchedule
$Shedule.FixedSchedule.DateTimeRanges

#Feiertage 2023
#https://www.ferienwiki.ch/feiertage/2023/ch
#https://www.feiertagskalender.ch/index.php?jahr=2023&geo=3056&klasse=5&hl=de&hidepast=1



#Neujahr 01.01.2023
$DateRange = New-CsOnlineDateTimeRange -Start "01/01/2023 00:00" -End "01/01/2023 23:45"
New-CsOnlineSchedule -Name "Neujahr" -FixedSchedule -DateTimeRanges @($DateRange)

#Berchtoldstag	02.01.2023
$DateRange = New-CsOnlineDateTimeRange -Start "01/02/2023 00:00" -End "01/02/2023 23:45"
New-CsOnlineSchedule -Name "Berchtoldstag" -FixedSchedule -DateTimeRanges @($DateRange)

#Heilige Drei Könige	06.01.2023
$DateRange = New-CsOnlineDateTimeRange -Start "01/06/2023 00:00" -End "01/06/2023 23:45"
New-CsOnlineSchedule -Name "Berchtoldstag" -FixedSchedule -DateTimeRanges @($DateRange)

#St. Josef 19.03.2023
$DateRange = New-CsOnlineDateTimeRange -Start "03/19/2023 00:00" -End "03/19/2023 23:45"
New-CsOnlineSchedule -Name "St. Josef" -FixedSchedule -DateTimeRanges @($DateRange)

#Karfreitag	07.04.2023
$DateRange = New-CsOnlineDateTimeRange -Start "04/07/2023 00:00" -End "04/07/2023 23:45"
New-CsOnlineSchedule -Name "Karfreitag" -FixedSchedule -DateTimeRanges @($DateRange)

#Ostersonntag	09.04.2023
$DateRange = New-CsOnlineDateTimeRange -Start "04/09/2023 00:00" -End "04/09/2023 23:45"
New-CsOnlineSchedule -Name "Ostersonntag" -FixedSchedule -DateTimeRanges @($DateRange)

#Sechseläuten	17.04.2023
$DateRange = New-CsOnlineDateTimeRange -Start "04/17/2023 00:00" -End "04/17/2023 23:45"
New-CsOnlineSchedule -Name "Sechseläuten" -FixedSchedule -DateTimeRanges @($DateRange)

#Auffahrt	18.05.2023
$DateRange = New-CsOnlineDateTimeRange -Start "05/18/2023 00:00" -End "05/18/2023 23:45"
New-CsOnlineSchedule -Name "Auffahrt" -FixedSchedule -DateTimeRanges @($DateRange)

#Pfingstmontag	29.05.2023
$DateRange = New-CsOnlineDateTimeRange -Start "05/29/2023 00:00" -End "05/29/2023 23:45"
New-CsOnlineSchedule -Name "Pfingstmontag" -FixedSchedule -DateTimeRanges @($DateRange)

#Fronleichnam	08.06.2023
$DateRange = New-CsOnlineDateTimeRange -Start "06/08/2023 00:00" -End "06/08/2023 23:45"
New-CsOnlineSchedule -Name "Fronleichnam" -FixedSchedule -DateTimeRanges @($DateRange)

#Peter und Paul	29.06.2023
$DateRange = New-CsOnlineDateTimeRange -Start "06/29/2023 00:00" -End "06/29/2023 23:45"
New-CsOnlineSchedule -Name "Peter und Paul" -FixedSchedule -DateTimeRanges @($DateRange)

#Bundesfeier	01.08.2023
$DateRange = New-CsOnlineDateTimeRange -Start "08/01/2023 00:00" -End "08/01/2023 23:45"
New-CsOnlineSchedule -Name "Bundesfeier" -FixedSchedule -DateTimeRanges @($DateRange)

#Mariä Himmelfahrt	15.08.2023
$DateRange = New-CsOnlineDateTimeRange -Start "08/15/2023 00:00" -End "08/15/2023 23:45"
New-CsOnlineSchedule -Name "Mariä Himmelfahrt" -FixedSchedule -DateTimeRanges @($DateRange)

#Genfer Bettag	07.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "09/07/2023 00:00" -End "09/07/2023 23:45"
New-CsOnlineSchedule -Name "Genfer Bettag" -FixedSchedule -DateTimeRanges @($DateRange)

#Knabenschiessen	11.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "09/11/2023 00:00" -End "09/11/2023 23:45"
New-CsOnlineSchedule -Name "Knabenschiessen" -FixedSchedule -DateTimeRanges @($DateRange)

#Eidgenössischer Dank-, Buss- und Bettag	17.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "09/17/2023 00:00" -End "09/17/2023 23:45"
New-CsOnlineSchedule -Name "Knabenschiessen" -FixedSchedule -DateTimeRanges @($DateRange)

#Mauritiustag 	22.09.2023
$DateRange = New-CsOnlineDateTimeRange -Start "09/22/2023 00:00" -End "09/22/2023 23:45"
New-CsOnlineSchedule -Name "Mauritiustag" -FixedSchedule -DateTimeRanges @($DateRange)

#St. Leodegar	02.10.2023
$DateRange = New-CsOnlineDateTimeRange -Start "10/02/2023 00:00" -End "10/02/2023 23:45"
New-CsOnlineSchedule -Name "St. Leodegar" -FixedSchedule -DateTimeRanges @($DateRange)

#Allerheiligen	01.11.2023
$DateRange = New-CsOnlineDateTimeRange -Start "11/01/2023 00:00" -End "11/01/2023 23:45"
New-CsOnlineSchedule -Name "Allerheiligen" -FixedSchedule -DateTimeRanges @($DateRange)

#Mariä Empfängnis	08.12.2023
$DateRange = New-CsOnlineDateTimeRange -Start "12/08/2023 00:00" -End "12/08/2023 23:45"
New-CsOnlineSchedule -Name "Mariä Empfängnis" -FixedSchedule -DateTimeRanges @($DateRange)

#Weihnachten	25.12.2023
$DateRange = New-CsOnlineDateTimeRange -Start "12/25/2023 00:00" -End "12/25/2023 23:45"
New-CsOnlineSchedule -Name "Weihnachten" -FixedSchedule -DateTimeRanges @($DateRange)

#Stephanstag	26.12.2023
$DateRange = New-CsOnlineDateTimeRange -Start "12/26/2023 00:00" -End "12/26/2023 23:45"
New-CsOnlineSchedule -Name "Stephanstag" -FixedSchedule -DateTimeRanges @($DateRange)
