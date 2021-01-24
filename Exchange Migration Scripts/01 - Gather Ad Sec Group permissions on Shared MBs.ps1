Clear-Host

$Sharedmailboxes = Get-Recipient -RecipientTypeDetails SharedMailbox; Write-Warning "Gathering Shared Mailboxes"
$ExchangeGroups = Get-Group -ResultSize Unlimited ; Write-Warning "Gathering Exchange Groups"
$DelegatesToSkip = @("NT AUTHORITY\SELF", "ENWL\svc-BBAdmin")

$Start = 1

$Root = "C:\Temp\Exchange"

Remove-Item "$root\*" -Force

$MailboxAccess = "$root\1 - MailboxAccess_Users.csv"
$MailboxAccessOrphanedSids = "$root\1 - MailboxAccess_OrphanedSids.csv"

$SendAsPermission = "$root\2 - SendAs_Users.csv"
$SendAsPermissionOrphanedSids = "$root\2 - SendAs_OrphanedSids.csv"

$SendOnBehalfPermission = "$root\3 - SendOnBehalf_Users.csv"
$SendOnBehalfPermissionOrphanedSids = "$root\3 - SendOnBehalf_OrphanedSids.csv"

$FolderPermissionsCSV = "$Root\4 - FolderPermissions_Users.csv"



