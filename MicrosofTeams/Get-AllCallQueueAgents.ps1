#Connect to AzureAD
Connect-AzureAD

#Initialize some variables
$skip = 0
$counter = 0
$cqs = @()
$path = "$env:USERPROFILE\Downloads\AllCallQueueAgents_$((Get-Date).ToString('yyyyMMdd')).csv"

#Get all call queues
while(($nextCqs = Get-CsCallQueue -Skip $skip) -ne $null){
	$cqs += $nextCqs
	$skip += 100
	Write-Host "Paging..."
}

$numberOfcqs = $cqs.Count

#Go throught all call queues, get the agents and add them to CSV file
foreach ($cq in $cqs){

	$cqName = $cq.Name
	
	#Show progress bar
	Write-Progress -Activity "Get all Agents" -PercentComplete (($counter*100)/$numberOfcqs) -Status "Processing ($counter of $numberOfcqs): $cqName";

	$agents = $cq.Agents
	
	#Check if call queue has agents
	if ($agents -eq $null) {
	
		Write-Host "No Agents found for $cqName" -ForegroundColor Yellow
		
		#Write to file
		[PSCustomObject]@{
            CallQueueName = $cqName;
            DisplayName =  "No Agents";
            UserPrincipalName = "No Agents"
        } | Export-Csv -Path $path -NoClobber -NoTypeInformation -Encoding UTF8 -Append
	
	} else {
		
		#Resolve GUID from agent in DisplayName an UserPrincipalName
		foreach ($agent in $agents){
			Try {
				$guid = $agent.ObjectId
				
				$aadUser = Get-AzureADUser -ObjectId $guid | Select DisplayName,UserPrincipalName		
				  
				$displayName = $aadUser.DisplayName
				$upn = $aadUser.UserPrincipalName
			
			} catch {
				Write-Host "Agent with $guid NOT found" -ForegroundColor Red
				$displayName = "Account with $guid NOT found"
				$upn = "Account with $guid NOT found"
			}
			
			#Write to file
			[PSCustomObject]@{
				CallQueueName = $cqName;
				DisplayName =  $displayName;
				UserPrincipalName = $upn
			} | Export-Csv -Path $path -NoClobber -NoTypeInformation -Encoding UTF8 -Append

		}
	}
	
	#Update counter for progress bar
	$counter++
}