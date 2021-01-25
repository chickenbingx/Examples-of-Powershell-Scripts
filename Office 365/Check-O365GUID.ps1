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
function Check-O365GUID {
   [CmdletBinding()]
   [Alias()]
   [OutputType([int])]
   Param
   (
      # Param1 help description
      [Parameter(Mandatory = $true,
         ValueFromPipelineByPropertyName = $true,
         Position = 0)]
      $Identity

   )

   Begin {

      $Usercheck = [bool](Get-ADUser $Identity)
      $365Cred = Get-Credential -UserName "$env:USERNAME@mydentist.co.uk" -Message "Enter 365 Admin Credentials"
   }
   Process {

      switch ($Usercheck) {
         "True" {
                            
            $AD = Get-ADUser $Identity
            $g = new-object -TypeName System.Guid -ArgumentList $AD.objectguid
            $b64 = [System.Convert]::ToBase64String($g.ToByteArray())

            Connect-MsolService -Credential $365Cred

            $365check = [bool](Get-MsolUser -UserPrincipalName $ad.UserprincipalName)

            switch ($365check) {
               "True" {
                                                       
                  $365GUID = Get-MsolUser -UserPrincipalName $ad.UserprincipalName | select -ExpandProperty ImmutableId

                  switch ($365GUID) {
                     $B64 { Write-Host "GUIDs for $Identity match between AD and O365" -ForegroundColor Green }
                     default { Write-Warning "GUIDS for $Identity do not match between AS and O365" }
                  }


               }
               "False" {
                                                        
                  Write-Warning "Cant find a Office 365 account for $Identity"
                                                        
               }
            }

                            

         }
         "False" {
                             
            Write-Warning "$Identity is not a valid user in AD - Please try again."
                             
         }
      }

   }
   End {
   }
}