foreach ($Mailbox in $Sharedmailboxes) {
  
    Write-Verbose "$($Mailbox.PrimarySmtpAddress) ($($Start) of $($Sharedmailboxes.Count))" -Verbose
    
    ## Get Access Permissions ##

    $AccessPermissions = Get-MailboxPermission $Mailbox.PrimarySmtpAddress | Where-Object { $DelegatesToSkip -notcontains $_.User -and $_.IsInherited -eq $false }

    foreach ($Member in $AccessPermissions) {

        Switch -Wildcard ($Member.User) {
            "S-1-5-21-4001338897*" {

                $Hash = [ordered]@{
                    MailboxName  = $Mailbox.Name
                    MailboxAlias = $Mailbox.Alias
                    PrimarySMTP  = $Mailbox.PrimarySmtpAddress
                    Sid          = $Member.User
                    Permission   = ($Member.AccessRights -join ',')
                }

                $Hash = New-Object PSObject -Property $Hash
                $Hash | Export-Csv $MailboxAccessOrphanedSids -NoTypeInformation -Append

            }
            Default {

                $GroupName = $Member.User.Split('\')[1]

                if ($ExchangeGroups.Name -contains $GroupName) {

                    $GroupMembers = Get-ADGroupMember -Identity $GroupName

                    foreach ($GMember in $GroupMembers) {

                        $Hash = [ordered]@{
                            MailboxName         = $Mailbox.Name
                            MailboxAlias        = $Mailbox.Alias
                            PrimarySMTP         = $Mailbox.PrimarySmtpAddress
                            Mailbox_GUID        = $Mailbox.GUID
                            SecurityGroup       = $GroupName
                            User_SamaccountName = $GMember.SamaccountName
                            User_ObjectClass    = $GMember.ObjectClass
                            Permission          = ($Member.AccessRights -join ',')
                        }

                        $Hash = New-Object PSObject -Property $Hash
                        $Hash | Export-Csv $MailboxAccess -NoTypeInformation -Append

                    }



                }

            }

        }



    }
  

    ## Get Send-As Permissions ##

    $SendAsPerm = Get-ADPermission $Mailbox.DistinguishedName | Where-Object { $DelegatesToSkip -notcontains $_.User -and $_.ExtendedRights -like "*send-as*" }

    foreach ($Member in $SendAsPerm) {

        switch -Wildcard ($Member.User) {
            "S-1-5-21-4001338897*" {
            
                $Hash = [ordered]@{
                    MailboxName  = $Mailbox.Name
                    MailboxAlias = $Mailbox.Alias
                    PrimarySMTP  = $Mailbox.PrimarySmtpAddress
                    Sid          = $Member.User
                    Permission   = ($Member.ExtendedRights -join ',')
                }

                $Hash = New-Object PSObject -Property $Hash
                $Hash | Export-Csv $SendAsPermissionOrphanedSids -NoTypeInformation -Append
            
            
            }
            default {
    
                $GroupName = $Member.User.Split('\')[1]

                if ($ExchangeGroups.Name -contains $GroupName) {
    
                    $GroupMembers = Get-ADGroupMember -Identity $GroupName

                    foreach ($GMember in $GroupMembers) {

                        $Hash = [ordered]@{
                            MailboxName         = $Mailbox.Name
                            MailboxAlias        = $Mailbox.Alias
                            PrimarySMTP         = $Mailbox.PrimarySmtpAddress
                            Mailbox_GUID        = $Mailbox.GUID
                            SecurityGroup       = $GroupName
                            User_SamaccountName = $GMember.SamaccountName
                            User_ObjectClass    = $GMember.ObjectClass
                            Permission          = ($Member.ExtendedRights -join ',')
                        }

                        $Hash = New-Object PSObject -Property $Hash
                        $Hash | Export-Csv $SendAsPermission -NoTypeInformation -Append

                    }
    
                }
    
            }
    
        }
    
    }

    ## Get Send On Behalf of Permissions ##

    $SharedMailbox = Get-Mailbox $Mailbox.DistinguishedName

    foreach ($Member in $SharedMailbox.GrantSendOnBehalfTo) {
     
     
        $GroupName = [string]$Member.split('/')[-1]

        switch ($GroupName) {
            "S-1-5-21-4001338897*" {
            
                $Hash = [ordered]@{
                    MailboxName  = $Mailbox.Name
                    MailboxAlias = $Mailbox.Alias
                    PrimarySMTP  = $Mailbox.PrimarySmtpAddress
                    Sid          = $Member.User
                    Permission   = ($Member.ExtendedRights -join ',')
                }

                $Hash = New-Object PSObject -Property $Hash
                $Hash | Export-Csv $SendOnBehalfPermissionOrphanedSids -NoTypeInformation -Append
            }
            default {
                
                if ($ExchangeGroups.Name -contains $GroupName) {

                    $EG = Get-Group $GroupName
                    $GroupMembers = Get-ADGroupMember -Identity $EG.GUID

                    foreach ($GMember in $GroupMembers) {

                        $Hash = [ordered]@{
                            MailboxName         = $Mailbox.Name
                            MailboxAlias        = $Mailbox.Alias
                            PrimarySMTP         = $Mailbox.PrimarySmtpAddress
                            Mailbox_GUID        = $Mailbox.GUID
                            SecurityGroup       = $GroupName
                            User_SamaccountName = $GMember.SamaccountName
                            User_ObjectClass    = $GMember.ObjectClass
                            Permission          = "GrantSendOnBehalfTo"
                        }

                        $Hash = New-Object PSObject -Property $Hash
                        $Hash | Export-Csv $SendOnBehalfPermission -NoTypeInformation -Append

                    }

                
                }
     
     
            }

        }

    

    

    }


    ## Get Folder Permissions ##

    $MailboxFolders = Get-MailboxFolderStatistics $Mailbox.PrimarySmtpAddress | Where-Object { $_.FolderPath -in @("/Top of Information Store", "/Calendar") -or $_.FolderPath -like "/Inbox*" }# | select Name

    foreach ($folder in $MailboxFolders) {
    
        if ($folder.folderpath -eq "/Top of Information Store") {
    
            $FolderPath = '\'
    
        }
        else {

            $FolderPath = $Folder.FolderPath.Replace("/", "\")

        }

        $folderLocation = $Mailbox.PrimarySmtpAddress + ":" + $FolderPath

        $FolderPermissions = Get-MailboxFolderPermission $folderLocation -ErrorAction SilentlyContinue

        foreach ($Permission in $FolderPermissions) {
    
            $FolderDelegate = $Permission.User

            If ($FolderDelegate -ne "Default" -and $FolderDelegate -ne "Anonymous") {
         

                if ($ExchangeGroups.Name -contains $FolderDelegate) {
                   

                    $GroupMembers = Get-ADGroupMember $CheckDelegate.Guid

                    foreach ($Member in $GroupMembers) {
               
                        $Hash = [ordered]@{
                            MailboxName         = $Mailbox.Name
                            MailboxAlias        = $Mailbox.Alias
                            PrimarySMTP         = $Mailbox.PrimarySmtpAddress
                            Mailbox_GUID        = $Mailbox.GUID
                            FolderLocation      = $folderLocation
                            SecurityGroup       = $FolderDelegate
                            User_SamaccountName = $Member.SamaccountName
                            User_ObjectClass    = $Member.ObjectClass
                            Permission          = $Permission.AccessRights
                        }

                        $Hash = New-Object PSObject -Property $hash
                        $Hash | Export-Csv $FolderPermissionsCSV -NoTypeInformation -Append
               
               
                    }
               
                }
          
            }
    
    
        }
    
    }

    $Start++

}