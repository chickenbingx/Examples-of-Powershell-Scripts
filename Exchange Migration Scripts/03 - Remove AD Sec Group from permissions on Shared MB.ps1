$root = "C:\Temp\Exchange"

$Mailboxes = Import-Csv "C:\Users\n399055\OneDrive - Electricity North West Ltd\Documents\Work\Exchange\Exchange Migration\On Prem Permission Change\Group Change Log Docs - Copy\PowershellProcessSheet.csv" | Where-Object SamaccountName -like "connectionsch*"

$Access = Import-Csv "$root\1 - MailboxAccess_Users.csv"
$SendAs = Import-Csv "$root\2 - SendAs_Users.csv"
$SendOnBehalf = Import-Csv "$root\3 - SendOnBehalf_Users.csv"
$folder = Import-Csv "$root\4 - FolderPermissions_Users.csv"

foreach ($Mailbox in $Mailboxes) {

    ##Access

    $AccessRemove = $Access | Where-Object PrimarySMTP -eq $Mailbox.PrimarySMTPAddress 

    foreach ($Remove in $AccessRemove) {

        Write-Verbose "Removing $($data.Permission) to $($Data.SecurityGroup) on $($Mailbox.PrimarySMTPAddress)" -Verbose

        Remove-MailboxPermission -Identity $Remove.PrimarySMTP -User $Remove.SecurityGroup -AccessRights $Remove.Permission -Confirm:$False

    }

    ## Send As

    $SendAsRemove = $SendAs | Where-Object PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Remove in $SendAsRemove) {

        Write-Verbose "Removing $($Remove.Permission) to $($Remove.SecurityGroup) on $($Mailbox.PrimarySMTPAddress)"

        Get-User $Remove.PrimarySMTP | Remove-ADPermission -User $Remove.SecurityGroup -AccessRights "ExtendedRight " -ExtendedRights $Remove.Permission -Confirm:$False

    }


    #Send on Behalf of 

    $SendOnBehalfRemove = $SendOnBehalf | Where-Object PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Remove in $SendOnBehalfRemove) {

        Write-Verbose "Removing $($data.Permission) to $($Data.SecurityGroup) on $($Mailbox.PrimarySMTPAddress)" -Verbose

        Remove-Mailbox -Identity $Remove.PrimarySMTP -GrantSendOnBehalfTo $Remove.SecurityGroup -Confirm:$False


    }

    #Folder
    $folderRemove = $folder | Where-Object PrimarySMTP -eq $Mailbox.PrimarySMTPAddress

    foreach ($Remove in $folderRemove) {

        Write-Verbose "Removing $($data.Permission) to $($Data.SecurityGroup) on $($Data.FolderLocation)" -Verbose

        Remove-MailboxFolderPermission -Identity $Remove.FolderLocation -User $Remove.SecurityGroup -AccessRights $Remove.Permission -Confirm:$False

    }


}