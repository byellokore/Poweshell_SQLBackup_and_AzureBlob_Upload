#Default config
$date = Get-Date -UFormat "%Y_%m_%d_%A"
$file = "D:\Prod" + $date + ".bak"
$blob = "Prod_" + $date + ".bak"
$groupName = "Backups"
$container = "sqlbackups"
$text = ""

#Setup Azure
$storageAccount = Get-AzStorageAccount -ResourceGroupName $groupName
$ctx = $storageAccount.Context
Write-Output "Azure Started"

#Start Sql Backup
Try
{
Backup-SqlDatabase -ServerInstance "." -Database "Prod" -BackupFile $file
Write-Output "Backup Finished"
	if ([System.IO.File]::Exists($file))  {
		Write-Output "sending to Azure"
		set-AzStorageblobcontent -File $file -Container $container -Blob $blob -Context $ctx
	}
}
Catch
{
    $text= "File was not uploaded to Azure! $file"	
}

#Remove File
if ([System.IO.File]::Exists($file))  {
	Remove-Item $file 
}

#Start Slack Config
if (!$text.length -gt 0){
	$text= "SAP SQL Server - Daily Backup Finished. >> *$blob Saved on Azure Blob Storage*"
}
$payload = @{
	"channel" = "#it"
	"icon_emoji" = ":bomb:"
	"text" = $text
	"username" = "IT Routines"
}
Send Message To Slack Channel
Invoke-WebRequest `
	-Body (ConvertTo-Json -Compress -InputObject $payload) `
	-Method Post `
	-Uri "your_web_hook" | Out-Null
