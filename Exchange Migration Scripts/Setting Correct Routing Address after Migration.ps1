$RemoteMailboxes = Get-RemoteMailbox -ResultSize Unlimited | Where-Object RemoteRoutingAddress -notlike "*@enw365.mail.onmicrosoft.com"

foreach ($Mailbox in $RemoteMailboxes) {
    
    $Mailbox.PrimarySmtpAddress
    $NewRouting = "SMTP:" + $Mailbox.Name + "@enw365.mail.onmicrosoft.com"
    Set-RemoteMailbox -Identity $Mailbox.Name -RemoteRoutingAddress "$NewRouting"

}

