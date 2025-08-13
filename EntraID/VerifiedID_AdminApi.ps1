###############################################################################
# Verified ID Admin API
# 2025-01-29 Initial Version - Andres Bohren
###############################################################################
#Application Permissions
#- VerifiableCredential.Authority.Read
#- VerifiableCredential.Authority.ReadWrite
#- VerifiableCredential.Contract.Read
#- VerifiableCredential.Contract.ReadWrite
#- VerifiableCredential.Credential.Revoke
#- VerifiableCredential.Credential.Search
#- VerifiableCredential.Network.Read
#Delegated Permissions
# - Authentication Policy Administrator
# - Global Administrator

###############################################################################
# PSMSALNet (Delegate Permission WAM)
###############################################################################
#Install-Module PSMSALNet
#Import-Module PSMSALNet
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "da2e568b-3058-48f5-9684-a0116a86656e" # IcewolfVerifiedCredential
$CustomResource = "6a8b4b39-c021-437c-b060-5a14a3fd65f3"
$RedirectURI = "ms-appx-web://microsoft.aad.brokerplugin/$AppID"
$Token = Get-EntraToken -WAMFlow -ClientId $AppID -TenantId $TenantId -RedirectUri $RedirectURI -Resource Custom -CustomResource $CustomResource -Permissions "full_access"
$AccessToken = $token.AccessToken

#View AccessToken
Get-JWTDetails -token $AccessToken

###############################################################################
# PSMSALNet (Delegated Permission)
###############################################################################
#Install-Module PSMSALNet
#Import-Module PSMSALNet
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "da2e568b-3058-48f5-9684-a0116a86656e" # IcewolfVerifiedCredential
$CustomResource = "6a8b4b39-c021-437c-b060-5a14a3fd65f3"
$Permissions = @('full_access')

$HashArguments = @{
    TenantId = $TenantId
    ClientId = $AppID
    RedirectUri = 'http://localhost'
    Resource = 'Custom'
    CustomResource = $CustomResource
    Permissions = $Permissions
}

#Get AccessToken
$Token = Get-EntraToken -PublicAuthorizationCodeFlow @HashArguments
$AccessToken = $token.AccessToken

#View AccessToken
Get-JWTDetails -token $AccessToken

###############################################################################
# PSMSALNet (Application Permission with Certificate)
###############################################################################
#Install-Module PSMSALNet
#Import-Module PSMSALNet
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "da2e568b-3058-48f5-9684-a0116a86656e" # IcewolfVerifiedCredential
$Certificate = Get-Item "Cert:\CurrentUser\My\A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4.cer
$CustomResource = "6a8b4b39-c021-437c-b060-5a14a3fd65f3"

$HashArguments = @{
    TenantId = $TenantId
    ClientId = $AppID
    ClientCertificate = $Certificate
    Resource = 'Custom'
    CustomResource = $CustomResource
}

#Get AccessToken
$Token = Get-EntraToken -ClientCredentialFlowWithCertificate @HashArguments
$AccessToken = $token.AccessToken

#View AccessToken
Get-JWTDetails -token $AccessToken

###############################################################################
# Native Login with ClientSecret (Application Permission)
###############################################################################
$ClientSecret = "YourClientSecret"
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "da2e568b-3058-48f5-9684-a0116a86656e" # IcewolfVerifiedCredential
$ContentType = "application/x-www-form-urlencoded"
$URI = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

#Create Body
$Body = @"
client_id=$AppID
&scope=6a8b4b39-c021-437c-b060-5a14a3fd65f3/.default
&client_secret=$ClientSecret
&grant_type=client_credentials
"@

#Get AccessToken
$Token = Invoke-RestMethod -Uri $URI -Method "Post" -ContentType $ContentType -Body $Body
$AccessToken = $token.access_token

#View AccessToken
Get-JWTDetails -token $AccessToken


