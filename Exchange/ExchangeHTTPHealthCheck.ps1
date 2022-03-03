########################################################################################
# Loadbalancer Check for Exchange Server
########################################################################################

$ExchangeServer = "mail.icewolf.ch"
#$AllProtocols = [System.Net.SecurityProtocolType]'Tls11,Tls12'
#[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$OWA = "https://$ExchangeServer/owa/healthcheck.htm"
$ECP = "https://$ExchangeServer/ecp/healthcheck.htm"
$RPC = "https://$ExchangeServer/rpc/healthcheck.htm"
$EWS = "https://$ExchangeServer/ews/healthcheck.htm"
$MAPI = "https://$ExchangeServer/mapi/healthcheck.htm"
$OAB = "https://$ExchangeServer/oab/healthcheck.htm"
$EAS = "https://$ExchangeServer/Microsoft-Server-ActiveSync/healthcheck.htm"
$AutoDiscover = "https://$ExchangeServer/autodiscover/healthcheck.htm"
$OWAResponse = (Invoke-WebRequest -Uri $OWA).RawContent
if ($OWAResponse -match "200 OK
")
{
write-host "OWA:    OK" -foregroundcolor green
}
else
{
write-host "OWA:    Fehler" -foregroundcolor red
}
$ECPResponse = (Invoke-WebRequest -Uri $ECP).RawContent
if ($ECPResponse -match "200 OK
")
{
write-host "ECP:    OK" -foregroundcolor green
}
else
{
write-host "ECP:    Fehler" -foregroundcolor red
}
$RPCResponse = (Invoke-WebRequest -Uri $RPC).RawContent
if ($RPCResponse -match "200 OK
")
{
write-host "RPC:    OK" -foregroundcolor green
}
else
{
write-host "RPC:    Fehler" -foregroundcolor red
}
$EWSResponse = (Invoke-WebRequest -Uri $EWS).RawContent
if ($EWSResponse -match "200 OK
")
{
write-host "EWS:    OK" -foregroundcolor green
}
else
{
write-host "EWS:    Fehler" -foregroundcolor red
}
$MAPIResponse = (Invoke-WebRequest -Uri $MAPI).RawContent
if ($MAPIResponse -match "200 OK
")
{
write-host "MAPI:   OK" -foregroundcolor green
}
else
{
write-host "MAPI:   Fehler" -foregroundcolor red
}
$OABResponse = (Invoke-WebRequest -Uri $OAB).RawContent
if ($OABResponse -match "200 OK
")
{
write-host "OAB:    OK" -foregroundcolor green
}
else
{
write-host "OAB:    Fehler" -foregroundcolor red
}
$EASResponse = (Invoke-WebRequest -Uri $EAS).RawContent
if ($EASResponse -match "200 OK
")
{
write-host "EAS:    OK" -foregroundcolor green
}
else
{
write-host "EAS:    Fehler" -foregroundcolor red
}
$AutodiscoverResponse = (Invoke-WebRequest -Uri $Autodiscover).RawContent
if ($AutodiscoverResponse -match "200 OK
")
{
write-host "Autodiscover:   OK" -foregroundcolor green
}
else
{
write-host "Autodiscover:   Fehler" -foregroundcolor red
}