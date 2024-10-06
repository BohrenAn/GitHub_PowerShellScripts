# Introduction 
This is the Template for Azure DevOps for the deployment of MTA-STS with Azure Static Webiste

# Requirements
- Git
- VSCode
- PowerShell 7.x
- AZ PowerShell Module

# Repo

# Step 1: Clone Template

![](docs/MTA-STS_setup_01.jpg)

![](docs/MTA-STS_setup_02.jpg)

# Step 2: Create New Repository

![](docs/MTA-STS_setup_03.jpg)

Repository name: MTA-STS-[DomainwithoutTLD]

![](docs/MTA-STS_setup_04.jpg)

Clone with VSCode

![](docs/MTA-STS_setup_05.jpg)

Select local Directory

![](docs/MTA-STS_setup_06.jpg)

Open in VSCode 

![](docs/MTA-STS_setup_07.jpg)


Danach den Inhalt mit dem Explorer vom Template in diesen Ordner kopieren

![](docs/MTA-STS_setup_08.jpg)

# Step 3: Depoloy Azure Static Website

Open PowerShell 7

```pwsh
cd to the LocalDirectory\Deployment
.\DeployStaticWebApp.ps1
```

leave the PowerShell open - you will need the Values from the Output

![](docs/MTA-STS_setup_09.jpg)

# Step 4: Update Pipeline.yaml

Update the Variable Group and api_token in the DemoPipeline.yaml

![](docs/MTA-STS_setup_10.jpg)

# Step 5: Commit and Push

Open new Terminal

![](docs/MTA-STS_setup_11.jpg)

Update your Infos

```
git config user.email "a.bohren@icewolf.ch"
git config user.name "Andres Bohren"
```

![](docs/MTA-STS_setup_12.jpg)

Commit in VSVode with Commit Message

![](docs/MTA-STS_setup_13.jpg)

Push Code to Repo

```pwsh
git push
```
![](docs/MTA-STS_setup_14.jpg)

# Step 6: Create Variables in Azure DevOps

Under Pipelines > Library create new Variable Group

![](docs/MTA-STS_setup_15.jpg)

Copy VariableGroup, Variable and Value from the PowerShell Output and "Save"

![](docs/MTA-STS_setup_16.jpg)

# Step 7: Create Pipeline

Go to Pipelines and click on "New Pipeline"

![](docs/MTA-STS_setup_17.jpg)

Azure Repos Git

![](docs/MTA-STS_setup_18.jpg)

Select your Repo

![](docs/MTA-STS_setup_19.jpg)

Existing Azure Pipeline YAML file

![](docs/MTA-STS_setup_20.jpg)

Select the yaml File from the Dropdown

![](docs/MTA-STS_setup_21.jpg)

Check again Variable Group and TokenVariable > then hit "Run"

![](docs/MTA-STS_setup_22.jpg)

Click "View"

![](docs/MTA-STS_setup_23.jpg)

Click "Permit"

![](docs/MTA-STS_setup_24.jpg)

Click "Permit"

![](docs/MTA-STS_setup_25.jpg)

The Pipeline is running and should finish with no error

![](docs/MTA-STS_setup_26.jpg)

# Step 8: Azure Static Website

The PowerShell Script created the Azure Static Website

![](docs/MTA-STS_setup_27.jpg)

The URL can be found in Overview

![](docs/MTA-STS_setup_28.jpg)

After the deployment you can see the Website

![](docs/MTA-STS_setup_29.jpg)

and the mta-sts.txt

![](docs/MTA-STS_setup_30.jpg)

# Step 9: Create DNS Records

Create the DNS Records from the PowerShell Output 

![](docs/MTA-STS_setup_09.jpg)

>id ist einfach ein Datumswert (kann im Prinzip irgendeine Zahl sein)

```
_mta-sts.domain.tld TXT v=STSv1; id=20240223T150000;
mta-sts.domain.tld CNAME xxx.azurestaticapps.net
_smtp._tls.domain.tld TXT v=TLSRPTv1; rua=mailto:tlsrptrecipient@domain.tld
```

# Step 10: Create custom Domain on Azure Static Web App

Auf der Static Web App > Custom Domains > Add 

![](docs/MTA-STS_setup_31.jpg)

mta-sts.domain.tld

![](docs/MTA-STS_setup_32.jpg)

Kann erst hinzugefügt werden, wenn der DNS CNAME Record erstellt wurde

![](docs/MTA-STS_setup_33.jpg)