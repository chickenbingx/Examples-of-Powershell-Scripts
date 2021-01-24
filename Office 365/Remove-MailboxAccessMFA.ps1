<#
.Synopsis
   Short description
.DESCRIPTION
   Long descriptionremove-mail
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-MailboxAccessMFA {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $User,

        # Param2 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        $Mailbox
    )

    Begin {

        switch ([bool](Get-ADUser -Identity $User)) {
            'True' {

                $UserADInfo = Get-ADUser -Identity $User

            }
            'False' {
                                           
                Write-Host "User $User doesnt exist in AD - please check and try again" -ForegroundColor Red
                                           
                break

            }
        }

        $USerUPN = $UserADInfo.UserPrincipalName

    }
    Process {

        switch ([bool](Get-Mailbox -Identity $mailbox)) {
            'True' {
                                              
                Remove-MailboxPermission -Identity $mailbox -User $USerUPN -AccessRights FullAccess -InheritanceType All -Confirm:$false 

            }
            'False' {

                Write-Host "User $User doesnt exist in 365 - please check and try again" -ForegroundColor Red
                                              
            }
        }
    }
    End {

    }
}