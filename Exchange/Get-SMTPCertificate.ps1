###############################################################################
      # Connect to SMTP Server, check for STARTTLS and then get the Certificate
      # 29.06.2021 V1.0 Andres Bohren - Initial Version
      # 02.08.2022 V1.1 Thomas Nolte - Add optonal ignoring of certifcation errors
      ###############################################################################
      <#
      .SYNOPSIS
        
      .DESCRIPTION
            Connect to SMTP Server, check for STARTTLS and then get the Certificate

      .PARAMETER ServerName
            The Servername of the SMTP Server

      .PARAMETER Port
            The Port of the SMTP Server (25 / 587)

      .PARAMETER Sendingdomain
            The Sendingdomain used in the EHLO

      .PARAMETER IgnoreCertErrors
            Optional ignoring certification errors

      .PARAMETER CertificateFilePath
            Optional a Path to a File for saving the Certificate. Example: C:\GIT_WorkingDir\PowerShellScripts\cer.cer

      .EXAMPLE
            .\Get-SMTPCertificate.ps1 -ServerName "icewolfch.mail.protection.outlook.com" -Port 25 -Sendingdomain "icewolf.ch" -CertificateFilePath "C:\GIT_WorkingDir\PowerShellScripts\cer.cer"

      .LINK
      #>


      param (
            [parameter(Mandatory=$true)][String]$Port,
            [parameter(Mandatory=$true)][String]$ServerName,
            [parameter(Mandatory=$true)][String]$Sendingdomain,
            [parameter(Mandatory=$false)][Bool]$IgnoreCertErrors,
            [parameter(Mandatory=$false)][String]$CertificateFilePath
      )

      #Connect
      Write-Host("Connect $ServerName $Port") -ForegroundColor Green
      $socket = new-object System.Net.Sockets.TcpClient($ServerName, $Port)
      $stream = $socket.GetStream()
      $streamWriter = new-object System.IO.StreamWriter($stream)
      $streamReader = new-object System.IO.StreamReader($stream)
      $stream.ReadTimeout = 5000
      $stream.WriteTimeout = 5000  
      $streamWriter.AutoFlush = $true

      if ($IgnoreCertErrors) {
            $Callback = {param($sender,$cert,$chain,$errors) return $true}
            $sslStream = New-Object System.Net.Security.SslStream($stream, $false, $Callback)
      } else {
            $sslStream = New-Object System.Net.Security.SslStream($stream)
      }

      $sslStream.ReadTimeout = 5000
      $sslStream.WriteTimeout = 5000       
      $ConnectResponse = $streamReader.ReadLine();
      Write-Host($ConnectResponse)
      if(!$ConnectResponse.StartsWith("220")){
            throw "Error connecting to the SMTP Server"
      }

      #Send "EHLO"
      Write-Host(("EHLO " + $Sendingdomain)) -ForegroundColor Green
      $streamWriter.WriteLine(("EHLO " + $Sendingdomain));

      $response = @()
      Try {
            while($streamReader.EndOfStream -ne $true)
            {
                  $ehloResponse = $streamReader.ReadLine();
                  Write-Host($ehloResponse)
                  $response += $ehloResponse
            }
      } catch {

            If ($response -match "STARTTLS")
            {
                  #StartTLS found
                  Write-Host("STARTTLS") -ForegroundColor Green
                  $streamWriter.WriteLine("STARTTLS");
                  $startTLSResponse = $streamReader.ReadLine();
                  Write-Host($startTLSResponse)

                  #Get Certificate
                  $ccCol = New-Object System.Security.Cryptography.X509Certificates.X509CertificateCollection
            $sslStream.AuthenticateAsClient($ServerName,$ccCol,[System.Security.Authentication.SslProtocols]::Tls12,$false)    
                  $Cert = $sslStream.RemoteCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                  If ($Null -ne $CertificateFilePath)
                  {
                        [System.IO.File]::WriteAllBytes($CertificateFilePath, $Cert)
                        Write-Host("File written to " + $CertificateFilePath)
                  }

                  #Show Certificate Details
                  Write-Host ""
                  if ($IgnoreCertErrors) {
                        Write-Host "Ignore certification errors: TRUE"
                  }
                  Write-Host "Issuer: $($sslStream.RemoteCertificate.Issuer)"
                  Write-Host "Subject: $($sslStream.RemoteCertificate.Subject)"
                  Write-Host "ValidFrom: $($sslStream.RemoteCertificate.GetEffectiveDateString())"
                  Write-Host "ValidTo: $($sslStream.RemoteCertificate.GetExpirationDateString())"
                  Write-Host "SerialNumber: $($sslStream.RemoteCertificate.GetSerialNumberString())"
                  Write-Host "Thumbprint: $($sslStream.RemoteCertificate.GetCertHashString())"

                  #Convert to Base64
                  Write-Host ""
                  $StringBuilder = new-Object System.Text.StringBuilder
                  [void]$StringBuilder.AppendLine("-----BEGIN CERTIFICATE-----");
            [void]$StringBuilder.AppendLine([System.Convert]::ToBase64String($cert,[System.Base64FormattingOptions]::InsertLineBreaks))
                  [void]$StringBuilder.AppendLine("-----END CERTIFICATE-----")
                  $CertString = $StringBuilder.Tostring()
                  Write-Host "$CertString"

                  $stream.Dispose()
                  $sslStream.Dispose()

            } else {
                  Write-Host "ERROR: No <STARTTLS> found" -ForegroundColor Red
            }

      }
