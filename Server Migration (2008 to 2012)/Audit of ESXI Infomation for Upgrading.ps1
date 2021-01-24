$Ips = Import-Csv "C:\Users\tturner\Documents\Infra\Windows Upgrade\Potential ESXI IPs.csv" | Select-Object -ExpandProperty IPs
Import-Module Hyper-V -Prefix HV
$Pass1 = 'Password1'
$Pass2 = 'Password2'
$Pass3 = 'Password3'

$DBServer = 'SQL6\Sites'
$DBName = 'Estate_Upgrade'
$DBHardTableName = 'Host_Info'
$DBPassTableName = 'Server_ESXI_Password'

foreach ($IP in $IPs) {

   if (Test-Connection $IP -ErrorAction SilentlyContinue) {

      Write-Verbose "Connecting to $IP" -Verbose

      try {


         $connect = Connect-VIServer -Server $IP -Username root -Password $Pass1 -ErrorAction Stop

         [bool]$Sucsessful = $True

         $hostinfo = Get-VMHost
         $Manu = $hostinfo.Manufacturer
         $ServModel = $hostinfo.Model
         [int]$MemTotal = [math]::Round($hostinfo.MemoryTotalGB, 1)
         [int]$MemUsage = [math]::Round($hostinfo.MemoryUsageGB, 1)
         $VM = Get-VM

         $PasswordInfo = [ordered]@{
            Server_Name = $VM.Name
            Host_IP     = $IP
            Password    = $Pass1
         }

         $HostHash = [Ordered]@{
            Server_Name  = $VM.Name
            Host_IP      = $IP
            Hypervisor   = "ESXI"
            Manufacturer = $Manu
            Model        = $ServModel
            Memory_Total = $MemTotal
            Memory_Used  = $MemUsage
         }

      }
      catch {
   
         try {

            $connect = Connect-VIServer -Server $IP -Username root -Password $Pass2 -ErrorAction Stop

            [bool]$Sucsessful = $True
            $hostinfo = Get-VMHost
            $Manu = $hostinfo.Manufacturer
            $ServModel = $hostinfo.Model
            [int]$MemTotal = [math]::Round($hostinfo.MemoryTotalGB, 1)
            [int]$MemUsage = [math]::Round($hostinfo.MemoryUsageGB, 1)
            $VM = Get-VM | Where-Object Name -like "*Serv*"

            $PasswordInfo = [ordered]@{
               Server_Name = $VM.Name
               Host_IP     = $IP
               Password    = $Pass2
            }

            $HostHash = [Ordered]@{
               Server_Name  = $VM.Name
               Host_IP      = $IP
               Hypervisor   = "ESXI"
               Manufacturer = $Manu
               Model        = $ServModel
               Memory_Total = $MemTotal
               Memory_Used  = $MemUsage
            }

         }
         Catch {

            Try {


               $connect = Connect-VIServer -Server $IP -Username root -Password $Pass3 -ErrorAction Stop
               [bool]$Sucsessful = $True
               $hostinfo = Get-VMHost
               $Manu = $hostinfo.Manufacturer
               $ServModel = $hostinfo.Model
               [int]$MemTotal = [math]::Round($hostinfo.MemoryTotalGB, 1)
               [int]$MemUsage = [math]::Round($hostinfo.MemoryUsageGB, 1)
               $VM = Get-VM

               $PasswordInfo = [ordered]@{
                  Server_Name = $VM.Name
                  Host_IP     = $IP
                  Password    = $Pass3
               }

               $HostHash = [Ordered]@{
                  Server_Name  = $VM.Name
                  Host_IP      = $IP
                  Hypervisor   = "ESXI"
                  Manufacturer = $Manu
                  Model        = $ServModel
                  Memory_Total = $MemTotal
                  Memory_Used  = $MemUsage
               }

            }
            Catch {
               [bool]$Sucsessful = $False
               $PasswordInfo = [ordered]@{
                  Server_Name = 'Unknown - Bad Password'
                  Host_IP     = $IP
                  Password    = "Unknown - Bad Password"
               }

               $HostHash = [Ordered]@{
                  Server_Name  = 'Unknown - Bad Password'
                  Host_IP      = $IP
                  Hypervisor   = "ESXI"
                  Manufacturer = "Unknown - Bad Password"
                  Model        = "Unknown - Bad Password"
                  Memory_Total = [int]0
                  Memory_Used  = [int]0
               }


            }

         }

      }
      finally {

         $PasswordInfo = New-Object psobject -Property $PasswordInfo
         $hostHash = New-Object PSObject -Property $HostHash

         Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $DBPassTableName -SchemaName dbo -InputData $PasswordInfo
         Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $DBHardTableName -SchemaName dbo -InputData $HostHash

         #$PasswordInfo | Export-Csv "C:\Temp\ESXI\ESXIPWD.csv" -NoTypeInformation -Append
         #$hostHash | Export-Csv "C:\Temp\ESXI\ESXIInfo.csv" -NoTypeInformation -Append

         if ($Sucsessful -eq $True) {
            Disconnect-VIServer -Server $IP -Confirm:$False -Force

         }

      }

   }
   ELSE {

      $PasswordInfo = [ordered]@{
         Server_Name = "Unknown - Cannot Connect"
         Host_IP     = $IP
         Password    = "Unknown - Cannot Connect"
      }

      $HostHash = [Ordered]@{
         Server_Name  = "Unknown - Cannot Connect"
         Host_IP      = $IP
         Hypervisor   = "ESXI"
         Manufacturer = "Unknown - Cannot Connect"
         Model        = "Unknown - Cannot Connect"
         Memory_Total = [int]0
         Memory_Used  = [int]0
      }

      $PasswordInfo = New-Object psobject -Property $PasswordInfo
      $hostHash = New-Object PSObject -Property $hosthash

      Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $DBPassTableName -SchemaName dbo -InputData $PasswordInfo
      Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $DBHardTableName -SchemaName dbo -InputData $HostHash

   }
}