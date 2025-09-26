Connect-AzAccount -TenantId icewolfch.onmicrosoft.com
$ResourceGroupName = "RG_AI"
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\AIShell\main.bicep"