###############################################################################
# Native Login with Certificate (Application Permission)
# https://learn.microsoft.com/en-us/answers/questions/346048/how-to-get-access-token-from-client-certificate-ca
###############################################################################
$TenantName = "icewolfch.onmicrosoft.com"
$AppId = "da2e568b-3058-48f5-9684-a0116a86656e" # IcewolfVerifiedCredential
#$CertificateThumbprint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4.cer
$Certificate = Get-Item "Cert:\CurrentUser\My\A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4.cer
$Scope = "6a8b4b39-c021-437c-b060-5a14a3fd65f3/.default" # Example: "https://graph.microsoft.com/.default"

# Create base64 hash of certificate
$CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())

# Create JWT timestamp for expiration
$StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
$JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
$JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)

# Create JWT validity start timestamp  
$NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds  
$NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)

# Create JWT header
$JWTHeader = @{
    alg = "RS256"
    typ = "JWT"
    # Use the CertificateBase64Hash and replace/strip to match web encoding of base64  
    x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='  
}

# Create JWT payload
$JWTPayLoad = @{
    # What endpoint is allowed to use this JWT  
    aud = "https://login.microsoftonline.com/$TenantName/oauth2/token"  

    # Expiration timestamp
    exp = $JWTExpiration

    # Issuer = your application
    iss = $AppId

    # JWT ID: random guid
    jti = [guid]::NewGuid()

    # Not to be used before
    nbf = $NotBefore

    # JWT Subject
    sub = $AppId
}

# Convert header and payload to base64
$JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
$EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)

$JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
$EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)

# Join header and Payload with "." to create a valid (unsigned) JWT
$JWT = $EncodedHeader + "." + $EncodedPayload

# Get the private key object of your certificate
$PrivateKey = ([System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate))

# Define RSA signature and hashing algorithm
$RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
$HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256

# Create a signature of the JWT
$Signature = [Convert]::ToBase64String(
    $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
) -replace '\+','-' -replace '/','_' -replace '='

# Join the signature to the JWT with "."
$JWT = $JWT + "." + $Signature

# Create a hash with body parameters
$Body = @{
    client_id = $AppId
    client_assertion = $JWT
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    scope = $Scope
    grant_type = "client_credentials"
}

$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

# Use the self-generated JWT as Authorization
$Header = @{
    Authorization = "Bearer $JWT"
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method = 'POST'
    Body = $Body
    Uri = $Url
    Headers = $Header
}

$Token = Invoke-RestMethod @PostSplat
$AccessToken = $Token.access_token

#View AccessToken
Get-JWTDetails -token $AccessToken

###############################################################################
# Onboarding - Works only with delegated Authentication
###############################################################################
#POST /v1.0/verifiableCredentials/onboard
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/onboard"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
Invoke-RestMethod -URI $URI -Headers $Headers -Method "POST"

###############################################################################
# List Authorities
###############################################################################
#GET /v1.0/verifiableCredentials/authorities
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Json = Invoke-RestMethod -URI $URI -Headers $Headers
$Json.value

###############################################################################
# Create authority - Only works with Delegated Credentials
###############################################################################
#POST /v1.0/verifiableCredentials/authorities
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$ContentType = "application/json"
$SubscriptionID = "1e467fc0-3227-4628-a048-fc5ef79bff93"
$ResourceGroup = "RG_VerifiableCredentials"
$ResourceName = "DemoAuthorityKeyVault"

#with keVaultMetaData
$Body = @"
{
    "name": "Icewolf Authority",
    "linkedDomainUrl": "https://icewolf.ch",
    "didMethod": "web",
    "template": {
        "type": "VerifiedEmployee"
    },
    "keyVaultMetadata": {
        "subscriptionId": "$SubscriptionID",
        "resourceGroup": "$ResourceGroup",
        "resourceName": "$ResourceName",
        "resourceUrl": "https://$ResourceName.vault.azure.net/"
    }
}
"@

#Create Authority
Invoke-RestMethod -URI $URI -Body $Body -Headers $Headers -Method "POST" -ContentType $ContentType

