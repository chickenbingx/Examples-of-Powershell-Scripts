<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Generate-UUDentists {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$Sites
    )

    Begin {

        Import-Module ActiveDirectory -Force
        Import-Module SQLSERVER -Force

        function Create-UUDentists {
            [CmdletBinding()]
            [Alias()]
            [OutputType([int])]
            Param
            (
                # Param1 help description
                [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName = $true,
                    Position = 0)]
                $Site
            )

            Begin {

                $Data = Invoke-Sqlcmd -ServerInstance "sql6\sites" -Database "UniqueUsers" -Query "Select * from UniqueUsers where Practice_ID = '$site'" ##imports csv of clinicians for the site inputted above
                $DestinationOU = "OU=Live_Accounts,OU=Unique_User_Project,OU=Clinician - users,OU=Practice - Users,OU=IDH_Users,OU=Managed,DC=idh,DC=local" ##OU where Dentists will live
                $Role = "Dentist" ##This will be used later on in the script for creating users
                $DC = "IDH-HOPDC" ## This is the DC we will be working off
                $Date = Get-Date -Format "dd_MM_yy" ##Date which will be used later in the script 
                $45 = (Get-Date).AddDays(-45)
                $Type = "Dentist"
                ##This will start a foreach loop. It will process each dentist from $Data.

            }
            Process {

                foreach ($Dentist in $Data) {
                          
                    ###################Password Generator#############################################
                    $Special = @( "!", "$", "%", "&", "*", "@", "-", "?")
                    $Numbers = 10..99
                    $Upper = [char[]]([char]'A'..[char]'Z')
                    $Lower = [char[]]([char]'a'..[char]'z')

                    $Letters = @()
                    $Nums = @()
                    $Spec = @()

                    $Letters += Get-Random -InputObject $Upper -Count 4
                    $Letters += Get-Random -InputObject $Lower -Count 4
                    $Nums += Get-Random -InputObject $Numbers -Count 3
                    $Spec += Get-Random -InputObject $Special -Count 1

                    $LetterPass = ($Letters | Sort-Object { Get-Random }) -join ''
                    $NumPass = ($Nums | Sort-Object { Get-Random }) -join ''
                    $SpecPass = ($Spec | Sort-Object { Get-Random }) -join ''

                    $Password = $LetterPass + $NumPass + $Spec
                    $EncryptedPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

                    ###################################################################################
                          
                    $Siteno = $Dentist."Practice_ID"##Stores the dentists site number for later user
                    $PD = Import-Csv "\\myd-fs\Departments\IT Infrastructure Project Work\UU\PD\Practice Directory Export.csv" | where Practice -eq $Siteno ##gets practice directory infomation from a central document
                    $Username = "GDC" + ($dentist.GDC_Number -replace "[a-z]").TrimEnd() ##Makes sure the username is GDC...

                    [bool] $UserExist = [bool](Get-ADUser -Filter { Samaccountname -eq $Username } -Server $DC)##Checks to see if the user exists already in AD

                    Switch ($UserExist) {
                        "True" {
                        
                            $User = Get-ADUser -Identity $Username -Server $DC -Properties LastLogondate ## Gets AD infomation on the user
                            $GroupSearch = "$site" + "_Sec*" ##This will allow us to search for things with the name "Sitenumber_Sec*". Anything after the '*' is allowed
                            $groups = @('Sharepoint_Clinician', 'Office365_SSPR_Security') ##This is an array which holds groups that the user will need to be a part of.
                            $Groups += Get-ADGroup -Filter { Name -like $GroupSearch } -Server $DC | select -ExpandProperty Name ##This uses the "Sitenumber_Sec*" to check Ad for any groups which match that criteria.


                            ##foreach loop to add the user into each group in $Groups
                            foreach ($Group in $Groups) {
                                                                                
                                Add-ADGroupMember -Identity "$Group" -Members $Username -Server $DC 
                                                                                 
                            }

                            if ($User.LastLogonDate -le $45) {
                                                       
                                $SQL = Invoke-Sqlcmd -ServerInstance SQL6\Sites -Database UniqueUsers -Query "Select * from UU_Rollout_PWD_Audit" ##Gether previous passwords from the SQL db and store this in a var
                                                       
                                if ($SQL.Username -contains $Username) {
                                                                                          
                                    $CurrentSites = $SQL | where Username -eq $Username | select -ExpandProperty Siteno

                                    if ($CurrentSites -notcontains $Siteno) {
                                                                                                                                
                                        $CurrentPassword = Invoke-Sqlcmd -ServerInstance SQL6\Sites -Database UniqueUsers -Query "Select Password from UU_Rollout_PWD_Audit Where Username = '$Username'" | select -Unique -ExpandProperty Password

                                        Set-ADUser -Identity $Username -Enabled $True -Server $DC
                                        Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC

                                        $SQLInput = [ordered]@{
                                            "SiteNo"        = $Siteno
                                            "Dentist_Name"  = $Dentist.Full_Name
                                            "Username"      = $Username
                                            "Password"      = $CurrentPassword
                                            "Account_Type"  = $Type
                                            "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                            "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                            "Creation_Type" = "Rollout"
                                        }
                                        $SQLInput = New-Object PSObject -Property $SQLInput

                                        Write-SqlTableData -ServerInstance "SQL6\Sites" -DatabaseName "UniqueUsers" -TableName UU_Rollout_PWD_Audit -SchemaName dbo -InputData $SQLInput -Force

                                    }

                                                                                          
                                }
                                ELSE {

                                    Set-ADAccountPassword -Identity $Username -NewPassword $EncryptedPassword -Reset -Server $DC
                                    Set-ADUser -Identity $Username -Enabled $True -ChangePasswordAtLogon $True -Server $DC
                                    Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC


                                    $SQLInput = [ordered]@{
                                        "SiteNo"        = $Siteno
                                        "Dentist_Name"  = $Dentist.Full_Name
                                        "Username"      = $Username
                                        "Password"      = $Password
                                        "Account_Type"  = $Type
                                        "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                        "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                        "Creation_Type" = "Rollout"
                                    }
                                    $SQLInput = New-Object psobject -Property $SQLInput
                                    Write-SqlTableData -ServerInstance "SQL6\Sites" -DatabaseName "UniqueUsers" -TableName UU_Rollout_PWD_Audit -SchemaName dbo -InputData $SQLInput -Force

                                }

                            }
                            ELSE {

                                $SQL = Invoke-Sqlcmd -ServerInstance SQL6\Sites -Database UniqueUsers -Query "Select * from UU_Rollout_PWD_Audit"

                                if ($SQL.Username -contains $Username) {

                                    $CurrentSites = $SQL | where Username -eq $Username | select -ExpandProperty Siteno

                                    if ($CurrentSites -notcontains $Siteno) {

                                        Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC

                                        $SQLInput = [ordered]@{
                                            "SiteNo"        = $Siteno
                                            "Dentist_Name"  = $Dentist.Full_Name
                                            "Username"      = $Username
                                            "Password"      = "Account in use"
                                            "Account_Type"  = $Type
                                            "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                            "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                            "Creation_Type" = "Rollout"
                                        }
                                        $SQLInput = New-Object psobject -Property $SQLInput
                                        Write-SqlTableData -ServerInstance "SQL6\Sites" -DatabaseName "UniqueUsers" -TableName UU_Rollout_PWD_Audit -SchemaName dbo -InputData $SQLInput -Force

                                    }
                                }
                                ELSE {

                                    Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC

                                    $SQLInput = [ordered]@{
                                        "SiteNo"        = $Siteno
                                        "Dentist_Name"  = $Dentist.Full_Name
                                        "Username"      = $Username
                                        "Password"      = "Account in use"
                                        "Account_TYpe"  = $Type
                                        "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                        "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                        "Creation_Type" = "Rollout"
                                    }
                                    $SQLInput = New-Object psobject -Property $SQLInput
                                    Write-SqlTableData -ServerInstance "SQL6\Sites" -DatabaseName "UniqueUsers" -TableName UU_Rollout_PWD_Audit -SchemaName dbo -InputData $SQLInput -Force

                                }

                            }
                        
                        }
                        "False" {
                         
                            $PD = Import-Csv "\\myd-fs\Departments\IT Infrastructure Project Work\UU\Script\Practice Directory Export.csv" | where Practice -EQ $Siteno
                            $Practice = $PD.'Current Name'
                            $Role = "Dentist"
                            $FullName = $Dentist.Forename + ' ' + $Dentist.Surname + ' ' + "($Role)"
                            $Email = "$UserName@mydentistassociates.co.uk"
                            $Desc = "$Siteno - $Practice"
                            $groups = @('Sharepoint_Clinician')
                            $GroupSearch = "$siteno" + "_sec*"
                            $Groups += Get-ADGroup -Filter { Name -like $GroupSearch } -Server $DC | select -ExpandProperty Name

                            New-ADUser `
                                -GivenName $Dentist.Forename `
                                -Surname $Dentist.Surname `
                                -Name "$FullName" `
                                -DisplayName "$FullName" `
                                -SamAccountName $Username `
                                -EmailAddress $Email `
                                -UserPrincipalName $Email `
                                -HomePhone $PD.Phone `
                                -Description $Desc `
                                -Department $Desc `
                                -Office $PD.Practice `
                                -Path $DestinationOU `
                                -Title $Role `
                                -Server $DC `

                            foreach ($Group in $Groups) {
                                                                                 
                                Add-ADGroupMember -Identity "$Group" -Members $Username -Server $DC
                                                                                 
                            }

                                                
                            Set-ADAccountPassword -Identity $Username -NewPassword $EncryptedPassword -Reset -Server $DC
                            Set-ADUser -Identity $Username -Enabled $True -ChangePasswordAtLogon $True -Server $DC

                            $SQLInput = [ordered]@{
                                "SiteNo"        = $Siteno
                                "Dentist_Name"  = $Dentist.Full_Name
                                "Username"      = $Username
                                "Password"      = $Password 
                                "Account_Type"  = $Type
                                "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                "Creation_Type" = "Rollout"
                            }
                            $SQLInput = New-Object psobject -Property $SQLInput
                            Write-SqlTableData -ServerInstance "SQL6\Sites" -DatabaseName "UniqueUsers" -TableName UU_Rollout_PWD_Audit -SchemaName dbo -InputData $SQLInput -Force
                         
                        }
                    }                       
                }

            }
            End {
            }
        }

        function Report-UU {
            [CmdletBinding()]
            [Alias()]
            [OutputType([int])]
            Param
            (
                # Param1 help description
                [Parameter(Mandatory = $true,
                    ValueFromPipelineByPropertyName = $true,
                    Position = 0)]
                [int]$Siteno
            )

            Begin {

                $DBServer = "SQL6\sites"
                $DBName = "UniqueUsers"
                $PSUSer = ($env:USERNAME).TrimEnd('1')
                $Query = "Select * from UU_Rollout_PWD_Audit where SiteNo = '$Siteno' and Creation_Type = 'Rollout'"
                $exportFolder = "C:\Users\$PSUSer\Box\Departments\IT\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\Project Requests"
                $exportNAme = "Unique Users - Users for $Siteno.xlsx"
                if (Test-Path $exportFolder) {
                         
                    $Export = "$exportFolder" + "\" + "$exportNAme"
                         
                }
                ELSE {

                    $Export = "C:\Users\$PSUSer\Box\Departments\IT\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\Project Requests\" + "$exportNAme"

                }


                if (Test-Path $Export) {
                         
                    Remove-Item $Export -Force

                }
    
            }
            Process {

                $t = Invoke-Sqlcmd -ServerInstance $DBServer -Database $DBName -Query $Query | select Siteno, @{n = "Dentist Name"; e = { $_.Dentist_Name } }, Username, Password, AccountType

                $excel = New-Object -ComObject Excel.Application

                $excel.Visible = $False

                $workbook = $excel.Workbooks.Add()

                $sheet = $workbook.ActiveSheet

                $counter = 1

                $sheet.Cells.Item(1, 1) = 'SiteNo'
                $sheet.Cells.Item(1, 2) = 'Dentist Name'
                $sheet.Cells.Item(1, 3) = 'Username'
                $sheet.Cells.Item(1, 4) = 'Password'
                $sheet.Cells.Item(1, 5) = 'Account Type'

                ForEach ($Dentist in $T) {

                    $counter++

                    $sheet.cells.Item($counter, 1) = $dentist.Siteno

                    $sheet.cells.Item($counter, 2) = $dentist.'Dentist Name'

                    $sheet.cells.Item($counter, 3) = $dentist.'Username'

                    $sheet.cells.Item($counter, 4) = $dentist.'Password'

                    $sheet.cells.Item($counter, 5) = $dentist.'Account_Type'

                }

                $workbook.SaveAs($Export)
                $excel.Quit()
            }
            End {
            }
        }

    }
    Process {

        foreach ($Site in $Sites) {

            Write-Verbose "Generating Dentist for $Site" -Verbose

            Create-UUDentists -Site $Site

            Write-Verbose "Dentists Created" -Verbose

            Report-UU -Siteno $Site

            Write-Verbose "Report Created for $Site" -Verbose

        }

    }
    End {
    }
}