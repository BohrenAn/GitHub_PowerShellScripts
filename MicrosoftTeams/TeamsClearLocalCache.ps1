###############################################################
# Powershell Script to delete the Teams Cache in %APPDATA%
# 09.06.2021 Andres Bohren
###############################################################
Write-Host "Teams wird beendet, um den Cache zu loeschen."
try{
 Get-Process -ProcessName Teams -ErrorAction SilentlyContinue | Stop-Process -Force
 Start-Sleep -Seconds 5
 Write-Host "Microsoft Teams wurde beendet."
} catch{
 echo $_
}

# Der Cache wird nun geloescht / geleert
try{
 If (Test-Path $env:APPDATA\"Microsoft\teams\application cache\cache")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\application cache\cache""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\application cache\cache" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\blob_storage")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\blob_storage""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\blob_storage" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\databases")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\databases""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\databases" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\cache")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\cache""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\cache" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\gpucache")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\gpucache""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\gpucache" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\Indexeddb")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\Indexeddb""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\Indexeddb" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\Local Storage")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\Local Storage""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\Local Storage" | Remove-Item -Recurse -Confirm:$false
 }
 If (Test-Path $env:APPDATA\"Microsoft\teams\tmp")
 {
  Write-Host "Delete > $env:APPDATA\"Microsoft\teams\tmp""
  Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\tmp" | Remove-Item -Recurse -Confirm:$false
 }
}
 catch{
 echo $_
}
write-host "Der Cache wurde erfolgreich geloescht / geleert."
write-host "Teams kann nun wieder gestartet werden"