#You still need to Register Decentralized ID (DID)
#https://icewolf.ch/.well-known/did.json

#You still need to upload DID Configuration JSON
#https://icewolf.ch/.well-known/did-configuration.json

###############################################################################
# Generate DID document
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/generateDidDocument
#https://icewolf.ch/.well-known/did.json
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/generateDidDocument"
$URI = $BaseURL + $APIURL
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Response = Invoke-WebRequest -URI $URI -Headers $Headers -Method "POST" -ContentType $ContentType
$Response.Content

###############################################################################
# Well-known DID configuration
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/generateWellknownDidConfiguration
#https://icewolf.ch/.well-known/did-configuration.json
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/generateWellknownDidConfiguration"
$URI = $BaseURL + $APIURL
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Response = Invoke-WebRequest -URI $URI -Headers $Headers -Method "POST" -ContentType $ContentType
$Response.Content

<#
I am using an Azure App Service to host the Webiste. Hat do extend the web.config with the MIME Type.
<system.webServer>
    <staticContent>
        <remove fileExtension=".json"/>
        <mimeMap fileExtension=".json" mimeType="application/json"/>
    </staticContent>
#>

###############################################################################
# Check DID JSON
###############################################################################
(Invoke-WebRequest -Uri "https://icewolf.ch/.well-known/did.json" -Method "GET").Content
(Invoke-WebRequest -Uri "https://icewolf.ch/.well-known/did-configuration.json" -Method "GET").Content

###############################################################################
# Validate well-known DID configuration
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/validateWellKnownDidConfiguration
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/validateWellKnownDidConfiguration"
$URI = $BaseURL + $APIURL
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = ""
Invoke-RestMethod -URI $URI -Body $Body -Headers $Headers -Method "POST"

###############################################################################
# Get authority
###############################################################################
#GET /v1.0/verifiableCredentials/authorities/<authorityId>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Json = Invoke-RestMethod -URI $URI -Headers $Headers
$Json

###############################################################################
# Update authority - Works only with delegated Authentication
###############################################################################
#PATCH /v1.0/verifiableCredentials/authorities/<authorityId>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$ContentType = "application/json"

$body = @"
{
    "name":"Icewolf Authority DEMO"
}
"@
#Update Authority
Invoke-RestMethod -URI $URI -Body $Body -Headers $Headers -Method "PATCH" -ContentType $ContentType

###############################################################################
# Delete authority > Works only with delegated Permission
###############################################################################
#DELETE /beta/verifiableCredentials/authorities/<authorityId>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/beta/verifiableCredentials/authorities/$AuthorityId"
$ContentType = "application/json"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
#Delete authority
Invoke-RestMethod -URI $URI -Headers $Headers -Method "DELETE" -ContentType $ContentType

###############################################################################
# Rotate signing key > Caution! Was not able to validate did.json afterwards
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/didInfo/signingKeys/rotate
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/didInfo/signingKeys/rotate"
$URI = $BaseURL + $APIURL
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
Invoke-RestMethod -URI $URI -Headers $Headers -Method "POST"

#You need to update DID JSON and DID Configuration
#https://icewolf.ch/.well-known/did.json
#https://icewolf.ch/.well-known/did-configuration.json

#Could not validate did.json afterwards

###############################################################################
# List contracts
###############################################################################
#GET /v1.0/verifiableCredentials/authorities/<authorityId>/contracts
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Json = Invoke-RestMethod -URI $URI -Headers $Headers
$Json.Value

###############################################################################
# Create contract (Verified Employee)
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/contracts
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$ContentType = "application/json"

