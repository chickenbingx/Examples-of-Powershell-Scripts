$root = "C:\Temp\Exchange"

$Mailboxes = Import-Csv "C:\Users\n399055\OneDrive - Electricity North West Ltd\Documents\Work\Exchange\Exchange Migration\On Prem Permission Change\Group Change Log Docs - Copy\PowershellProcessSheet.csv" 

$Access = Import-Csv "$root\1 - MailboxAccess_Users.csv"
$SendAs = Import-Csv "$root\2 - SendAs_Users.csv"
$SendOnBehalf = Import-Csv "$root\3 - SendOnBehalf_Users.csv"
$folder = Import-Csv "$root\4 - FolderPermissions_Users.csv"

foreach ($Mailbox in $Mailboxes) {

    ## Access
    $AccessData = $Access | where PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Data in $AccessData) {

        Write-Verbose "Applying $($data.Permission) to $($Data.User_SamaccountName) on $($Mailbox.PrimarySMTPAddress)" -Verbose

        Add-MailboxPermission -Identity $Data.PrimarySMTP -User $Data.User_SamaccountName -AccessRights $Data.Permission -AutoMapping:$False 

    }

    ## SendAs

    $SendAsData = $SendAs | where PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Data in $SendAsData) {

        Write-Verbose "Applying $($data.Permission) to $($Data.User_SamaccountName) on $($Mailbox.PrimarySMTPAddress)" -Verbose

        Get-User $Data.PrimarySMTP | Add-ADPermission -User $Data.User_SamaccountName -AccessRights "ExtendedRight " -ExtendedRights $Data.Permission 

    }


    #Send on Behalf of 

    $SendOnBehalfData = $SendOnBehalf | where PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Data in $SendOnBehalfData) {

        Write-Verbose "Applying $($data.Permission) to $($Data.User_SamaccountName) on $($Mailbox.PrimarySMTPAddress)" -Verbose

        Set-Mailbox -Identity $Data.PrimarySMTP -GrantSendOnBehalfTo $Data.User_SamaccountName 


    }

    #Folder
    $folderData = $folder | where PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Data in $folderData) {

        Write-Verbose "Applying $($data.Permission) to $($Data.User_SamaccountName) on $($Data.FolderLocation)" -Verbose

        Set-MailboxFolderPermission -Identity $Data.FolderLocation -User $Data.User_SamaccountName -AccessRights $data.Permission 

    }

}