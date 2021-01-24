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
function New-UUADHoc {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $ForeName,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        $Surname,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        $GDC,
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 3)]
        [validateSet('Dentist', 'Hygienist', 'Therapist', 'Orthodontist')]$AccountType,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 4)]
        $SiteNo,

        [Parameter(ParameterSetName = 'DentistPerform',
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 5)]
        [validateSet('Private', 'NHS')]$Perform,

        [Parameter(Mandatory = $True,
            ValueFromPipelineByPropertyName = $true,
            Position = 6)]
            [validateSet('Helpdesk', 'ADHOC')]$Request
    )

    Begin {

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

        $LetterPass = ($Letters | Sort-Object {Get-Random}) -join ''
        $NumPass = ($Nums | Sort-Object {Get-Random}) -join ''
        $SpecPass = ($Spec | Sort-Object {Get-Random}) -join ''

        $Password = $LetterPass + $NumPass + $SpecPass
        $EncryptedPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

        ###################################################################################

        
        $DestinationOU = "OU=Live_Accounts,OU=Unique_User_Project,OU=Clinician - users,OU=Practice - Users,OU=IDH_Users,OU=Managed,DC=idh,DC=local"  
        $45 = (Get-Date).AddDays(-45)
        $DBServer = "SQL6\Sites"
        $DBName = "UniqueUsers"
        $UUTable = "UU_RollOut_PWD_Audit"
        $Data = Invoke-Sqlcmd -ServerInstance $DBServer -Database $DBName -Query "Select * from UniqueUsers where Practice_ID = '$site'" 
        $DC = "IDH-HOPDC"

        If ($GDC -like "GDC*") {
                     
            $GDC = "GDC" + ($GDC -replace "[a-z]").TrimEnd()                     

        }
        ##$GDC = "GDC" + ($GDC -replace "[a-z]").TrimEnd()
        $PD = Import-Csv "C:\PSScripts\Useful\Practice Directory Export.csv" | where Practice -eq $Site
        $FullName = $Forename + ' ' + $Surname + ' ' + "($Role)"
        $groups = @('Sharepoint_Clinician', 'Office365_SSPR_Security')
        $Email = "$GDC@mydentistassociates.co.uk"
        $Practice = $PD.'Current Name'
        $Desc = "$Site - $Practice"
        $DC = 'IDH-HOPDC'
        $LicExportLive = "C:\Users\tturner\Documents\Infra\O365\Licenses\User Creation - License Application.csv"
        $OU = "OU=Live_Accounts,OU=Unique_User_Project,OU=Clinician - users,OU=Practice - Users,OU=IDH_Users,OU=Managed,DC=idh,DC=local"
        $UserCheck = [bool] (Get-ADUser -Filter {Samaccountname -eq $GDC} -Server $DC)
        $groups = @('Sharepoint_Clinician', 'Office365_SSPR_Security')
        $GroupSearch = "$site" + "_Sec*"
        $Groups += Get-ADGroup -Filter {Name -like $GroupSearch} -Server $DC | select -ExpandProperty Name

        Switch ($AccountType) {
            'Dentist' {
                                                                                                                              
                if ($Perform -eq 'Private') {

                    $groups += 'Office365_F1_Security'
                    $GroupSearch = "$siteno" + "_sec*"
                    $Groups += Get-ADGroup -Filter {Name -like $GroupSearch} -Server $DC | select -ExpandProperty Name                                                                                     

                }
                ELSE {
                    $groups += 'Office365_F1(Sharepoint)_Security'
                    $GroupSearch = "$siteno" + "_sec*"
                    $Groups += Get-ADGroup -Filter {Name -like $GroupSearch} -Server $DC | select -ExpandProperty Name

                }

                if ($Perform -eq $Null) {
                                                           
                    $groups += 'Office365_F1(Sharepoint)_Security'                    
                    $GroupSearch = "$siteno" + "_sec*"
                    $Groups += Get-ADGroup -Filter {Name -like $GroupSearch} -Server $DC | select -ExpandProperty Name
                                                                                  
                }

            }
            Default {
                                                           
                $groups = @('Sharepoint_Clinician')
                $GroupSearch = "$siteno" + "_sec*"
                $Groups += Get-ADGroup -Filter {Name -like $GroupSearch} -Server $DC | select -ExpandProperty Name
                                                                                                                 
            }
                                                 
        }
                                                 
        ##################################################################
       
    }