<#
$Body = @"
{
    "name": "ExampleContractName1",
    "rules": "<rules JSON>",
    "displays": [{<display JSON}],
}
"@
#>
###############################################################################
# VerifiedEmployee
###############################################################################
$Body = @"
{
    "name": "Verified employee",
    "status": "Enabled",
    "issueNotificationEnabled": false,
    "issueNotificationAllowedToGroupOids": [],
    "availableInVcDirectory": true,
    "rules": {
        "attestations": {
            "accessTokens": [
                {
                    "mapping": [
                        {
                            "outputClaim": "displayName",
                            "required": true,
                            "inputClaim": "displayName",
                            "indexed": false
                        },
                        {
                            "outputClaim": "givenName",
                            "required": false,
                            "inputClaim": "givenName",
                            "indexed": false
                        },
                        {
                            "outputClaim": "jobTitle",
                            "required": false,
                            "inputClaim": "jobTitle",
                            "indexed": false
                        },
                        {
                            "outputClaim": "preferredLanguage",
                            "required": false,
                            "inputClaim": "preferredLanguage",
                            "indexed": false
                        },
                        {
                            "outputClaim": "surname",
                            "required": false,
                            "inputClaim": "surname",
                            "indexed": false
                        },
                        {
                            "outputClaim": "mail",
                            "required": false,
                            "inputClaim": "mail",
                            "indexed": false
                        },
                        {
                            "outputClaim": "revocationId",
                            "required": true,
                            "inputClaim": "userPrincipalName",
                            "indexed": true
                        },
                        {
                            "outputClaim": "photo",
                            "required": false,
                            "inputClaim": "photo",
                            "indexed": false
                        }
                    ],
                    "required": true
                }
            ]
        },
        "validityInterval": 15552000,
        "vc": {
            "type": [
                "VerifiedEmployee"
            ]
        }
    },
    "displays": [
        {
            "locale": "en-US",
            "card": {
                "backgroundColor": "#FFFFFF",
                "description": "This verifiable credential is issued to all members of the Icewolf Authority org.",
                "issuedBy": "Icewolf Authority",
                "textColor": "#000000",
                "title": "Verified Employee",
                "logo": {
                    "description": "Default verified employee logo",
                    "uri": "https://icewolf.ch/images/icewolf_ch.png"
                }
            },
            "consent": {
                "instructions": "Verify your identity and workplace the easy way. Add this ID for online and in-person use.",
                "title": "Do you want to accept the verified employee credential from Icewolf Authority."
            },
            "claims": [
                {
                    "claim": "vc.credentialSubject.givenName",
                    "label": "Name",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.surname",
                    "label": "Surname",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.mail",
                    "label": "Email",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.jobTitle",
                    "label": "Job title",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.photo",
                    "label": "User picture",
                    "type": "image/jpg;base64url"
                },
                {
                    "claim": "vc.credentialSubject.displayName",
                    "label": "Display name",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.preferredLanguage",
                    "label": "Preferred language",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.revocationId",
                    "label": "Revocation id",
                    "type": "String"
                }
            ]
        }
    ],
    "allowOverrideValidityIntervalOnIssuance": false
}
"@

#Create Contract
Invoke-RestMethod -URI $URI -Headers $Headers -Method "POST" -Body $Body -ContentType $ContentType

###############################################################################
# Create contract (Custom Contract)
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/contracts
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$ContentType = "application/json"

###############################################################################
# VerifiedCredentialExpert
###############################################################################
$Body = @"
{
    "name": "Example Contract",
    "rules": {
        "attestations": {
            "idTokenHints": [
                {
                    "mapping": [
                        {
                            "outputClaim": "firstName",
                            "required": false,
                            "inputClaim": "given_name",
                            "indexed": false
                        },
                        {
                            "outputClaim": "lastName",
                            "required": false,
                            "inputClaim": "family_name",
                            "indexed": false
                        }
                    ],
                    "required": false
                }
            ]
        },
        "validityInterval": 2592000,
        "vc": {
            "type": [
                "VerifiedCredentialExpert"
            ]
        }
    },
    "displays": [
        {
            "locale": "en-US",
            "card": {
                "title": "Verified Credential Expert",
                "issuedBy": "Icewolf Authority DEMO",
                "backgroundColor": "#000000",
                "textColor": "#ffffff",
                "logo": {
                    "uri": "https://icewolf.ch/images/icewolf_ch.png",
                    "description": "Icewolf Logo"
                },
                "description": "My Description"
            },
            "consent": {
                "title": "Do you want to accept the Verified Credential Expert VC from Icewolf Authority",
                "instructions": "Verify your Verified Credential Expert. Add this ID for online and in-person use"
            },
            "claims": [
                {
                    "claim": "vc.credentialSubject.firstName",
                    "label": "Name",
                    "type": "String"
                },
                {
                    "claim": "vc.credentialSubject.lastName",
                    "label": "Surname",
                    "type": "String"
                }
            ]
        }
    ]
}
"@

