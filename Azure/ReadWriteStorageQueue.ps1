###############################################################################
# Read Write Storage Queue with PowerShell
# 23.06.2024 - Initial Version - Andres Bohen
###############################################################################
# Requirements
# - AZ PowerShell Module
# - StorageQueue

#Connect to Azure
Write-Host "Connect to Azure"
Connect-AzAccount -TenantId 46bbad84-29f0-4e03-8d34-f6841a5071ad -Subscription 42ecead4-eae9-4456-997c-1580c58b54ba

#Get Storage Queue
$Storagequeue = Get-AzStorageAccount -Name devicewolf -ResourceGroupName RG_DEV | Get-AzStorageQueue -Name demoqueue
$Storagequeue


#Add Message to Queue
$Message = "icewolf.ch"
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Message)
$MessageBase64  =[Convert]::ToBase64String($Bytes)
$Storagequeue.QueueClient.SendMessageAsync($MessageBase64)


#Get Message from Queue
# Set the amount of time you want to entry to be invisible after read from the queue
# If it is not deleted by the end of this time, it will show up in the queue again
$visibilityTimeout = [System.TimeSpan]::FromSeconds(10)
$queueMessage = $Storagequeue.QueueClient.ReceiveMessage($visibilityTimeout)
$EncodedMessage = $queueMessage.Value.MessageText
$Message = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($EncodedMessage))
Write-Host "Message: $Message"


# Receive one message from the queue, then delete the message.
$visibilityTimeout = [System.TimeSpan]::FromSeconds(10)
$queueMessage = $Storagequeue.QueueClient.ReceiveMessage($visibilityTimeout)
$Storagequeue.QueueClient.DeleteMessage($queueMessage.Value.MessageId, $queueMessage.Value.PopReceipt)