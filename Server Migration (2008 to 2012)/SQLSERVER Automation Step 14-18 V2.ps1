$localhost = "LocalHost"
$Datadrive = Read-Host -Prompt "Enter Data Drive Letter"
$Dbs = @('sys2000', 'NG_R4_sys2000', 'Tutor', 'NG_R4_Tutor')

Get-Process -Name "PWM*" | Stop-Process -Force

$Datadrive = $Datadrive + ":\"
$serverswapfilesFolder = "Server_Swap_Files"
$C_serverswapfilesroot = "C:\" + $serverswapfilesFolder
$C_MDFLDFFilesRoot = $C_serverswapfilesroot + "\" + "MDFs, LDFs and LIC"
$C_MDFLDFFiles = Get-ChildItem $c_MDFLDFFilesRoot
$Sys2dataRoot = $Datadrive  + "Sys2data"

switch($C_MDFLDFFiles.Count){
{$_ -le '8'}{

Write-Warning "There are missing MDF, LDF and/or LIC files - Please check manually"

$cont = Read-Host -Prompt "Do you want to proceed with the upgrade without the correct number of files"

switch($cont){
"Y"{

continue

}
"N"{

break

}

}

}
"9"{

Move-Item -Path $C_MDFLDFFiles.FullName -Destination $Sys2dataRoot -Verbose

}

}

$CurrentDbs = Get-SqlDatabase -ServerInstance $localhost 

Start-Sleep 30

foreach($Db in $dbs){

if($CurrentDbs.Name -contains $DB){

Write-Verbose "$DB is already attached" -Verbose

}
else
{

$MDF = $Sys2dataRoot + "\" + "$DB" + ".mdf"
$LDF = $Sys2dataRoot + "\" + "$DB" + "_Log.LDF"

Invoke-Sqlcmd -ServerInstance $localhost -Query "
USE [master]
GO
CREATE DATABASE [$DB] ON
( FILENAME = N'$mdf' ),
( FILENAME = N'$ldf' )
 FOR ATTACH
GO
"

Write-Verbose "Attaching $DB to SQL" -Verbose

}


}

$R4BackupsRoot = $Datadrive  + $serverswapfilesFolder + "\" + "R4BackupFiles"
$R4BackUpFiles = Get-ChildItem $R4BackupsRoot

foreach($BKUP in $R4BackUpFiles){

$DBName = ($BKUP.Name).Split('.')[0]

Restore-SqlDatabase -ServerInstance $localhost -Database $DBName -BackupFile $BKUP.FullName -ReplaceDatabase -verbose

}

Set-Location -Path "C:\"

$DHCPPath = $Datadrive + $serverswapfilesFolder + "\" + "DHCP Backup"

Restore-DhcpServer -Path $DHCPPath -Force

TRY{

$IP = Get-Content -Path ($Datadrive + $serverswapfilesFolder + "\IP.txt")

}
catch{

$IP = Read-Host -Prompt "Cannot find IP. Please type IP"

}

$IPSPlit = $IP.Split('.')
$subnetmask = "255.255.255.192"
$OnetoThreeOctet = $IPSPlit[0] + '.' + $IPSPlit[1] + '.' + $IPSPlit[2]
$LastOctet = $IP.Split('.')[3]

$GatewayOctet = switch($LastOctet){
{$_ -in 1..62}{"62"}
{$_ -in 65..126}{"126"}
{$_ -in 129..190}{"190"}
{$_ -in 193..254}{"254"}
}

$DefaultGateway = $OnetoThreeOctet + '.' + $GatewayOctet
$ComputerName = $env:COMPUTERNAME
$Siteno = $ComputerName.Split('-')[0]

switch($Siteno){
{$_ -in 0..199}{

$PrimaryDNS = "172.30.1.1"
$SecondaryDNS = "172.30.1.11"

}
{$_ -in 200..299}{

$PrimaryDNS = "172.30.1.2"
$SecondaryDNS = "172.30.1.12"

}
{$_ -in 300..499}{

$PrimaryDNS = "172.30.1.3"
$SecondaryDNS = "172.30.1.13"

}
{$_ -in 500..599}{

$PrimaryDNS = "172.30.1.5"
$SecondaryDNS = "172.30.1.15"

}
{$_ -in 600..699}{

$PrimaryDNS = "172.30.1.11"
$SecondaryDNS = "172.30.1.1"

}
{$_ -in 700..799}{

$PrimaryDNS = "172.30.1.12"
$SecondaryDNS = "172.30.1.2"

}
{$_ -in 800..899}{

$PrimaryDNS = "172.30.1.13"
$SecondaryDNS = "172.30.1.3"

}
{$_ -in 900..999}{

$PrimaryDNS = "172.30.1.14"
$SecondaryDNS = "172.30.1.4"

}

}

$NIC = Get-NetAdapter | where InterfaceDescription -like 'VMXnet*'
Disable-NetAdapterBinding -Name $NIC.Name -ComponentID MS_TCPIP6 | Out-Null

New-NetIPAddress -InterfaceIndex $NIC.ifIndex -IPAddress $IP -PrefixLength 26 -DefaultGateway $DefaultGateway
Set-DnsClientServerAddress -InterfaceIndex $NIC.ifIndex -ServerAddresses ("$PrimaryDNS","$SecondaryDNS")

Start-Sleep 10

Add-Computer -DomainName idh.local -Credential (Get-Credential -UserName "wxho\tturner1" -Message "Enter password to join domain")