#Create Contract
Invoke-RestMethod -URI $URI -Headers $Headers -Method "POST" -Body $Body -ContentType $ContentType

###############################################################################
# Get contract
###############################################################################
#GET /v1.0/verifiableCredentials/authorities/<authorityId>/contracts/<contractid>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts/$ContractId"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Json = Invoke-RestMethod -URI $URI -Headers $Headers -Method "GET"
$Json
#$Request = Invoke-WebRequest -URI $URI -Headers $Headers -Method "GET"
#$Request.Content

###############################################################################
# Enable through MyAccount - Only with Delegated Credential
###############################################################################
#POST https://verifiedid.did.msidentity.com/v1.0/verifiableCredentials/organizationSettings/myAccount
$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$URI = "https://verifiedid.did.msidentity.com/v1.0/verifiableCredentials/organizationSettings/myAccount"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$ContentType = "application/json"

#Enable through MyAccount
$Body = @"
{"contractIdsEnabled":["$ContractId"]}
"@
Invoke-RestMethod -URI $URI -Headers $Headers -Method "POST" -Body $Body -ContentType $ContentType

#Disable through MyAccount
$Body = @"
{"contractIdsEnabled":[]}
"@
Invoke-RestMethod -URI $URI -Headers $Headers -Method "POST" -Body $Body -ContentType $ContentType

###############################################################################
# Update contract - did not work
###############################################################################
#PATCH /v1.0/verifiableCredentials/authorities/<authorityId>/contracts/<contractid>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$ContractId = "ef2fb8d8-95eb-6c3a-55e0-8400157d7d32" #ExampleContract
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts/$ContractId"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$ContentType = "application/json"

$Body = @"
{
    "issueNotificationAllowedToGroupOids": [
        "503eafb2-021f-4ee2-9942-3d3f91e48e03"
    ]
}
"@

#Update contract
$Json = Invoke-RestMethod -URI $URI -Headers $Headers -Method "PATCH" -Body $Body -ContentType $ContentType

###############################################################################
# Delete Contract (BETA)
###############################################################################
#PATCH /v1.0/verifiableCredentials/authorities/<authorityId>/contracts/<contractid>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/beta/verifiableCredentials/authorities/$AuthorityId/contracts/$ContractId"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
Invoke-RestMethod -URI $URI -Headers $Headers -Method "DELETE"


###############################################################################
# Search Credential
###############################################################################
# Search credential:
# - The Claim Value is case-sensitive.
# - The ContractId and the Claim Value are combined: 88da6a53-8a44-9884-093e-ecc1653af101a.bohren@icewolf.ch
# - The combined string is converted to a Bytearray
# - The ByteArray is hashed with SHA256
# - The SHA256 Hash is Base64 Encoded
# - The Base64 Encoded Value will be URLEncoded
# - Now you can search for the Credential

#GET /v1.0/verifiableCredentials/authorities/<authorityId>/contracts/<contractId>/credentials?filter=indexclaimhash eq {hashedsearchclaimvalue}
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$claimvalue = ("A.Bohren@icewolf.ch").ToLower()

# Create Input Data
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$strInput = "$contractid$claimvalue"
Add-Type -AssemblyName System.Web
$enc = [system.Text.Encoding]::UTF8
$InputBytes = $enc.GetBytes($strInput)
$Base64String = [Convert]::ToBase64String($sha256.ComputeHash($InputBytes))
$hashedsearchclaimvalue = [System.Web.HttpUtility]::UrlEncode($Base64String)

