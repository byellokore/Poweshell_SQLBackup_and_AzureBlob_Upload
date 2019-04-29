#Default config
$date = Get-Date -UFormat "%Y_%m_%d_%A"
$file = "D:\Backup_" + $date + ".bak"
$blob = "Backup_" + $date + ".bak"
#Change to yours
$groupName = "Backups"
$container = "sqlbackups"
#Setup Azure
$storageAccount = Get-AzStorageAccount -ResourceGroupName $groupName
$ctx = $storageAccount.Context
echo "Azure Started"

#Start Sql Backup
Backup-SqlDatabase -ServerInstance "." -Database "your_database" -BackupFile $file
echo "Backup Finished"
if ([System.IO.File]::Exists($file))  {
    echo "sending to Azure"
    set-AzStorageblobcontent -File $file -Container $container -Blob $blob -Context $ctx
}
#Remove Connection
Remove-Item $file -Force

#Start Slack Config
$payload = @{
	"channel" = "#it"
	"icon_emoji" = ":bomb:"
	"text" = "SAP SQL Server - Daily Backup Finished. >> *$blob Saved on Azure Blob Storage*"
	"username" = "IT Routines"
}
#Send Message To Slack Channel
Invoke-WebRequest `
	-Body (ConvertTo-Json -Compress -InputObject $payload) `
	-Method Post `
	-Uri "webhook to slack" | Out-Null