#######################################################################################

    Process {

        switch ($UserCheck) {
            'True' {
                            
                #Write-Verbose "$GDC is already " -Verbose
                        
                            
                $User = Get-ADUser -Identity $GDC -Server $DC -Properties LastLogondate
                $DentistName = $User.Name.Replace("(Dentist)", "")
                $DentistName = $DentistName.TrimEnd()

                foreach ($Group in $Groups) {
                                                                                
                    Add-ADGroupMember -Identity "$Group" -Members $GDC -Server $DC 
                                                                                 
                }

                if ($User.LastLogonDate -le $45) {
                                                          
                    $SQL = Invoke-Sqlcmd -ServerInstance $DBServer -Database $DBName -Query "Select * from $UUTable"

                    if ($SQL.Username -contains $GDC) {
                            
                        $CurrentSites = $SQL | where Username -eq $GDC | select -ExpandProperty Siteno

                        if ($CurrentSites -notcontains $Siteno) {
                                                                
                            $CurrentPassword = Invoke-Sqlcmd -ServerInstance $DBServer -Database $DBName -Query "Select Password from $UUTable Where Username = '$GDC'" | select -Unique -ExpandProperty Password
                          
                            Set-ADUser -Identity $User.SamAccountName -Enabled $True -Server $DC
                            Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC

                            $SQLInput = [ordered]@{
                                "SiteNo"        = $Siteno
                                "Dentist_Name"  = $DentistName
                                "Username"      = $GDC
                                "Password"      = $CurrentPassword
                                "Account_Type"  = $AccountType
                                "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                "Creation_Type" = "Adhoc"
                            }

                            $SQLInput = New-Object PSObject -Property $SQLInput
                            Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $UUTable -SchemaName dbo -InputData $SQLInput -Force
                                                                
                        }
                        ELSE {

                            Write-Verbose "$GDC already in DB against that site number" -Verbose

                            $GG = $True

                        }

                                                            
                                                                                                       
                    }
                    ELSE {

                        Set-ADAccountPassword -Identity $User.ObjectGUID -NewPassword $EncryptedPassword -Reset -Server $DC
                        Set-ADUser -Identity $User.ObjectGUID -Enabled $True -ChangePasswordAtLogon $True -Server $DC
                        Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC


                        $SQLInput = [ordered]@{
                            "SiteNo"        = $Siteno
                            "Dentist_Name"  = $DentistName
                            "Username"      = $GDC
                            "Password"      = $Password
                            "Account_Type"  = $AccountType
                            "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                            "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                            "Creation_Type" = "Adhoc"
                        }
                        $SQLInput = New-Object psobject -Property $SQLInput
                        Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $UUTable -SchemaName dbo -InputData $SQLInput -Force

                    }
                                                               
                                                               
                }
                ELSE {

                    $SQL = Invoke-Sqlcmd -ServerInstance $DBServer -Database $DBName -Query "Select * from $UUtable"
                    if ($SQL.Username -contains $GDC) {

                        $CurrentSites = $SQL | where Username -eq $GDC | select -ExpandProperty Siteno
                                                            
                        if ($CurrentSites -notcontains $Siteno) {
                                                                   
                            Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC

                            $SQLInput = [ordered]@{
                                "SiteNo"        = $Siteno
                                "Dentist_Name"  = $DentistName
                                "Username"      = $GDC
                                "Password"      = "Account in use"
                                "Account_Type"  = $AccountType
                                "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                                "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                                "Creation_Type" = "Adhoc"
                            }
                            $SQLInput = New-Object psobject -Property $SQLInput
                            Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $UUTable -SchemaName dbo -InputData $SQLInput -Force

                        }
                    }
                    else {

                        Move-ADObject -Identity $User.ObjectGUID -TargetPath $DestinationOU -Server $DC

                        $SQLInput = [ordered]@{
                            "SiteNo"        = $Siteno
                            "Dentist_Name"  = $DentistName
                            "Username"      = $GDC
                            "Password"      = "Account in use"
                            "Account_TYpe"  = $AccountType
                            "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                            "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                            "Creation_Type" = "Adhoc"
                        }
                        $SQLInput = New-Object psobject -Property $SQLInput
                        Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $UUTable -SchemaName dbo -InputData $SQLInput -Force
          
          
                                                                                                            
                                                                                          
                    }
                }
                                                          
                                                          

            }
            'False' {
                             
                $Practice = $PD.'Current Name'
                $Role = "$AccountType"
                $DentistName = $ForeName + ' ' + $Surname
                $FullName = $DentistName + ' ' + "($Role)"
                $Email = "$GDC@mydentistassociates.co.uk"
                $Desc = "$Siteno - $Practice"

                New-ADUser `
                    -GivenName $Forename `
                    -Surname $Surname `
                    -Name "$FullName" `
                    -DisplayName "$FullName" `
                    -SamAccountName $GDC `
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
                                                                                 
                    Add-ADGroupMember -Identity "$Group" -Members $GDC -Server $DC
                                                                                 
                }

                Set-ADAccountPassword -Identity $GDC -NewPassword $EncryptedPassword -Reset -Server $DC
                Set-ADUser -Identity $GDC -Enabled $True -ChangePasswordAtLogon $True -Server $DC

                $SQLInput = [ordered]@{
                    "SiteNo"        = $Siteno
                    "Dentist_Name"  = $DentistName
                    "Username"      = $GDC
                    "Password"      = $Password 
                    "Account_Type"  = $AccountType
                    "Modifiedby"    = "$Env:USERDOMAIN\$Env:USERNAME"
                    "ModifiedDate"  = Get-Date -Format "dd/MM/yyyy HH:mm"
                    "Creation_Type" = "Adhoc"
                }
                $SQLInput = New-Object psobject -Property $SQLInput
                Write-SqlTableData -ServerInstance $DBServer -DatabaseName $DBName -TableName $UUTable -SchemaName dbo -InputData $SQLInput -Force


            }
        }

    }

