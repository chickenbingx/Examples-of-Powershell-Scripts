$server = Read-Host -Prompt "Enter Server Name"
$Drive = Read-Host -Prompt "Enter Data Drive Letter"


if((Get-Service -ComputerName $Server -Name MSSQLSERVER).Status -ne "Running"){

Write-Verbose "Turning MSSQLSERVER Service on..." -Verbose

Set-Service -ComputerName $server -Name MSSQLSERVER -StartupType Automatic -Status Running

}
else
{

Write-Verbose "Restarting MSSQLSERVER ..." -Verbose

Get-Service -ComputerName $Server -Name MSSQLSERVER | Restart-Service -Force

}

$Dbs = @('sys2000', 'NG_R4_sys2000', 'Tutor', 'NG_R4_Tutor')

$Drive = "\\" + "$server" + "\" + "$Drive$"
$ServerSwapFilesRoot = $Drive + "\" + "Server_Swap_Files"

$DHCPFolder = $ServerSwapFilesRoot + "\" + "DHCP Backup"

if(!(Test-Path $DHCPFolder)){

New-Item $DHCPFolder -ItemType Directory -Force

}

#Backup-DhcpServer -ComputerName $server -Path $DHCPFolder -Verbose

$PrinterFolder = $ServerSwapFilesRoot + "\" + "Printers"

if(!(Test-Path $PrinterFolder)){

New-Item $PrinterFolder -ItemType Directory -Force

}


if(Test-Path $Drive){

$bkupfolder = $ServerSwapFilesRoot + "\" + "R4BackupFiles"

if(!(Test-Path $bkupfolder)){

New-Item -Path $bkupfolder -ItemType Directory -Force

}

foreach($DB in $Dbs){

$Destination = "$bkupfolder\$DB.bak"

if(Test-Path $Destination){

Remove-Item $Destination -Force

}

Backup-SqlDatabase -ServerInstance $server -Database $DB -BackupFile $Destination -Verbose

}

Start-Sleep -Seconds 40 -Verbose

Get-Service -ComputerName $server -Name MSSQLSERVER | Stop-Service -Force

$sys2data = $Drive + "\" + "Sys2data"

##############################################################################

foreach($DB in $Dbs){

$DBCDriveLocation = "$ServerSwapFilesRoot\MDFs, LDFs and LIC"



if(!(Test-Path $DBCDriveLocation)){

New-Item $DBCDriveLocation -ItemType Directory | Out-Null

}

if($DB -eq "Sys2000"){

$LICLocation = $sys2data + "\" + "$DB.lic"

Move-Item -Path $LICLocation -Destination $DBCDriveLocation -Force

}

$MDF = "$DB" + ".MDF"
$LDF = "$DB" + "_Log.LDF"
$DBFiles = @()
$DBFiles += $sys2data + "\" + $MDF
$DBFiles += $sys2data + "\" + $LDF



foreach($File in $DBFiles){

Write-Verbose "copying $File to $DBCDriveLocation" -Verbose

Move-Item -Path $File -Destination $DBCDriveLocation -Force

}

}

$ScriptPath = "\\it-pc-tturner\D$\Users\tturner\Documents\Infra\SQL_Server Upgrade\Automation\Version 1\SQLSERVER Automation Step 14-18*"
$CentralStorePath = "\\myd-fs\Departments\IT General Information\CentralStore_Permissions_Fix\CentralStore_FixPerms.vbs"

Resolve-DnsName $server | where Type -eq "A" | select -ExpandProperty IPaddress | Out-File "$ServerSwapFilesRoot\IP.txt"
Copy-Item -Path $ScriptPath -Destination $ServerSwapFilesRoot -Force
Copy-Item -Path $CentralStorePath -Destination $ServerSwapFilesRoot -Force
Copy-Item -Path "D:\Users\tturner\Documents\Infra\Scripts\BATCH\install CC Services.bat" -Destination $ServerSwapFilesRoot -Force

}
ELSE
{

"Cannot access $Drive"

}

$Final = Read-Host -Prompt "If you havent already, please back up DHCP and Printers on $server. If this has already been done, please enter 'Y' and the server will shutdown"

if($Final -eq 'Y'){

Write-Verbose "Shutting down $server..." -Verbose

Stop-Computer -ComputerName $server -Force

}
else
{

Write-Verbose "You have entered a value which doesnt equal 'Y'. Please shutdown $server manually" -Verbose

}

