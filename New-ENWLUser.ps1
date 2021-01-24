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
function New-ENWLUser {
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$FirstName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]$LastName,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [string]$EmployeeNumber,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 3)]
        [string]$JobTitle,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 4)]
        [ValidateSet(
            'Barrow - Cotsworld Crescent',
            'Blackburn - Training Academy',
            'Blackburn - Whitebirk',
            'Kendal - Parkside Road',
            'Manchester - Linley House',
            'Morecambe - Southgate',
            'Oldham - Whitegate',
            'Penrith - Newtongate',
            'Preston - Hartington Road',
            'Salford - Frederick Road',
            'Stockport - Borron Street',
            'Walkden - Hilltop',
            'Warrington - Bridgewater Place',
            'Workington - Lillthall'
        )]
        [string]$Location,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 5)]
        [ValidateSet(
            'Commercial Strategy and Support',
            'Customer',
            'Energy Solutions',
            'Engineering and Technical',
            'Finance and Business Services',
            'Operations North',
            'Operations South'
        )]
        [string]$Directorate,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 6)]
        [int]$Extension,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 7)]
        [string]$DeskNumber,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 8)]
        [string]$MobEx,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 9)]
        [String]$MobileNumber

    )

    Begin {

        $DC = (Get-ADDomain | Select-Object -ExpandProperty PDCEmulator).split('.')[0]
        $OU = "OU=User Accounts,OU=_ENWL,DC=ENWL,DC=intra"
        $SamAccountName = 'N' + ($EmployeeNumber -replace "[^0-9]")
        $DisplayName = $LastName + ", " + $FirstName
        $UPN = $FirstName + "." + $LastName + "@enwl.co.uk"
        $Country = 'GB'
        $groups = @("GS-Swivel-SMS", "GS-Swivel-SMTP", "GS-Swivel-Mobile", "GS-Citrix-User", "GS-MSOL-Office365-E3", "GS-App-IvantiUsers")

        switch ($Location) {
            'Barrow - Cotsworld Crescent' {

                $Postalcode = "LA14 5BL"
                $StreetAddress = 'Cotsworld Crescent'

            }
            'Blackburn - Training Academy' {

                $Postalcode = 'BB1 3AB'
                $StreetAddress = '6 Dyneley Road'

            }
            'Blackburn - Whitebirk' {

                $Postalcode = 'BB1 3HT'
                $StreetAddress = 'Whitebirk Drive'

            }
            'Kendal - Parkside Road' {

                $Postalcode = 'LA9 7DU'
                $StreetAddress = 'Parkside Road'

            }
            'Manchester - Linley House' {

                $Postalcode = 'M1 4LF'
                $StreetAddress = 'Linley House'
            }
            'Morecambe - Southgate' {

                $Postalcode = 'LA3 3PB'
                $StreetAddress = 'Southgate (rear F Edmondson & Sons) - Whitelund Industrial Estate '
            }
            'Oldham - Whitegate' {

                $Postalcode = 'OL9 9XB'
                $StreetAddress = 'Whitegate depot, Oldham Broadway Business Park'
            }
            'Penrith - Newtongate' {

                $Postalcode = 'CA11 0AB'
                $StreetAddress = 'Newtongate'
            }
            'Preston - Hartington Road' {

                $Postalcode = 'PR1 8AF'
                $StreetAddress = 'Hartington Road'
            }
            'Salford - Frederick Road' {

                $Postalcode = 'M6 6QH'
                $StreetAddress = 'Frederick Road'
            }
            'Stockport - Borron Street' {

                $Postalcode = 'SK1 2JD'
                $StreetAddress = 'Borron Street'
            }
            'Walkden - Hilltop' {

                $Postalcode = 'SK1 2JD'
                $StreetAddress = 'Hilltop Depot, Brackley Street'
            }
            'Warrington - Bridgewater Place' {

                $Postalcode = 'WA3 6XG'
                $StreetAddress = '304 Bridgewater Place'
            }
            'Workington - Lillthall' {

                $Postalcode = 'CA14 4PW'
                $StreetAddress = 'Lillyhall Depot, Hallwood Road'
            }
        }

        if ($DeskNumber) {
            if ($DeskNumber -like "0*") {

                $DeskNumber = $DeskNumber -replace "^0", "+44"

            }

        }

        if ($MobileNumber) {
            if ($MobileNumber -like "0*") {

                $MobileNumber = $MobileNumber -replace "^0", "+44"

            }

        }

        ################################Password Generator###############################
        $Special = @( "!", "$", "%", "&", "*", "@", "-", "?")
        $Numbers = 10..99
        $Upper = [char[]]([char]'A'..[char]'Z')
        $Lower = [char[]]([char]'a'..[char]'z')

        $Letters = @()
        $Nums = @()
        $Spec = @()

        $Letters += Get-Random -InputObject $Upper -Count 2
        $Letters += Get-Random -InputObject $Lower -Count 2
        $Nums += Get-Random -InputObject $Numbers -Count 3
        $Spec += Get-Random -InputObject $Special -Count 1

        $LetterPass = ($Letters | Sort-Object { Get-Random }) -join ''
        $NumPass = ($Nums | Sort-Object { Get-Random }) -join ''
        $SpecPass = ($Spec | Sort-Object { Get-Random }) -join ''

        $Password = $LetterPass + $NumPass + $SpecPass
        $EncryptedPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

        ################################################################################### 

    }
    Process {
       
        $ADCheck = [bool](Get-ADUser -Filter { Name -eq $SamAccountName } -Server $DC )
        
        switch ($ADCheck) {
            $True {

                Write-Host "$Samaccountname is already present within AD. Please check the infomation provided" -ForegroundColor Red

            }
            $False { 
                
                New-ADUser `
                    -GivenName $FirstName `
                    -Surname $LastName `
                    -Name $SamAccountName `
                    -DisplayName $DisplayName `
                    -SamAccountName $SamAccountName `
                    -EmailAddress $UPN `
                    -UserPrincipalName $UPN `
                    -Department $Directorate `
                    -Division $Directorate `
                    -StreetAddress $StreetAddress `
                    -PostalCode $Postalcode `
                    -Country $Country `
                    -Title $JobTitle `
                    -Office $Location `
                    -Path $OU `
                    -Server $DC
                
                Set-ADAccountPassword -Identity $SamAccountName -NewPassword $EncryptedPassword -Server $DC 
                Set-ADUser -Identity $SamAccountName -Enabled $True -ChangePasswordAtLogon $True -PasswordNeverExpires $False -Server $DC 

                foreach ($Group in $Groups) {

                    Add-ADGroupMember -Identity $Group -Members $SamAccountName -Server $DC

                }

                Start-Sleep -Seconds 10

                $ADObject = Get-ADUser -Identity $SamAccountName -Properties CanonicalName -Server $DC
                $CN = $ADObject.CanonicalName
                $DBs = Get-MailboxDatabase -Status | Where-Object { $_.Name -like "MB01_*" -and $_.Name -notlike "*vip*" } | Select-Object name, @{Name = 'DB_Size(Gb)'; Expression = { $_.DatabaseSize } }, @{Name = 'Available New Mbx Space Gb)'; Expression = { $_.AvailableNewMailboxSpace } } | Sort-Object "DB_Size(Gb)"

                $mailboxDB = $dbs | Select-Object -First 1 | Select-Object -ExpandProperty Name

                Enable-Mailbox -Identity "$CN" -Database $mailboxDB -DomainController $DC | Out-Null

            }
        }

    }
    End {

        if ($ADCheck -eq $false) {

            "Username - $SamAccountName"
            "Email - $UPN"
            "Password - $Password"
        }
    }
}