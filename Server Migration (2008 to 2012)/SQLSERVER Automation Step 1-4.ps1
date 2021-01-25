if ((Get-Service -Name MSSQLSERVER).Status -ne "Running") {

    Write-Verbose "Turning MSSQLSERVER Service on..." -Verbose

    Set-Service -Name MSSQLSERVER -StartupType Automatic -Status Running

}
else {


    Write-Verbose "Restarting MSSQLSERVER ..." -Verbose

    Get-Service -Name MSSQLSERVER | Restart-Service -Force


}

$Localhost = 'Localhost'
$ServerName = $env:COMPUTERNAME
#$AdminCreds = Get-Credential -UserName "$ServerName\administrator"
$R4DBNames = @('SYS2000', 'Tutor', 'NG_R4_SYS2000', 'NG_R4_Tutor')
$LIC = 'Sys2000.lic'
$DBs = Get-SqlDatabase -ServerInstance $Localhost | where Name -in $R4DBNames

##### Start of Step 1 #####

If ($DBs.Count -ge '1') {

    foreach ($DB in $DBs) {

        $DBName = $DB.Name

        Write-Verbose "Detaching $DBName from $ServerName" -Verbose

        Invoke-Sqlcmd -ServerInstance $Localhost -Query "USE [master]
GO
ALTER DATABASE [$DBName] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'$DBname'
GO
"

    }

}
ELSE {

    Write-Verbose "There is no R4 DBs which need detatching..." -Verbose

}

##### End of Step 1 #####

##### Start of Step 2 #####

Set-Location "c:\"

$DataDrive = (Get-PSDrive | where { $_."Free" -ne $Null -and $_.Name -ne "C" -and $_."Free" -ne "0.00" }).Name
$DataDrive = $DataDrive + ":\"
$sys2data = $DataDrive + "Sys2data"
$CdriveLocationroot = "C:\Server_Swap_Files"

foreach ($DB in $R4DBNames) {

    $DBCDriveLocation = "$CdriveLocationroot\MDFs, LDFs and LIC"

    if (!(Test-Path $DBCDriveLocation)) {

        New-Item $DBCDriveLocation -ItemType Directory | Out-Null

    }

    if ($DB -eq "Sys2000") {

        $LICLocation = $sys2data + "\" + "$DB.lic"

        Write-Verbose "Moving Sys2000 license to $DBCDriveLocation"

        Move-Item -Path $LICLocation -Destination $DBCDriveLocation -Force

    }

    $MDF = "$DB" + ".MDF"
    $LDF = "$DB" + "_Log.LDF"
    $DBFiles = @()
    $DBFiles += $sys2data + "\" + $MDF
    $DBFiles += $sys2data + "\" + $LDF



    foreach ($File in $DBFiles) {

        Write-Verbose "Moving $File to $DBCDriveLocation" -Verbose

        Move-Item -Path $File -Destination $DBCDriveLocation -Force

    }

}




##### Start of Step 3 #####

$ShutdownDescision = Read-Host -Prompt "Step 3 is to shutdown the server. Please enter Y or N?"

switch ($ShutdownDescision) {
    "Y" {

        Stop-Computer -Force

    }
    "N" {

        Write-Host "Please shutdown server manually once you are ready to shutdown" -ForegroundColor Yellow

    }
    default {

        $ShutdownDescision = Read-Host -Prompt "You have entered the wrong input. Please answer with either a 'Y' or 'N'"

        switch ($ShutdownDescision) {
            "Y" {

                Stop-Computer -Force

            }
            "N" {

                Write-Host "Please shutdown server manually once you are ready to shutdown" -ForegroundColor Yellow

            }
            default {

                Write-Host "You have entered an incorrect value again. Please shutdown server manually once you are ready to shutdown" -ForegroundColor Yellow


            }

        }

    }

}

##### End of Step 3 #####