####################################################################################
    End {
            
$PSUSer = ($env:USERNAME).TrimEnd('1')
            $Query = "Select * from $UUTable where SiteNo = '$Siteno' and Creation_Type = 'Adhoc'"

            Switch($Request){
                            'Helpdesk'{

                            $exportFolder = "C:\Users\$PSUSer\Box\Departments\IT\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\Helpdesk Requests"

                            if(!(Test-Path $exportFolder)){
                                                       
                                                          $exportFolder = "C:\Users\$PSUSer\Box\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\Helpdesk Requests"
                                                       
                                                          }

                            $exportNAme = "Unique Users - Users for $Siteno (Helpdesk).xlsx"

                                      }
                            'ADHOC'{

                            $exportFolder = "C:\Users\$PSUSer\Box\Departments\IT\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\Adhoc Requests"

                                    if(!(Test-Path $exportFolder)){
                                                                  
                                                                  $exportFolder = "C:\Users\$PSUSer\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\Adhoc Requests"
                                                                  
                                                                  }

                                   
                                   $exportNAme = "Unique Users - Users for $Siteno (ADHOC).xlsx"
                                   }
                            }
    
            if (Test-Path $exportFolder) {
                         
                $Export = "$exportFolder" + "\" + "$exportNAme"
                         
            }
            ELSE {

                $Export = "C:\Users\$PSUSer\Box\Departments\IT\IT - Infrastructure - Box\Projects\Unique Users\Clinician Accounts Created\" + "$exportNAme"

            }


            if (Test-Path $Export) {
                         
                Remove-Item $Export -Force

            }

            $t = Invoke-Sqlcmd -ServerInstance $DBServer -Database $DBName -Query $Query | select Siteno, @{n = "Dentist Name"; e = {$_.Dentist_Name}}, Username, Password, Account_Type

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
            <#
            if (Get-Process Excel) {
                     
                Get-Process excel | Stop-Process -Force
                     
            }
            #>

        }


    }