#Create Query
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts/$ContractId/credentials?filter=indexclaimhash eq $hashedsearchclaimvalue"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$JSON = Invoke-RestMethod -URI $URI -Headers $Headers -Method "GET"
$JSON.Value

###############################################################################
# Get Credential
###############################################################################
#GET /v1.0/verifiableCredentials/authorities/<authorityId>/contracts/<contractId>/credentials/<credentialId>
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$CredentialId = "urn:pic:00e59840d54044b59ef7902c40201626"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts/$ContractId/credentials/$CredentialId"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$JSON = Invoke-RestMethod -URI $URI -Headers $Headers
$JSON

###############################################################################
# Revoke Credential
###############################################################################
#POST /v1.0/verifiableCredentials/authorities/<authorityId>/contracts/<contractId>/credentials/<credentialid>/revoke
$AuthorityId = "33467785-7b60-d1f4-d200-2282a9329284"
$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$CredentialId = "urn:pic:00e59840d54044b59ef7902c40201626"
$ContentType = "application/json"
$BaseURL = "https://verifiedid.did.msidentity.com"
$APIURL = "/v1.0/verifiableCredentials/authorities/$AuthorityId/contracts/$ContractId/credentials/$CredentialId/revoke"
$URI = $BaseURL + $APIURL
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = ""
Invoke-RestMethod -URI $URI -Headers $Headers -Body $Body -Method "POST" -ContentType $ContentType

###############################################################################
# Manifest URL is JWT Encoded Information
###############################################################################
# GET https://verifiedid.did.msidentity.com/v1.0/tenants/<TenantId>/verifiableCredentials/contracts/<ContractId>/manifest
#$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
#Use OIDC to get TenantId
$Domain = "icewolf.ch"
$Response = Invoke-WebRequest -UseBasicParsing https://login.windows.net/$($Domain)/.well-known/openid-configuration -TimeoutSec 1
$TenantId = ($Response | ConvertFrom-Json).token_endpoint.Split('/')[3]

$ContractId = "88da6a53-8a44-9884-093e-ecc1653af101"
$ManifestUrl = "https://verifiedid.did.msidentity.com/v1.0/tenants/$TenantId/verifiableCredentials/contracts/$ContractId/manifest"
$Json = Invoke-RestMethod -URI $ManifestURL -Method "GET"
$Accesstoken = $Json.token

#View AccessToken
Get-JWTDetails -token $AccessToken

###############################################################################
# AZ PowerShell Enable Face Check
###############################################################################
#Serveralive
$TenantName = "serveralive.onmicrosoft.com"
$SubscriptionId = "176d5a47-5c8c-4b9d-929c-3e2a1cb9d180" 
$ResourceGroupName = "VerifiedID"

#Icewolf
$TenantName = "icewolfch.onmicrosoft.com"
$SubscriptionId = "42ecead4-eae9-4456-997c-1580c58b54ba" 
$ResourceGroupName = "RG_VerifiableCredentials"

#Connect AZ PowerShell
Connect-AzAccount -Tenant $TenantName -Subscription $SubscriptionId

#Get AZ Resource Provider
Get-AzResourceProvider -ProviderNamespace Microsoft.VerifiedId

#Register AZ Resource Provider
Register-AzResourceProvider -ProviderNamespace Microsoft.VerifiedId

#Get Facecheck
$AuthorityID = "33467785-7b60-d1f4-d200-2282a9329284"
$Location = "North Europe"
$Path = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.VerifiedId/authorities/$AuthorityID`?api-version=2024-01-26-preview"
Invoke-AzRestMethod -Method "GET" -Path $Path

#Enable FaceCheck
$Payload = "{'location':'" + $Location + "'}"
Invoke-AzRestMethod -Method "PUT" -Path $Path -Payload $Payload


#Disable FaceCheck
Invoke-AzRestMethod -Method "DELETE" -Path $Path