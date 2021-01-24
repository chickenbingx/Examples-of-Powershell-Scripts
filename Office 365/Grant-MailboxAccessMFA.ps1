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
function Grant-MailboxAccessMFA {
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
        [string[]]$Mailbox,

        [Parameter(Mandatory = $False,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [bool]$AutoMap = $True,

        [parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True,
            Position = 3
        )]
        [ValidateSet(
            'Access',
            'SendOnBehalfOf',
            'SendAs'
        )]
        $AccessType
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


        foreach ($M in $Mailbox) {
            switch ([bool](Get-Mailbox -Identity $M)) {
                'True' {
                                              
                                                    
                    switch ($AccessType) {
                        'Access' {
                                                                               
                            Add-MailboxPermission -Identity $M -User $USerUPN -AccessRights FullAccess -InheritanceType All -AutoMapping:$AutoMap
                                                                               
                        }
                        'SendOnBehalfOf' {
                                                                                       
                            Add-MailboxPermission -Identity $M -User $USerUPN -AccessRights FullAccess -InheritanceType All -AutoMapping:$AutoMap
                            Set-Mailbox -Identity $M -GrantSendOnBehalfTo $UserUPN
                                                                                       
                        }
                        'SendAs' {
                            Add-MailboxPermission -Identity $M -User $USerUPN -AccessRights FullAccess -InheritanceType All -AutoMapping:$AutoMap
                            Add-RecipientPermission -Identity $M -Trustee $USerUPN -AccessRights SendAs -Confirm:$False
                        }

                    }

                                                    

                }
                'False' {

                    Write-Host "User $User doesnt exist in 365 - please check and try again" -ForegroundColor Red
                                              
                }
     
     
            }                                        
        }
    }
    End {

    }
}