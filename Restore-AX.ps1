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
function Restore-AX {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateSet(
            'UAT',
            'UAT2',
            'TEST',
            'DEV'
        )]
        $Environment,

        [parameter(Mandatory = $True,
            Position = 1                  
        )]
        [ValidateSet(
            'PROD',
            'UAT',
            'UAT2',
            'TEST'
        )]
        $RestoreFrom,

        [Parameter(Mandatory = $True,
            Position = 2
        )]
        [ValidateSet(
            'Data',
            'Model',
            'Data&Model'
        )]
        $RestoreType
    )

    Begin {

        Set-Location c:\

        $Start = Get-Date -Format "HH:mm:ss"

        if ($env:USERNAME -notlike "*1") {
                                   
            Write-Error "Log in with your 1 account"
                                   
            Break

        }

        if ($Environment -match $RestoreFrom) {
                                        
            Write-Warning "You have select the same environment as your restore source and destination. Please reselect the parameters"

            break
                                        
        }
        $Gee = Get-Date
        $Date = Get-Date $gee -Format "dd_MM_yy"
        $DayMonth = Get-Date $gee -Format "dd_MM"
        $EnvServer = "IDH-$Environment-SQL-01.IDHDYN.COM"
        $ResServer = "IDH-$RestoreFrom-SQL-01.IDHDYN.COM"

        $EnvDBs = @()
        $ResDBs = @()

    

        switch ($RestoreType) {
            'Data' {
                $EnvDBs += "AX2012_$Environment"
                $ResDBs += "AX2012_$RestoreFrom"
            }
            'Model' {
                $EnvDBs += "AX2012_$Environment" + "_Model"
                $ResDBs += "AX2012_$RestoreFrom" + "_Model"
            }
            'Data&Model' {
                $EnvDBs += "AX2012_$Environment"
                $EnvDBs += "AX2012_$Environment" + "_Model"
                $ResDBs += "AX2012_$RestoreFrom"
                $ResDBs += "AX2012_$RestoreFrom" + "_Model"
            }
        }

        $envDBOrig = "AX2012_$Environment" + "_Orig" 

        $EnvDrive = "\\$EnvServer\t$"
        $ResDrive = "\\$ResServer\t$" 

        if (Test-Path "$ResDrive\Toby") {
                                  
            $ResDrive = "$ResDrive\Toby"
            $ResfolderName = "Restore $DayMonth"

            if (!(Test-Path "$ResDrive\$ResfolderName")) {

                New-Item "$ResDrive\$ResfolderName" -ItemType Directory

            }

                                  
        }
        ELSE {

            $ResDrive = "$ResDrive\Toby"

            New-Item $ResDrive -ItemType Directory

            $ResfolderName = "Restore $DayMonth"

            if (!(Test-Path "$ResDrive\$ResfolderName")) {

                New-Item "$ResDrive\$folderName" -ItemType Directory

            }


        }
        if (Test-Path "$EnvDrive\Toby") {
                                  
            $EnvDrive = "$EnvDrive\Toby"
            $EnvfolderName = "$Environment Restore From $RestoreFrom $DayMonth"

            if (!(Test-Path "$EnvDrive\$EnvFoldername")) {

                New-Item "$EnvDrive\$EnvFoldername" -ItemType Directory

            }

                                  
        }
        ELSE {

            New-Item $EnvDrive -ItemType Directory

            $EnvFoldername = "$Environment Restore From $RestoreFrom $DayMonth"

            if (!(Test-Path "$EnvDrive\$EnvFoldername")) {

                New-Item "$EnvDrive\$EnvFoldername" -ItemType Directory

            }
                                  
        }

        $ResBKUPFolder = "$ResDrive\$ResfolderName"

        $ResDBHash = @{}

    }
    Process {

        foreach ($DB in $ResDBs) {

            $ResBKUPFile = "$DB $Date.bak"
            $ResBKUPLocal = "$ResBKUPFolder\$ResBKUPFile"

            if (Test-Path $ResBKUPLocal) {

                Write-Verbose "$ResBKUPFile already exists on $ResServer" -Verbose
                           
                switch -Wildcard ($DB) {
                    '*_Model*' { $ResDBHash.Add('Model', "$ResBKUPFile") }
                    Default { $ResDBHash.Add('Data', "$ResBKUPFile") }     
                }

            }
            ELSE {

                switch -Wildcard ($DB) {
                    '*_Model*' { $ResDBHash.Add('Model', "$ResBKUPFile") }
                    Default { $ResDBHash.Add('Data', "$ResBKUPFile") }     
                }

                Write-Verbose "Running Back up on $ResServer - $DB" -Verbose

                Backup-SqlDatabase -ServerInstance $ResServer -Database $DB -BackupFile $ResBKUPLocal -ConnectionTimeout 600 

            }
                           
        }


        foreach ($DB in $ResDBHash.Values) {

            if (!(Test-Path "$EnvDrive\$EnvfolderName\$DB")) {

                write-verbose "Copying $DB to $Envserver" -verbose
                                                    
                Start-BitsTransfer -Source "$ResBKUPFolder\$db" -Destination "$EnvDrive\$EnvfolderName" -DisplayName $DB -Asynchronous 
                                                     
            }
            ELSE {

                $EnvFile = Get-ChildItem "$EnvDrive\$EnvfolderName\$DB"
                $ResFile = Get-ChildItem "$ResDrive\$ResfolderName\$DB"

                if ($EnvFile.LastWriteTime -eq $ResFile.LastWriteTime) {
                                                                              
                    Write-Verbose "$DB is already present on $EnvServer" -Verbose
                                                                              
                }
                ELSE {

                    Remove-item $EnvFile -for

                    Write-Verbose "Transfering $DB" -Verbose

                    Start-BitsTransfer -Source "$ResBKUPFolder\$db" -Destination "$EnvDrive\$EnvfolderName" -DisplayName $DB -Asynchronous

                }

            }
        }


        $Jobs = Get-BitsTransfer 

        while ($Jobs.Count -ge '1') {
                           
            $Transfer = Get-BitsTransfer | Select-Object DisplayName, @{n = 'Completed'; e = { "$([math]::Round($_.BytesTransferred/$_.BytesTotal,2)*100)%" } }


            $Transfer | Format-Table -AutoSize

            Start-Sleep 2

            Get-BitsTransfer | Where-Object { $_.JobState -eq "Transferred" } | Complete-BitsTransfer -ea SilentlyContinue

            Clear-Host

            if ((Get-BitsTransfer).Count -eq '0') {
                                                              
                Break

            }
`
                          
        }

                          



        $EnvAOS = "IDH-$Environment-AOS-01"

        Write-Verbose "Stopping AX Service on $EnvAOS" -Verbose

        Get-Service -ComputerName $EnvAOS -DisplayName "*AX Object Server*" | Stop-Service -Force

        $EnvDB = "AX2012_$Environment"
        $EnvDBOrig = "AX2012_$Environment" + "_Orig"

        $OrigCheck = "
IF (SELECT NAME FROM sys.databases WHERE name = '$envDBOrig`') IS NULL
BEGIN 
CREATE DATABASE $envDBOrig
END
             
             "


        Invoke-Sqlcmd -ServerInstance $EnvServer -Database Master -Query $OrigCheck

        $SQL1 = "
print ' '
print '------- PROCESS START  ------------'

IF OBJECT_ID ( '$EnvDBOrig.dbo.AifWebsites' )                                  IS NOT NULL    drop table $EnvDBOrig.dbo.AifWebsites
IF OBJECT_ID ( '$EnvDBOrig.dbo.batch' )                                        IS NOT NULL    drop table $EnvDBOrig.dbo.batch
IF OBJECT_ID ( '$EnvDBOrig.dbo.BatchGroup' )                                   IS NOT NULL    drop table $EnvDBOrig.dbo.BatchGroup
IF OBJECT_ID ( '$EnvDBOrig.dbo.BatchJob' )                                     IS NOT NULL    drop table $EnvDBOrig.dbo.BatchJob
IF OBJECT_ID ( '$EnvDBOrig.dbo.BatchServerConfig' )                            IS NOT NULL    drop table $EnvDBOrig.dbo.BatchServerConfig
IF OBJECT_ID ( '$EnvDBOrig.dbo.BatchServerGroup' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.BatchServerGroup
IF OBJECT_ID ( '$EnvDBOrig.dbo.bianalysisserver' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.bianalysisserver
IF OBJECT_ID ( '$EnvDBOrig.dbo.biconfiguration' )                              IS NOT NULL    drop table $EnvDBOrig.dbo.biconfiguration

IF OBJECT_ID ( '$EnvDBOrig.dbo.DocuParameters' )                               IS NOT NULL    drop table $EnvDBOrig.dbo.DocuParameters
IF OBJECT_ID ( '$EnvDBOrig.dbo.docutype' )                                     IS NOT NULL    drop table $EnvDBOrig.dbo.docutype
IF OBJECT_ID ( '$EnvDBOrig.dbo.epglobalparameters' )                           IS NOT NULL    drop table $EnvDBOrig.dbo.epglobalparameters
IF OBJECT_ID ( '$EnvDBOrig.dbo.epwebsiteparameters' )                          IS NOT NULL    drop table $EnvDBOrig.dbo.epwebsiteparameters
IF OBJECT_ID ( '$EnvDBOrig.dbo.srsservers' )                                   IS NOT NULL    drop table $EnvDBOrig.dbo.srsservers
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysbcproxyuseraccount' )                        IS NOT NULL    drop table $EnvDBOrig.dbo.sysbcproxyuseraccount
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysclusterconfig' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.sysclusterconfig
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysemailsmtppassword' )                         IS NOT NULL    drop table $EnvDBOrig.dbo.sysemailsmtppassword
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysserverconfig' )                              IS NOT NULL    drop table $EnvDBOrig.dbo.sysserverconfig
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysserversessions' )                            IS NOT NULL    drop table $EnvDBOrig.dbo.sysserversessions
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysworkflowparameters' )                        IS NOT NULL    drop table $EnvDBOrig.dbo.sysworkflowparameters
IF OBJECT_ID ( '$EnvDBOrig.dbo.userinfo' )                                     IS NOT NULL    drop table $EnvDBOrig.dbo.userinfo
IF OBJECT_ID ( '$EnvDBOrig.dbo.dirpersonuser' )                                IS NOT NULL    drop table $EnvDBOrig.dbo.dirpersonuser
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysUserInfo' )                                  IS NOT NULL    drop table $EnvDBOrig.dbo.SysUserInfo
IF OBJECT_ID ( '$EnvDBOrig.dbo.SecurityUserRole' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.SecurityUserRole
IF OBJECT_ID ( '$EnvDBOrig.dbo.userexternalparty' )                            IS NOT NULL    drop table $EnvDBOrig.dbo.userexternalparty
IF OBJECT_ID ( '$EnvDBOrig.dbo.sysuserprofiles' )                              IS NOT NULL    drop table $EnvDBOrig.dbo.sysuserprofiles
IF OBJECT_ID ( '$EnvDBOrig.dbo.usergroupinfo' )                                IS NOT NULL    drop table $EnvDBOrig.dbo.usergroupinfo
IF OBJECT_ID ( '$EnvDBOrig.dbo.UserGroupList' )                                IS NOT NULL    drop table $EnvDBOrig.dbo.UserGroupList
IF OBJECT_ID ( '$EnvDBOrig.dbo.vendpaymmodetable' )                            IS NOT NULL    drop table $EnvDBOrig.dbo.vendpaymmodetable
IF OBJECT_ID ( '$EnvDBOrig.dbo.OMUserRoleOrganization' )                       IS NOT NULL    drop table $EnvDBOrig.dbo.OMUserRoleOrganization
IF OBJECT_ID ( '$EnvDBOrig.dbo.OMUserRoleOUs' )                                IS NOT NULL    drop table $EnvDBOrig.dbo.OMUserRoleOUs

IF OBJECT_ID ( '$EnvDBOrig.dbo.aifAction' )                                    IS NOT NULL    drop table $EnvDBOrig.dbo.aifAction
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifAdapter' )                                   IS NOT NULL    drop table $EnvDBOrig.dbo.aifAdapter
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifAppsharefile' )                              IS NOT NULL    drop table $EnvDBOrig.dbo.aifAppsharefile
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifChannel' )                                   IS NOT NULL    drop table $EnvDBOrig.dbo.aifChannel
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifDatapolicy' )                                IS NOT NULL    drop table $EnvDBOrig.dbo.aifDatapolicy
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifDocumentfield' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.aifDocumentfield
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifDocumentschematable' )                       IS NOT NULL    drop table $EnvDBOrig.dbo.aifDocumentschematable
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifEndpointactionvaluemap' )                    IS NOT NULL    drop table $EnvDBOrig.dbo.aifEndpointactionvaluemap
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifGlobalsettings' )                            IS NOT NULL    drop table $EnvDBOrig.dbo.aifGlobalsettings
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifPort' )                                      IS NOT NULL    drop table $EnvDBOrig.dbo.aifPort
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifPortactionpolicy' )                          IS NOT NULL    drop table $EnvDBOrig.dbo.aifPortactionpolicy
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifPortdocument' )                              IS NOT NULL    drop table $EnvDBOrig.dbo.aifPortdocument
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifRuntimecache' )                              IS NOT NULL    drop table $EnvDBOrig.dbo.aifRuntimecache
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifSchemastore' )                               IS NOT NULL    drop table $EnvDBOrig.dbo.aifSchemastore
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifService' )                                   IS NOT NULL    drop table $EnvDBOrig.dbo.aifService
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifSqlcdcenabledtables' )                       IS NOT NULL    drop table $EnvDBOrig.dbo.aifSqlcdcenabledtables
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifSqlcttriggers' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.aifSqlcttriggers
IF OBJECT_ID ( '$EnvDBOrig.dbo.aifWcfconfiguration' )                          IS NOT NULL    drop table $EnvDBOrig.dbo.aifWcfconfiguration

IF OBJECT_ID ( '$EnvDBOrig.dbo.AifPipeline' )                                  IS NOT NULL    drop table $EnvDBOrig.dbo.AifPipeline
IF OBJECT_ID ( '$EnvDBOrig.dbo.AifPipelineComponent' )                         IS NOT NULL    drop table $EnvDBOrig.dbo.AifPipelineComponent
IF OBJECT_ID ( '$EnvDBOrig.dbo.AifXmlTransformConfig' )                        IS NOT NULL    drop table $EnvDBOrig.dbo.AifXmlTransformConfig
IF OBJECT_ID ( '$EnvDBOrig.dbo.AifTransformElement' )                          IS NOT NULL    drop table $EnvDBOrig.dbo.AifTransformElement
IF OBJECT_ID ( '$EnvDBOrig.dbo.AifTransform' )                                 IS NOT NULL    drop table $EnvDBOrig.dbo.AifTransform
IF OBJECT_ID ( '$EnvDBOrig.dbo.AifXsltRepository' )                            IS NOT NULL    drop table $EnvDBOrig.dbo.AifXsltRepository

IF OBJECT_ID ( '$EnvDBOrig.dbo.SysVersionControlMorphXItemTable' )             IS NOT NULL    drop table $EnvDBOrig.dbo.SysVersionControlMorphXItemTable
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysVersionControlMorphXLockTable' )             IS NOT NULL    drop table $EnvDBOrig.dbo.SysVersionControlMorphXLockTable
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysVersionControlMorphXRevisionTable' )         IS NOT NULL    drop table $EnvDBOrig.dbo.SysVersionControlMorphXRevisionTable
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysVersionControlParameters' )                  IS NOT NULL    drop table $EnvDBOrig.dbo.SysVersionControlParameters
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysVersionControlPendingChangeList' )           IS NOT NULL    drop table $EnvDBOrig.dbo.SysVersionControlPendingChangeList
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysVersionControlSynchronizeLog')               IS NOT NULL    drop table $EnvDBOrig.dbo.SysVersionControlSynchronizeLog

IF OBJECT_ID ( '$EnvDBOrig.dbo.SYSGLOBALCONFIGURATION')                        IS NOT NULL    drop table $EnvDBOrig.dbo.SYSGLOBALCONFIGURATION
IF OBJECT_ID ( '$EnvDBOrig.dbo.SYSFILESTOREPARAMETERS')                        IS NOT NULL    drop table $EnvDBOrig.dbo.SYSFILESTOREPARAMETERS
IF OBJECT_ID ( '$EnvDBOrig.dbo.COLLABSITEPARAMETERS')                          IS NOT NULL    drop table $EnvDBOrig.dbo.COLLABSITEPARAMETERS

IF OBJECT_ID ( '$EnvDBOrig.dbo.ledgerparameters')                              IS NOT NULL    drop table $EnvDBOrig.dbo.ledgerparameters

IF OBJECT_ID ( '$EnvDBOrig.dbo.xRefDialogUpdate')                              IS NOT NULL    drop table $EnvDBOrig.dbo.xRefDialogUpdate
IF OBJECT_ID ( '$EnvDBOrig.dbo.xRefNames')                                     IS NOT NULL    drop table $EnvDBOrig.dbo.xRefNames
IF OBJECT_ID ( '$EnvDBOrig.dbo.xRefPaths')                                     IS NOT NULL    drop table $EnvDBOrig.dbo.xRefPaths
IF OBJECT_ID ( '$EnvDBOrig.dbo.xRefReferences')                                IS NOT NULL    drop table $EnvDBOrig.dbo.xRefReferences
IF OBJECT_ID ( '$EnvDBOrig.dbo.xRefTableRelation')                             IS NOT NULL    drop table $EnvDBOrig.dbo.xRefTableRelation
IF OBJECT_ID ( '$EnvDBOrig.dbo.xRefTmpReferences')                             IS NOT NULL    drop table $EnvDBOrig.dbo.xRefTmpReferences

IF OBJECT_ID ( '$EnvDBOrig.dbo.SYSConfig')                                     IS NOT NULL    drop table $EnvDBOrig.dbo.SYSConfig
IF OBJECT_ID ( '$EnvDBOrig.dbo.SYSLICENSECODESORT')                            IS NOT NULL    drop table $EnvDBOrig.dbo.SYSLICENSECODESORT

IF OBJECT_ID ( '$EnvDBOrig.dbo.SysAdmin_DBUsers' )                             IS NOT NULL    drop table $EnvDBOrig.dbo.SysAdmin_DBUsers
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysAdmin_DBSchemas' )                           IS NOT NULL    drop table $EnvDBOrig.dbo.SysAdmin_DBSchemas
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysAdmin_DBUserRoles' )                         IS NOT NULL    drop table $EnvDBOrig.dbo.SysAdmin_DBUserRoles

IF OBJECT_ID ( '$EnvDBOrig.dbo.CUSTVENDAIFPAYMTABLE')                          IS NOT NULL    drop table $EnvDBOrig.dbo.CUSTVENDAIFPAYMTABLE

-- Following two tables are populated only by AX_Orig-AX.sql script
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysAdmin_DBSchemasToDelete')                    IS NOT NULL    drop table $EnvDBOrig.dbo.SysAdmin_DBSchemasToDelete
IF OBJECT_ID ( '$EnvDBOrig.dbo.SysAdmin_DBUsersToDelete')                      IS NOT NULL    drop table $EnvDBOrig.dbo.SysAdmin_DBUsersToDelete

IF OBJECT_ID ( '$EnvDBOrig.dbo.SQLDictionary')                                 IS NOT NULL    drop table $EnvDBOrig.dbo.SQLDictionary


IF OBJECT_ID ( '$EnvDB.dbo.AifWebsites' )                                 IS NOT NULL    select * into $EnvDBOrig.dbo.AifWebsites                                  from $EnvDB.dbo.AifWebsites
IF OBJECT_ID ( '$EnvDB.dbo.batch' )                                       IS NOT NULL    select * into $EnvDBOrig.dbo.batch                                        from $EnvDB.dbo.batch
IF OBJECT_ID ( '$EnvDB.dbo.BatchGroup' )                                  IS NOT NULL    select * into $EnvDBOrig.dbo.BatchGroup                                   from $EnvDB.dbo.BatchGroup
IF OBJECT_ID ( '$EnvDB.dbo.BatchJob' )                                    IS NOT NULL    select * into $EnvDBOrig.dbo.BatchJob                                     from $EnvDB.dbo.BatchJob
IF OBJECT_ID ( '$EnvDB.dbo.BatchServerConfig' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.BatchServerConfig                            from $EnvDB.dbo.BatchServerConfig
IF OBJECT_ID ( '$EnvDB.dbo.BatchServerGroup' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.BatchServerGroup                             from $EnvDB.dbo.BatchServerGroup
IF OBJECT_ID ( '$EnvDB.dbo.bianalysisserver' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.bianalysisserver                             from $EnvDB.dbo.bianalysisserver
IF OBJECT_ID ( '$EnvDB.dbo.biconfiguration' )                             IS NOT NULL    select * into $EnvDBOrig.dbo.biconfiguration                              from $EnvDB.dbo.biconfiguration
IF OBJECT_ID ( '$EnvDB.dbo.DocuParameters' )                              IS NOT NULL    select * into $EnvDBOrig.dbo.DocuParameters                               from $EnvDB.dbo.DocuParameters
IF OBJECT_ID ( '$EnvDB.dbo.docutype' )                                    IS NOT NULL    select * into $EnvDBOrig.dbo.docutype                                     from $EnvDB.dbo.docutype
IF OBJECT_ID ( '$EnvDB.dbo.epglobalparameters' )                          IS NOT NULL    select * into $EnvDBOrig.dbo.epglobalparameters                           from $EnvDB.dbo.epglobalparameters
IF OBJECT_ID ( '$EnvDB.dbo.epwebsiteparameters' )                         IS NOT NULL    select * into $EnvDBOrig.dbo.epwebsiteparameters                          from $EnvDB.dbo.epwebsiteparameters
IF OBJECT_ID ( '$EnvDB.dbo.srsservers' )                                  IS NOT NULL    select * into $EnvDBOrig.dbo.srsservers                                   from $EnvDB.dbo.srsservers
IF OBJECT_ID ( '$EnvDB.dbo.sysbcproxyuseraccount' )                       IS NOT NULL    select * into $EnvDBOrig.dbo.sysbcproxyuseraccount                        from $EnvDB.dbo.sysbcproxyuseraccount
IF OBJECT_ID ( '$EnvDB.dbo.sysclusterconfig' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.sysclusterconfig                             from $EnvDB.dbo.sysclusterconfig
IF OBJECT_ID ( '$EnvDB.dbo.sysemailsmtppassword' )                        IS NOT NULL    select * into $EnvDBOrig.dbo.sysemailsmtppassword                         from $EnvDB.dbo.sysemailsmtppassword
IF OBJECT_ID ( '$EnvDB.dbo.sysserverconfig' )                             IS NOT NULL    select * into $EnvDBOrig.dbo.sysserverconfig                              from $EnvDB.dbo.sysserverconfig
IF OBJECT_ID ( '$EnvDB.dbo.sysserversessions' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.sysserversessions                            from $EnvDB.dbo.sysserversessions
IF OBJECT_ID ( '$EnvDB.dbo.sysworkflowparameters' )                       IS NOT NULL    select * into $EnvDBOrig.dbo.sysworkflowparameters                        from $EnvDB.dbo.sysworkflowparameters
IF OBJECT_ID ( '$EnvDB.dbo.userinfo' )                                    IS NOT NULL    select * into $EnvDBOrig.dbo.userinfo                                     from $EnvDB.dbo.userinfo
IF OBJECT_ID ( '$EnvDB.dbo.dirpersonuser' )                               IS NOT NULL    select * into $EnvDBOrig.dbo.dirpersonuser                                from $EnvDB.dbo.dirpersonuser
IF OBJECT_ID ( '$EnvDB.dbo.SysUserInfo' )                                 IS NOT NULL    select * into $EnvDBOrig.dbo.SysUserInfo                                  from $EnvDB.dbo.SysUserInfo
IF OBJECT_ID ( '$EnvDB.dbo.SecurityUserRole' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.SecurityUserRole                             from $EnvDB.dbo.SecurityUserRole
IF OBJECT_ID ( '$EnvDB.dbo.userexternalparty' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.userexternalparty                            from $EnvDB.dbo.userexternalparty
IF OBJECT_ID ( '$EnvDB.dbo.sysuserprofiles' )                             IS NOT NULL    select * into $EnvDBOrig.dbo.sysuserprofiles                              from $EnvDB.dbo.sysuserprofiles

IF OBJECT_ID ( '$EnvDB.dbo.usergroupinfo' )                               IS NOT NULL    select * into $EnvDBOrig.dbo.usergroupinfo                                from $EnvDB.dbo.usergroupinfo
IF OBJECT_ID ( '$EnvDB.dbo.usergrouplist' )                               IS NOT NULL    select * into $EnvDBOrig.dbo.usergrouplist                                from $EnvDB.dbo.usergrouplist
IF OBJECT_ID ( '$EnvDB.dbo.vendpaymmodetable' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.vendpaymmodetable                            from $EnvDB.dbo.vendpaymmodetable
IF OBJECT_ID ( '$EnvDB.dbo.OMUserRoleOrganization' )                      IS NOT NULL    select * into $EnvDBOrig.dbo.OMUserRoleOrganization                       from $EnvDB.dbo.OMUserRoleOrganization
IF OBJECT_ID ( '$EnvDB.dbo.OMUserRoleOUs' )                               IS NOT NULL    select * into $EnvDBOrig.dbo.OMUserRoleOUs                                from $EnvDB.dbo.OMUserRoleOUs

IF OBJECT_ID ( '$EnvDB.dbo.aifAction' )                                   IS NOT NULL    select * into $EnvDBOrig.dbo.aifAction                                    from $EnvDB.dbo.aifAction
IF OBJECT_ID ( '$EnvDB.dbo.aifAdapter' )                                  IS NOT NULL    select * into $EnvDBOrig.dbo.aifAdapter                                   from $EnvDB.dbo.aifAdapter
IF OBJECT_ID ( '$EnvDB.dbo.aifAppsharefile' )                             IS NOT NULL    select * into $EnvDBOrig.dbo.aifAppsharefile                              from $EnvDB.dbo.aifAppsharefile
IF OBJECT_ID ( '$EnvDB.dbo.aifChannel' )                                  IS NOT NULL    select * into $EnvDBOrig.dbo.aifChannel                                   from $EnvDB.dbo.aifChannel
IF OBJECT_ID ( '$EnvDB.dbo.aifDatapolicy' )                               IS NOT NULL    select * into $EnvDBOrig.dbo.aifDatapolicy                                from $EnvDB.dbo.aifDatapolicy
IF OBJECT_ID ( '$EnvDB.dbo.aifDocumentfield' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.aifDocumentfield                             from $EnvDB.dbo.aifDocumentfield
IF OBJECT_ID ( '$EnvDB.dbo.aifDocumentschematable' )                      IS NOT NULL    select * into $EnvDBOrig.dbo.aifDocumentschematable                       from $EnvDB.dbo.aifDocumentschematable
IF OBJECT_ID ( '$EnvDB.dbo.aifEndpointactionvaluemap' )                   IS NOT NULL    select * into $EnvDBOrig.dbo.aifEndpointactionvaluemap                    from $EnvDB.dbo.aifEndpointactionvaluemap
IF OBJECT_ID ( '$EnvDB.dbo.aifGlobalsettings' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.aifGlobalsettings                            from $EnvDB.dbo.aifGlobalsettings
IF OBJECT_ID ( '$EnvDB.dbo.aifPort' )                                     IS NOT NULL    select * into $EnvDBOrig.dbo.aifPort                                      from $EnvDB.dbo.aifPort
IF OBJECT_ID ( '$EnvDB.dbo.aifPortactionpolicy' )                         IS NOT NULL    select * into $EnvDBOrig.dbo.aifPortactionpolicy                          from $EnvDB.dbo.aifPortactionpolicy
IF OBJECT_ID ( '$EnvDB.dbo.aifPortdocument' )                             IS NOT NULL    select * into $EnvDBOrig.dbo.aifPortdocument                              from $EnvDB.dbo.aifPortdocument
IF OBJECT_ID ( '$EnvDB.dbo.aifRuntimecache' )                             IS NOT NULL    select * into $EnvDBOrig.dbo.aifRuntimecache                              from $EnvDB.dbo.aifRuntimecache
IF OBJECT_ID ( '$EnvDB.dbo.aifSchemastore' )                              IS NOT NULL    select * into $EnvDBOrig.dbo.aifSchemastore                               from $EnvDB.dbo.aifSchemastore
IF OBJECT_ID ( '$EnvDB.dbo.aifService' )                                  IS NOT NULL    select * into $EnvDBOrig.dbo.aifService                                   from $EnvDB.dbo.aifService
IF OBJECT_ID ( '$EnvDB.dbo.aifSqlcdcenabledtables' )                      IS NOT NULL    select * into $EnvDBOrig.dbo.aifSqlcdcenabledtables                       from $EnvDB.dbo.aifSqlcdcenabledtables
IF OBJECT_ID ( '$EnvDB.dbo.aifSqlcttriggers' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.aifSqlcttriggers                             from $EnvDB.dbo.aifSqlcttriggers
IF OBJECT_ID ( '$EnvDB.dbo.aifWcfconfiguration' )                         IS NOT NULL    select * into $EnvDBOrig.dbo.aifWcfconfiguration                          from $EnvDB.dbo.aifWcfconfiguration

IF OBJECT_ID ( '$EnvDB.dbo.AifPipeline' )                                 IS NOT NULL    select * into $EnvDBOrig.dbo.AifPipeline                                  from $EnvDB.dbo.AifPipeline
IF OBJECT_ID ( '$EnvDB.dbo.AifPipelineComponent' )                        IS NOT NULL    select * into $EnvDBOrig.dbo.AifPipelineComponent                         from $EnvDB.dbo.AifPipelineComponent
IF OBJECT_ID ( '$EnvDB.dbo.AifXmlTransformConfig' )                       IS NOT NULL    select * into $EnvDBOrig.dbo.AifXmlTransformConfig                        from $EnvDB.dbo.AifXmlTransformConfig
IF OBJECT_ID ( '$EnvDB.dbo.AifTransformElement' )                         IS NOT NULL    select * into $EnvDBOrig.dbo.AifTransformElement                          from $EnvDB.dbo.AifTransformElement
IF OBJECT_ID ( '$EnvDB.dbo.AifTransform' )                                IS NOT NULL    select * into $EnvDBOrig.dbo.AifTransform                                 from $EnvDB.dbo.AifTransform
IF OBJECT_ID ( '$EnvDB.dbo.AifXsltRepository' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.AifXsltRepository                            from $EnvDB.dbo.AifXsltRepository

IF OBJECT_ID ( '$EnvDB.dbo.SysVersionControlMorphXItemTable' )            IS NOT NULL    select * into $EnvDBOrig.dbo.SysVersionControlMorphXItemTable             from $EnvDB.dbo.SysVersionControlMorphXItemTable
IF OBJECT_ID ( '$EnvDB.dbo.SysVersionControlMorphXLockTable' )            IS NOT NULL    select * into $EnvDBOrig.dbo.SysVersionControlMorphXLockTable             from $EnvDB.dbo.SysVersionControlMorphXLockTable
IF OBJECT_ID ( '$EnvDB.dbo.SysVersionControlMorphXRevisionTable' )        IS NOT NULL    select * into $EnvDBOrig.dbo.SysVersionControlMorphXRevisionTable         from $EnvDB.dbo.SysVersionControlMorphXRevisionTable
IF OBJECT_ID ( '$EnvDB.dbo.SysVersionControlParameters' )                 IS NOT NULL    select * into $EnvDBOrig.dbo.SysVersionControlParameters                  from $EnvDB.dbo.SysVersionControlParameters
IF OBJECT_ID ( '$EnvDB.dbo.SysVersionControlPendingChangeList' )          IS NOT NULL    select * into $EnvDBOrig.dbo.SysVersionControlPendingChangeList           from $EnvDB.dbo.SysVersionControlPendingChangeList
IF OBJECT_ID ( '$EnvDB.dbo.SysVersionControlSynchronizeLog' )             IS NOT NULL    select * into $EnvDBOrig.dbo.SysVersionControlSynchronizeLog              from $EnvDB.dbo.SysVersionControlSynchronizeLog

IF OBJECT_ID ( '$EnvDB.dbo.CUSTVENDAIFPAYMTABLE' )                        IS NOT NULL    select * into $EnvDBOrig.dbo.CUSTVENDAIFPAYMTABLE                         from $EnvDB.dbo.CUSTVENDAIFPAYMTABLE

IF OBJECT_ID ( '$EnvDB.dbo.SYSGLOBALCONFIGURATION' )                      IS NOT NULL    select * into $EnvDBOrig.dbo.SYSGLOBALCONFIGURATION                       from $EnvDB.dbo.SYSGLOBALCONFIGURATION
IF OBJECT_ID ( '$EnvDB.dbo.SYSFILESTOREPARAMETERS' )                      IS NOT NULL    select * into $EnvDBOrig.dbo.SYSFILESTOREPARAMETERS                       from $EnvDB.dbo.SYSFILESTOREPARAMETERS
IF OBJECT_ID ( '$EnvDB.dbo.COLLABSITEPARAMETERS' )                        IS NOT NULL    select * into $EnvDBOrig.dbo.COLLABSITEPARAMETERS                         from $EnvDB.dbo.COLLABSITEPARAMETERS

IF OBJECT_ID ( '$EnvDB.dbo.ledgerparameters' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.ledgerparameters                             from $EnvDB.dbo.ledgerparameters

IF OBJECT_ID ( '$EnvDB.dbo.xRefDialogUpdate' )                            IS NOT NULL    select * into $EnvDBOrig.dbo.xRefDialogUpdate                             from $EnvDB.dbo.xRefDialogUpdate
IF OBJECT_ID ( '$EnvDB.dbo.xRefNames' )                                   IS NOT NULL    select * into $EnvDBOrig.dbo.xRefNames                                    from $EnvDB.dbo.xRefNames
IF OBJECT_ID ( '$EnvDB.dbo.xRefPaths' )                                   IS NOT NULL    select * into $EnvDBOrig.dbo.xRefPaths                                    from $EnvDB.dbo.xRefPaths
IF OBJECT_ID ( '$EnvDB.dbo.xRefReferences' )                              IS NOT NULL    select * into $EnvDBOrig.dbo.xRefReferences                               from $EnvDB.dbo.xRefReferences
IF OBJECT_ID ( '$EnvDB.dbo.xRefTableRelation' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.xRefTableRelation                            from $EnvDB.dbo.xRefTableRelation
IF OBJECT_ID ( '$EnvDB.dbo.xRefTmpReferences' )                           IS NOT NULL    select * into $EnvDBOrig.dbo.xRefTmpReferences                            from $EnvDB.dbo.xRefTmpReferences

IF OBJECT_ID ( '$EnvDB.dbo.SYSConfig' )                                   IS NOT NULL    select * into $EnvDBOrig.dbo.SYSConfig                                    from $EnvDB.dbo.SYSConfig
IF OBJECT_ID ( '$EnvDB.dbo.SYSLICENSECODESORT' )                          IS NOT NULL    select * into $EnvDBOrig.dbo.SYSLICENSECODESORT                           from $EnvDB.dbo.SYSLICENSECODESORT

IF OBJECT_ID ( '$EnvDB.dbo.SQLDictionary' )                               IS NOT NULL    select * into $EnvDBOrig.dbo.SQLDictionary                                from $EnvDB.dbo.SQLDictionary

select
     row_number() over (order by Name) as RowNum
    ,name
    ,default_schema_name
into $EnvDBOrig.dbo.sysAdmin_DBUsers
from $EnvDB.sys.database_principals
where type in ('U','G')
    and name <> 'dbo'
GO

select
     row_number() over (order by Name) as RowNum
    ,name
    into $EnvDBOrig.dbo.SysAdmin_DBSchemas
from $EnvDB.sys.schemas
where name like 'global%'
GO

select
    row_number() over (order by sysServerPrincipal.name) as RowNum
    ,sysServerPrincipal.name as dbUser
    ,sysDatabasePrincipalRole.name as dbRole
into $EnvDBOrig.dbo.SysAdmin_DBUserRoles
from $EnvDB.sys.database_principals as sysDatabasePrincipalRole
    inner join $EnvDB.sys.database_role_members as sysDatabaseRoleMember
        on sysDatabaseRoleMember.role_principal_id = sysDatabasePrincipalRole.principal_id
    inner join $EnvDB.sys.database_principals as sysDatabasePrincipalMember
        on sysDatabasePrincipalMember.principal_id = sysDatabaseRoleMember.member_principal_id
    inner join $EnvDB.sys.server_principals as sysServerPrincipal
        on sysServerPrincipal.sid = sysDatabasePrincipalMember.sid
where sysServerPrincipal.type_desc in ('WINDOWS_LOGIN', 'WINDOWS_GROUP', 'SQL_LOGIN')
    and sysServerPrincipal.is_disabled = 0
GO
       
        "

        Write-Verbose "Creating Minimal Orig DB - $envDBOrig" -Verbose

        Invoke-Sqlcmd -ServerInstance $EnvServer -Database $envDBOrig -Query $SQL1

        $SQL2 = "
DECLARE @SQL VARCHAR(MAX)
SET @SQL = '
 
--If OBJECT_ID ( ''dbo.sp_CopyTable'', ''P'' ) IS NOT NULL 
--DROP PROCEDURE dbo.sp_CopyTable
 
--CREATE PROCEDURE dbo.sp_CopyTable
ALTER PROCEDURE dbo.sp_CopyTable
   @db_from                 NVARCHAR(100),
   @db_too                  NVARCHAR(100),
   @table                   NVARCHAR(100)
AS
BEGIN
    DECLARE @SQLS           VARCHAR(MAX)
    DECLARE @COLNAMES       VARCHAR(MAX)
    DECLARE @COLNAMES1      VARCHAR(MAX)
    DECLARE @COLNAMES2      VARCHAR(MAX)
    DECLARE @COLNAMESADD    VARCHAR(MAX)
    Declare @INDIVIDUAL     VARCHAR(30) = null
    DECLARE @CHECK          VARCHAR(100)
    Declare @VALUESADD      VARCHAR(100)
 
 
    IF OBJECT_ID ( ''dbo.SysAdmin_Log'' ) IS NULL Create table dbo.SysAdmin_Log (RECID int, DETAIL VarChar(MAX), TimeStamp datetime)
 
    insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), ''Start processing: '' + (select  @table), (select getdate()))
 
    IF OBJECT_ID ( ''dbo.SysAdmin_FieldList'' ) IS NOT NULL drop table dbo.SysAdmin_FieldList
    Create table dbo.SysAdmin_FieldList (FieldList VarChar(MAX))
 
    set @SQLS = ''DECLARE @COLS VARCHAR(max) ; select @COLS = coalesce(@COLS + '' + CHAR(39) + '','' + CHAR(39) + '','' + CHAR(39) + '''' + CHAR(39) + '') + column_name from ( SELECT AC.[name] AS [column_name] FROM ['' + @db_from + ''].sys.[tables] AS T INNER JOIN ['' + @db_from + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_from + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 and AC.[name] in ( SELECT AC.[name] AS [column_name] FROM ['' + @db_too + ''].sys.[tables] AS T INNER JOIN ['' + @db_too + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_too + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 ) ) a ; insert into dbo.SysAdmin_FieldList select @COLS ''
 
    insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select @SQLS), (select getdate()))
 
    exec (@SQLS)
 
    select @COLNAMES = fieldlist from dbo.SysAdmin_FieldList
 
    set @SQLS = ''insert into ['' + @db_too +''].dbo.'' + @table + '' ('' + @COLNAMES + '') select '' + @COLNAMES + '' from ['' + @db_from +''].dbo.'' + @table
 
    insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select @SQLS), (select getdate()))
 
    BEGIN TRY
        exec (@SQLS)
    END TRY
    BEGIN CATCH
        insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select ''SEQ Failed with fields '' + @COLNAMES), (select getdate()))
 
        Truncate table dbo.SysAdmin_FieldList
        set @SQLS = ''DECLARE @COLS VARCHAR(max) ; select @COLS = coalesce(@COLS + '' + CHAR(39) + '','' + CHAR(39) + '','' + CHAR(39) + '''' + CHAR(39) + '') + column_name from ( SELECT AC.[name] AS [column_name] FROM ['' + @db_too + ''].sys.[tables] AS T INNER JOIN ['' + @db_too + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_too + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 and AC.[name] not in ( SELECT AC.[name] AS [column_name] FROM ['' + @db_from + ''].sys.[tables] AS T INNER JOIN ['' + @db_from + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_from + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 ) ) a ; insert into dbo.SysAdmin_FieldList select @COLS ''
        exec (@SQLS)
 
        select @COLNAMESADD = fieldlist from dbo.SysAdmin_FieldList
        set @COLNAMES1 = @COLNAMES + '','' + @COLNAMESADD
 
        select @CHECK = fieldlist from dbo.SysAdmin_FieldList
 
        select @VALUESADD = ''''
 
        while len(@CHECK) > 0
        begin
            if patindex(''%,%'',@CHECK) > 0
            begin
                set @INDIVIDUAL = substring(@CHECK, 0, patindex(''%,%'',@CHECK))
                select @VALUESADD = @VALUESADD + '',0''
 
                set @check = substring(@CHECK, len(@INDIVIDUAL + ''|'') + 1, len(@CHECK))
            end
            else
            begin
                set @INDIVIDUAL = @CHECK
                set @CHECK = null
                select @VALUESADD = @VALUESADD + '',0''
            end
        end
 
        set @COLNAMES = @COLNAMES + @VALUESADD
 
        set @SQLS = ''insert into ['' + @db_too +''].dbo.'' + @table + '' ('' + @COLNAMES1 + '') select '' + @COLNAMES + '' from ['' + @db_from +''].dbo.'' + @table
 
        insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select @SQLS), (select getdate()))
 
        exec(@SQLS)
    END CATCH
END'
 

DECLARE @SQL1 VARCHAR(MAX)
SET @SQL1 = '
 
--If OBJECT_ID ( ''dbo.sp_CopyTable'', ''P'' ) IS NOT NULL 
--DROP PROCEDURE dbo.sp_CopyTable
 
CREATE PROCEDURE dbo.sp_CopyTable
--ALTER PROCEDURE dbo.sp_CopyTable
   @db_from                 NVARCHAR(100),
   @db_too                  NVARCHAR(100),
   @table                   NVARCHAR(100)
AS
BEGIN
    DECLARE @SQLS           VARCHAR(MAX)
    DECLARE @COLNAMES       VARCHAR(MAX)
    DECLARE @COLNAMES1      VARCHAR(MAX)
    DECLARE @COLNAMES2      VARCHAR(MAX)
    DECLARE @COLNAMESADD    VARCHAR(MAX)
    Declare @INDIVIDUAL     VARCHAR(30) = null
    DECLARE @CHECK          VARCHAR(100)
    Declare @VALUESADD      VARCHAR(100)
 
 
    IF OBJECT_ID ( ''dbo.SysAdmin_Log'' ) IS NULL Create table dbo.SysAdmin_Log (RECID int, DETAIL VarChar(MAX), TimeStamp datetime)
 
    insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), ''Start processing: '' + (select  @table), (select getdate()))
 
    IF OBJECT_ID ( ''dbo.SysAdmin_FieldList'' ) IS NOT NULL drop table dbo.SysAdmin_FieldList
    Create table dbo.SysAdmin_FieldList (FieldList VarChar(MAX))
 
    set @SQLS = ''DECLARE @COLS VARCHAR(max) ; select @COLS = coalesce(@COLS + '' + CHAR(39) + '','' + CHAR(39) + '','' + CHAR(39) + '''' + CHAR(39) + '') + column_name from ( SELECT AC.[name] AS [column_name] FROM ['' + @db_from + ''].sys.[tables] AS T INNER JOIN ['' + @db_from + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_from + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 and AC.[name] in ( SELECT AC.[name] AS [column_name] FROM ['' + @db_too + ''].sys.[tables] AS T INNER JOIN ['' + @db_too + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_too + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 ) ) a ; insert into dbo.SysAdmin_FieldList select @COLS ''
 
    insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select @SQLS), (select getdate()))
 
    exec (@SQLS)
 
    select @COLNAMES = fieldlist from dbo.SysAdmin_FieldList
 
    set @SQLS = ''insert into ['' + @db_too +''].dbo.'' + @table + '' ('' + @COLNAMES + '') select '' + @COLNAMES + '' from ['' + @db_from +''].dbo.'' + @table
 
    insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select @SQLS), (select getdate()))
 
    BEGIN TRY
        exec (@SQLS)
    END TRY
    BEGIN CATCH
        insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select ''SEQ Failed with fields '' + @COLNAMES), (select getdate()))
 
        Truncate table dbo.SysAdmin_FieldList
        set @SQLS = ''DECLARE @COLS VARCHAR(max) ; select @COLS = coalesce(@COLS + '' + CHAR(39) + '','' + CHAR(39) + '','' + CHAR(39) + '''' + CHAR(39) + '') + column_name from ( SELECT AC.[name] AS [column_name] FROM ['' + @db_too + ''].sys.[tables] AS T INNER JOIN ['' + @db_too + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_too + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 and AC.[name] not in ( SELECT AC.[name] AS [column_name] FROM ['' + @db_from + ''].sys.[tables] AS T INNER JOIN ['' + @db_from + ''].sys.[all_columns] AC ON T.[object_id] = AC.[object_id] INNER JOIN ['' + @db_from + ''].sys.[types] TY ON AC.[system_type_id] = TY.[system_type_id] AND AC.[user_type_id] = TY.[user_type_id] WHERE T.[name] = '' + CHAR(39) + '''' + @table + '''' + CHAR(39) + '' and T.[is_ms_shipped] = 0 ) ) a ; insert into dbo.SysAdmin_FieldList select @COLS ''
        exec (@SQLS)
 
        select @COLNAMESADD = fieldlist from dbo.SysAdmin_FieldList
        set @COLNAMES1 = @COLNAMES + '','' + @COLNAMESADD
 
        select @CHECK = fieldlist from dbo.SysAdmin_FieldList
 
        select @VALUESADD = ''''
 
        while len(@CHECK) > 0
        begin
            if patindex(''%,%'',@CHECK) > 0
            begin
                set @INDIVIDUAL = substring(@CHECK, 0, patindex(''%,%'',@CHECK))
                select @VALUESADD = @VALUESADD + '',0''
 
                set @check = substring(@CHECK, len(@INDIVIDUAL + ''|'') + 1, len(@CHECK))
            end
            else
            begin
                set @INDIVIDUAL = @CHECK
                set @CHECK = null
                select @VALUESADD = @VALUESADD + '',0''
            end
        end
 
        set @COLNAMES = @COLNAMES + @VALUESADD
 
        set @SQLS = ''insert into ['' + @db_too +''].dbo.'' + @table + '' ('' + @COLNAMES1 + '') select '' + @COLNAMES + '' from ['' + @db_from +''].dbo.'' + @table
 
        insert into dbo.SysAdmin_Log values ((select count(*) from dbo.SysAdmin_Log), (select @SQLS), (select getdate()))
 
        exec(@SQLS)
    END CATCH
END'
 

IF OBJECT_ID('dbo.sp_CopyTable', 'P') IS NOT NULL
 
BEGIN
EXEC (@SQL)
END
ELSE
BEGIN
EXEC (@SQL1)
END
 

        "

        Write-Verbose "Creating SP_CopyTable - $envDBOrig" -Verbose
        Invoke-Sqlcmd -ServerInstance $EnvServer -Database $envDBOrig -Query $SQL2

        $SQL3 = "
        
DECLARE @SQL VARCHAR(MAX)
SET @SQL = '

-- Select OBJECT_ID ( ''dbo.sp_ReplaceConfigData'', ''P'' )
-- If OBJECT_ID ( ''dbo.sp_ReplaceConfigData'', ''P'' ) IS NOT NULL DROP PROCEDURE dbo.sp_ReplaceConfigData

--CREATE PROCEDURE dbo.sp_ReplaceConfigData
alter PROCEDURE dbo.sp_ReplaceConfigData
   @db_orig                 NVARCHAR(100),
   @db_new                  NVARCHAR(100),
   @table                   NVARCHAR(100),
   @instructions            NVARCHAR(100) = ''NONE''
AS
BEGIN
    DECLARE @SpacesStr      nvarchar(100) = ''                                                                                                                   ''
    DECLARE @Object_orig    NVARCHAR(200) = quotename(@db_orig) + ''.dbo.'' + quotename(@table)
    DECLARE @Object_new     NVARCHAR(200) = quotename(@db_new) + ''.dbo.'' + quotename(@table)
    DECLARE @SQLStr         NVARCHAR(200)
    DECLARE @PrintTableName NVARCHAR(200) = substring(upper(@table) + @SpacesStr,1,40)
    DECLARE @ParmDefinition nvarchar(200);
    DECLARE @RecordCount    Int
    DECLARE @IssueStr       nvarchar(50) = ''ISSUE''

    set nocount on

    print '' ''

    IF OBJECT_ID ( @Object_orig ) IS NULL
        begin
            print @PrintTableName + '': Table NOT found in original database''

            IF OBJECT_ID ( @Object_new ) IS NULL
                begin
                    print @PrintTableName + '': Table NOT found in new database''
                end
            else
                begin
                    print @PrintTableName + '': Table exists in new database (deleting contents in new database)''
                    set @SQLStr = N''delete from '' + @Object_new
                    exec(@SQLStr)
                    print @PrintTableName + '': '' + ltrim(str(@@ROWCOUNT)) + '' rows deleted''
                end
        end
    else
        begin
            print @PrintTableName + '': Table found in original database''

            IF OBJECT_ID ( @Object_new ) IS NULL
                begin
                    print substring(@PrintTableName + '': Table not found in new database'' + @SpacesStr,1,130) + @IssueSTR
                end
            else
                begin
                    set @SQLStr = N''select @RecordCountOUT = COUNT(*) from '' + @Object_new
                    exec sp_executesql @SQLStr, N''@RecordCountOUT int out'', @RecordCount OUT

                    if ( @RecordCount ) = 0
                        begin
                            print @PrintTableName + '': No record found in new database''
                        end
                    else
                        begin
                            print @PrintTableName + '': Records found in new database (deleting old records)''
                            set @SQLStr = N''delete from '' + @Object_new
                            exec(@SQLStr)
                            print @PrintTableName + '': '' + ltrim(str(@@ROWCOUNT)) + '' rows deleted''

                        end

                    if  @instructions <> ''DELETE NEW ONLY''
                        begin
                            set @SQLStr = N''select @RecordCountOUT = COUNT(*) from '' + @Object_orig
                            exec sp_executesql @SQLStr, N''@RecordCountOUT int out'', @RecordCount OUT

                            if ( @RecordCount ) = 0
                                begin
                                    print @PrintTableName + '': No record founds in original database''
                                end
                            else
                                begin
                                    print @PrintTableName + '': Records found in original database (inserting contents in to new database)''
                                    exec dbo.sp_CopyTable @db_orig, @db_new ,@table

                                    set @SQLStr = N''select @RecordCountOUT = COUNT(*) from '' + @Object_new
                                    exec sp_executesql @SQLStr, N''@RecordCountOUT int out'', @RecordCount OUT
                                    print @PrintTableName + '': '' + ltrim(str(@RecordCount)) + '' rows Inserted''
                                end
                        end
                end
        end


    set nocount off
END


'

DECLARE @SQL1 VARCHAR(MAX)
SET @SQL1 = '

-- Select OBJECT_ID ( ''dbo.sp_ReplaceConfigData'', ''P'' )
-- If OBJECT_ID ( ''dbo.sp_ReplaceConfigData'', ''P'' ) IS NOT NULL DROP PROCEDURE dbo.sp_ReplaceConfigData

CREATE PROCEDURE dbo.sp_ReplaceConfigData
--alter PROCEDURE dbo.sp_ReplaceConfigData
   @db_orig                 NVARCHAR(100),
   @db_new                  NVARCHAR(100),
   @table                   NVARCHAR(100),
   @instructions            NVARCHAR(100) = ''NONE''
AS
BEGIN
    DECLARE @SpacesStr      nvarchar(100) = ''                                                                                                                        ''
    DECLARE @Object_orig    NVARCHAR(200) = quotename(@db_orig) + ''.dbo.'' + quotename(@table)
    DECLARE @Object_new     NVARCHAR(200) = quotename(@db_new) + ''.dbo.'' + quotename(@table)
    DECLARE @SQLStr         NVARCHAR(200)
    DECLARE @PrintTableName NVARCHAR(200) = substring(upper(@table) + @SpacesStr,1,40)
    DECLARE @ParmDefinition nvarchar(200);
    DECLARE @RecordCount    Int
    DECLARE @IssueStr       nvarchar(50) = ''ISSUE''

    set nocount on

    print '' ''

    IF OBJECT_ID ( @Object_orig ) IS NULL
        begin
            print @PrintTableName + '': Table NOT found in original database''

            IF OBJECT_ID ( @Object_new ) IS NULL
                begin
                    print @PrintTableName + '': Table NOT found in new database''
                end
            else
                begin
                    print @PrintTableName + '': Table exists in new database (deleting contents in new database)''
                    set @SQLStr = N''delete from '' + @Object_new
                    exec(@SQLStr)
                    print @PrintTableName + '': '' + ltrim(str(@@ROWCOUNT)) + '' rows deleted''
                end
        end
    else
        begin
            print @PrintTableName + '': Table found in original database''

            IF OBJECT_ID ( @Object_new ) IS NULL
                begin
                    print substring(@PrintTableName + '': Table not found in new database'' + @SpacesStr,1,130) + @IssueSTR
                end
            else
                begin
                    set @SQLStr = N''select @RecordCountOUT = COUNT(*) from '' + @Object_new
                    exec sp_executesql @SQLStr, N''@RecordCountOUT int out'', @RecordCount OUT

                    if ( @RecordCount ) = 0
                        begin
                            print @PrintTableName + '': No record found in new database''
                        end
                    else
                        begin
                            print @PrintTableName + '': Records found in new database (deleting old records)''
                            set @SQLStr = N''delete from '' + @Object_new
                            exec(@SQLStr)
                            print @PrintTableName + '': '' + ltrim(str(@@ROWCOUNT)) + '' rows deleted''

                        end

                    if  @instructions <> ''DELETE NEW ONLY''
                        begin
                            set @SQLStr = N''select @RecordCountOUT = COUNT(*) from '' + @Object_orig
                            exec sp_executesql @SQLStr, N''@RecordCountOUT int out'', @RecordCount OUT

                            if ( @RecordCount ) = 0
                                begin
                                    print @PrintTableName + '': No record founds in original database''
                                end
                            else
                                begin
                                    print @PrintTableName + '': Records found in original database (inserting contents in to new database)''
                                    exec dbo.sp_CopyTable @db_orig, @db_new ,@table

                                    set @SQLStr = N''select @RecordCountOUT = COUNT(*) from '' + @Object_new
                                    exec sp_executesql @SQLStr, N''@RecordCountOUT int out'', @RecordCount OUT
                                    print @PrintTableName + '': '' + ltrim(str(@RecordCount)) + '' rows Inserted''
                                end
                        end
                end
        end


    set nocount off
END


'

IF OBJECT_ID('dbo.sp_ReplaceConfigData', 'P') IS NOT NULL
 
BEGIN
EXEC (@SQL)
END
ELSE
BEGIN
EXEC (@SQL1)
END
        
        "

        Write-Verbose "Creating SP_ReplaceConfigData - $envDBOrig" -Verbose
        Invoke-Sqlcmd -ServerInstance $EnvServer -Database $envDBOrig -Query $SQL3

        Set-Location c:\

        $BKUPs = Get-ChildItem "$EnvDrive\$EnvfolderName" | Where-Object Name -like "*$RestoreFrom*" | Sort-Object -Descending

        foreach ($BK in $BKUPs) {

            $DB = switch -Wildcard ($BK.Name) {
                '*Model*' { "AX2012_$Environment" + "_Model" }
                default { "AX2012_$Environment" }
            }

            $EnvBKFile = "$DB $Date.bak"
            $EnvPath = "$EnvDrive\$EnvfolderName\$EnvBKFile"                  

            Write-Verbose "Backing up $DB" -Verbose

            Backup-SqlDatabase -ServerInstance $EnvServer -Database $DB -BackupFile $EnvPath

            Get-Service -ComputerName $EnvServer -Name "MSSQLSERVER" | Restart-Service -Force

            Write-Verbose "Restoring up $DB" -Verbose

            Restore-SqlDatabase -ServerInstance $EnvServer -Database $DB -BackupFile $BK.FullName -ReplaceDatabase 


        }

        Start-Sleep -Seconds 30

        $SQL4 = "
        -- *******************************************************************************
-- * Copy environment specific settings from [$EnvDBOrig]                     *
-- * to [$EnvDB] database                                                      *
-- *                                                                             *
-- * NB: Before running correct the two variables at the top of this script      *
-- *     and run this script from the original database                          *
-- *                                                                             *
-- *                                                                             *
-- *******************************************************************************

DECLARE @db_orig                    NVARCHAR(100) = '$EnvDBOrig'
DECLARE @db_new                     NVARCHAR(100) = '$EnvDB'

-- If moving model as well as data set below to 'NO'
-- Otherwise set to 'YES'
DECLARE @DoSQLDictionary            NVARCHAR(30)  = 'YES'

DECLARE @DoDataCorrection           NVARCHAR(30)  = 'YES'
DECLARE @DoMRUrlUpdate              NVARCHAR(30)  = 'YES'
DECLARE @DoAXUsersUpdate            NVARCHAR(30)  = 'YES'
DECLARE @DoUserRoleSchemaUpdate     NVARCHAR(30)  = 'YES'
DECLARE @DoEmailAddrCorruption      NVARCHAR(30)  = 'YES'
DECLARE @DoMorphXUpdate             NVARCHAR(30)  = 'YES'

-- Preserve licence information in target
DECLARE @DoSysLicence               NVARCHAR(30)  = 'YES'

DECLARE @SQLStr                     NVARCHAR(MAX)
DECLARE @BigSQL                     NVARCHAR(MAX)
DECLARE @NameStr                    NVARCHAR(100)
DECLARE @SchemaStr                  NVARCHAR(100)
DECLARE @dbUserStr                  NVARCHAR(100)
DECLARE @dbRoleStr                  NVARCHAR(100)
DECLARE @i                          INT
DECLARE @numrows                    INT

If DB_ID ( @db_orig ) IS NULL
    begin
        print 'AX_Orig-AX.sql: Database (' + @db_orig  + ') does not exist'
        return
    end

If DB_ID ( @db_new ) IS NULL
    begin
        print 'AX_Orig-AX.sql: Database (' + @db_new  + ') does not exist'
        return
    end

If (select DB_NAME()) <> @db_orig
    begin
        print 'AX_Orig-AX.sql: Running from the wrong database'
        print '                This script needs to be run from ' + @db_orig + ' database'
        return
    end

If OBJECT_ID ( 'dbo.sp_CopyTable', 'P' ) IS NULL
    begin
        print 'AX_Orig-AX.sql: Procedure dbo.sp_CopyTable not found'
        print '                Run Procedure-dbo.sp_CopyTable.sql'
        return
    end

If OBJECT_ID ( 'dbo.sp_ReplaceConfigData', 'P' ) IS NULL
    begin
        print 'AX_Orig-AX.sql: Procedure dbo.sp_ReplaceConfigData not found'
        print '                Run Procedure-dbo.sp_ReplaceConfigData.sql'
        return
    end


--If OBJECT_ID ( 'dbo.SysAdmin_Log' ) IS NOT NULL
--    begin
--        truncate table dbo.SysAdmin_Log
--    end

print ' '
print '------- PROCESS START  ------------'

if (select @DoDataCorrection) = 'YES'
    begin
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'bianalysisserver'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'biconfiguration'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'DocuParameters'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'docutype'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'epglobalparameters'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'epwebsiteparameters'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'srsservers'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysbcproxyuseraccount'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysclusterconfig'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysemailsmtppassword'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysserverconfig'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysserversessions'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysworkflowparameters'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'vendpaymmodetable'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysTaskRecorderParameters'

        print ' '
        print '------- Workflow  -----------------'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'batch'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'BatchGroup'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'BatchJob'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'BatchServerConfig'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'BatchServerGroup'

        print ' '
        print '------- Workflow End  -------------'


        print ' '
        print '------- AIF -----------------------'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifAction'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifAdapter'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifAppsharefile'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifChannel'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifDatapolicy'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifDocumentfield'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifDocumentschematable'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifEndpointactionvaluemap'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifGlobalsettings'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifPort'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifPortactionpolicy'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifPortdocument'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifRuntimecache'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifSchemastore'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifService'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifSqlcdcenabledtables'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifSqlcttriggers'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'aifWcfconfiguration'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifWebsites'

        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifPipeline'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifPipelineComponent'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifXmlTransformConfig'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifTransformElement'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifTransform'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'AifXsltRepository'

        print ' '
        print '------- AIF End -------------------'


        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'CUSTVENDAIFPAYMTABLE'

        print ' '
        print '------- DMF End -------------------'

        print ' '
        print '------- Other ---------------------'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SYSGLOBALCONFIGURATION'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SYSFILESTOREPARAMETERS'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'COLLABSITEPARAMETERS'

        print ' '
        print '------- Other End -----------------'

        print ' '
        print '------- xRef ----------------------'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'xRefDialogUpdate'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'xRefNames'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'xRefPaths'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'xRefReferences'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'xRefTableRelation'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'xRefTmpReferences'

        print ' '
        print '------- xRef End ------------------'
    END


if (select @DoSysLicence) = 'YES'
    begin
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SYSConfig'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SYSLICENSECODESORT'
    END


if (select @DoMorphXUpdate) = 'YES'
    begin
        print ' '
        print '------- MorphX --------------------'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysVersionControlMorphXItemTable'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysVersionControlMorphXLockTable'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysVersionControlMorphXRevisionTable'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysVersionControlParameters'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysVersionControlPendingChangeList'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysVersionControlSynchronizeLog'

        print ' '
        print '------- MorphX End ----------------'
    END



if (select @DoAXUsersUpdate) = 'YES'
    begin
        print ' '
        print '------- User ----------------------'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'userinfo'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'dirpersonuser'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysUserInfo'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SecurityUserRole'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'userexternalparty'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'sysuserprofiles'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'usergroupinfo'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'usergrouplist'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SysClientSessions', 'DELETE NEW ONLY'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'OMUserRoleOrganization'
        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'OMUserRoleOUs'

        print ' '
        print '------- User End ------------------'
    END



if (select @DoMRUrlUpdate) = 'YES'
    begin
        print ' '
        print '------- MR ------------------------'

        set @SQLStr = N'update ' + @db_new + '.dbo.ledgerparameters set managementreporterurl = (select managementreporterurl from ' + @db_orig + '.dbo.ledgerparameters lp where lp.dataareaid = ' + @db_new + '.dbo.ledgerparameters.dataareaid)'

        BEGIN TRY
            exec(@SQLStr)
        END TRY
        BEGIN CATCH
            print ' '
            print 'LEDGERPARAMETERS         : Failed to set Management Reporter URL in new database'
        END CATCH

        print ' '
        print '------- MR End --------------------'
    END


    

if (select @DoUserRoleSchemaUpdate) = 'YES'
    begin
        print ' '
        print '------- User/Role/Schema ----------'

        -- Delete existing entries

        set @SQLStr = N'drop table dbo.SysAdmin_DBSchemasToDelete'
        PRINT 'Running statement        : ' + @SQLStr
        BEGIN TRY
            EXEC (@SQLStr)
        END TRY
        BEGIN CATCH
            print '                         : Table not found'
            print ' '
        END CATCH

        set @SQLStr = N'select row_number() over (order by Name) as RowNum ,name into ' + @db_orig + '.dbo.SysAdmin_DBSchemasToDelete from ' + @db_new + '.sys.schemas where name like ''global%'''
        PRINT 'Running statement        : ' + @SQLStr
        EXEC (@SQLStr)

        SET @i = 1

        set @SQLStr = N'select @CountOUT = count(*) from ' + @db_Orig + '.dbo.SysAdmin_DBSchemasToDelete'
        exec sp_executesql @SQLStr, N'@CountOUT int out', @numrows OUT

        IF @numrows > 0
        BEGIN
            WHILE (@i <= @numrows)
            BEGIN
                set @SQLStr = N'select @SchemeOUT = Name from ' + @db_Orig + '.dbo.SysAdmin_DBSchemasToDelete where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@SchemeOUT NVARCHAR(100) out', @SchemaStr OUT

                set @SQLStr = N'DROP SCHEMA [' + @SchemaStr + ']'
                PRINT 'Running statement        : ' + @SQLStr

                SET @BigSQL = 'USE [' + @db_New + '] EXEC sp_executesql N''' + @SQLStr + ''''

                BEGIN TRY
                    EXEC (@BigSQL)
                END TRY
                BEGIN CATCH
                    print '                         : Failed to drop schema'
                    print ' '
                END CATCH

                SET @i = @i + 1
            END
        END

        set @SQLStr = N'drop table dbo.SysAdmin_DBUsersToDelete'
        PRINT 'Running statement        : ' + @SQLStr
        BEGIN TRY
            EXEC (@SQLStr)
        END TRY
        BEGIN CATCH
            print '                         : Table not found'
            print ' '
        END CATCH

        set @SQLStr = N'select row_number() over (order by Name) as RowNum ,name into ' + @db_orig + '.dbo.SysAdmin_DBUsersToDelete from ' + @db_new + '.sys.database_principals where type = ''U'' and name <> ''dbo'''
        PRINT 'Running statement        : ' + @SQLStr
        EXEC (@SQLStr)

        SET @i = 1

        set @SQLStr = N'select @CountOUT = count(*) from ' + @db_Orig + '.dbo.SysAdmin_DBUsersToDelete'
        exec sp_executesql @SQLStr, N'@CountOUT int out', @numrows OUT

        IF @numrows > 0
        BEGIN
            WHILE (@i <= @numrows)
            BEGIN
                set @SQLStr = N'select @UserOut = Name from ' + @db_Orig + '.dbo.SysAdmin_DBUsersToDelete where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@UserOut NVARCHAR(100) out', @NameStr OUT

                set @SQLStr = N'DROP USER [' + @NameStr + ']'
                PRINT 'Running statement        : ' + @SQLStr

                SET @BigSQL = 'USE [' + @db_New + '] EXEC sp_executesql N''' + @SQLStr + ''''

                BEGIN TRY
                    EXEC (@BigSQL)
                END TRY
                BEGIN CATCH
                    print '                         : Failed to drop schema'
                    print ' '
                END CATCH

                SET @i = @i + 1
            END
        END

        -- Create new entries

        SET @i = 1

        set @SQLStr = N'select @CountOUT = count(*) from ' + @db_Orig + '.dbo.SysAdmin_DBUsers'
        exec sp_executesql @SQLStr, N'@CountOUT int out', @numrows OUT

        IF @numrows > 0
        BEGIN
            WHILE (@i <= @numrows)
            BEGIN
                set @SQLStr = N'select @NameOUT = Name from ' + @db_Orig + '.dbo.SysAdmin_DBUsers where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@NameOUT NVARCHAR(100) out', @NameStr OUT

                set @SQLStr = N'select @SchemeOUT = Default_Schema_Name from ' + @db_Orig + '.dbo.SysAdmin_DBUsers where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@SchemeOUT NVARCHAR(100) out', @SchemaStr OUT

                IF @SchemaStr is null
                BEGIN
                    SET @SQLStr = N'CREATE USER [' + @NameStr + '] FOR LOGIN [' + @NameStr + ']'
                END
                ELSE
                BEGIN
                    SET @SQLStr = N'CREATE USER [' + @NameStr + '] FOR LOGIN [' + @NameStr + '] WITH DEFAULT_SCHEMA = [' + @SchemaStr + ']'
                END

                PRINT 'Running statement        : ' + @SQLStr

                SET @BigSQL = 'USE [' + @db_New + '] EXEC sp_executesql N''' + @SQLStr + ''''

                BEGIN TRY
                    EXEC (@BigSQL)
                END TRY
                BEGIN CATCH
                    print '                         : Failed to create user'
                    print ' '
                END CATCH

                SET @i = @i + 1
            END
        END

        SET @i = 1

        set @SQLStr = N'select @CountOUT = count(*) from ' + @db_Orig + '.dbo.SysAdmin_DBSchemas'
        exec sp_executesql @SQLStr, N'@CountOUT int out', @numrows OUT

        IF @numrows > 0
        BEGIN
            WHILE (@i <= @numrows)
            BEGIN
                set @SQLStr = N'select @NameOUT = Name from ' + @db_Orig + '.dbo.SysAdmin_DBSchemas where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@NameOUT NVARCHAR(100) out', @NameStr OUT

                set @SQLStr = N'CREATE SCHEMA [' + @NameStr + ']'
                PRINT 'Running statement        : ' + @SQLStr

                SET @BigSQL = 'USE [' + @db_New + '] EXEC sp_executesql N''' + @SQLStr + ''''

                BEGIN TRY
                    EXEC (@BigSQL)
                END TRY
                BEGIN CATCH
                    print '                         : Failed to create schema'
                    print ' '
                END CATCH

                ---------------------

                set @SQLStr = N'select @NameOUT = Name from ' + @db_Orig + '.dbo.SysAdmin_DBSchemas where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@NameOUT NVARCHAR(100) out', @NameStr OUT

                set @SQLStr = N'ALTER AUTHORIZATION ON SCHEMA::[' + @NameStr + '] TO [' + @NameStr + ']'
                PRINT 'Running statement        : ' + @SQLStr

                SET @BigSQL = 'USE [' + @db_New + '] EXEC sp_executesql N''' + @SQLStr + ''''

                BEGIN TRY
                    EXEC (@BigSQL)
                END TRY
                BEGIN CATCH
                    print '                         : Failed to apply user to schema'
                    print ' '
                END CATCH

                SET @i = @i + 1
            END
        END

        SET @i = 1

        set @SQLStr = N'select @CountOUT = count(*) from ' + @db_Orig + '.dbo.SysAdmin_DBUserRoles'
        exec sp_executesql @SQLStr, N'@CountOUT int out', @numrows OUT


        IF @numrows > 0
        BEGIN
            WHILE (@i <= @numrows)
            BEGIN
                set @SQLStr = N'select @dbUserOUT = dbUser from ' + @db_Orig + '.dbo.SysAdmin_DBUserRoles where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@dbUserOUT NVARCHAR(100) out', @dbUserStr OUT

                set @SQLStr = N'select @dbRoleOUT = dbRole from ' + @db_Orig + '.dbo.SysAdmin_DBUserRoles where RowNum = ' + cast (@i as NVARCHAR)
                exec sp_executesql @SQLStr, N'@dbRoleOUT NVARCHAR(100) out', @dbRoleStr OUT

                set @SQLStr = N'ALTER ROLE [' + rtrim(@dbRoleStr) + '] ADD MEMBER [' + rtrim(@dbUserStr) + ']'
                PRINT 'Running statement        : ' + @SQLStr

                SET @BigSQL = 'USE [' + @db_New + '] EXEC sp_executesql N''' + @SQLStr + ''''

                BEGIN TRY
                    EXEC (@BigSQL)
                END TRY
                BEGIN CATCH
                    print '                         : Failed to add role to user'
                    print ' '
                END CATCH

                SET @i = @i + 1
            END
        END

        print ' '
        print '------- User/Role/Schema End ------'
    END



if (select @DoEmailAddrCorruption) = 'YES'
    begin
        print ' '
        print '--- Email Address Corruption ------'

        set @SQLStr = N'select @CountOUT = count(*) from ' + @db_new + '.dbo.LogisticsElectronicAddress where locator like ''%@%'''
        exec sp_executesql @SQLStr, N'@CountOUT int out', @numrows OUT

        IF @numrows > 0
        BEGIN
            set @SQLStr = N'Update ' + @db_new + '.dbo.LogisticsElectronicAddress set locator = Replace(locator,''@'',''$'') where locator like ''%@%'''
            PRINT 'Running statement        : ' + @SQLStr

            BEGIN TRY
                EXEC (@SQLStr)
            END TRY
            BEGIN CATCH
                print '                         : Failed to corrupt email addresses'
                print ' '
            END CATCH
        END
        ELSE
        BEGIN
            print '                         : No email addresses found to corrupt'
        END

        print ' '
        print '--- Email Address Corruption End --'
        print ' '
    END

if (select @DoSQLDictionary) = 'YES'
    begin
        print ' '
        print '--------- SQLDictionary -----------'

        exec dbo.sp_ReplaceConfigData @db_orig, @db_new, 'SQLDictionary'

        print ' '
        print '------- SQLDictionary End ---------'
        print ' '
    END

print '------ PROCESS END  ---------------'
print ' '


        
        "

        Write-Verbose "Copying config from $envDBOrig to $EnvDB - $envDBOrig" -Verbose
        Invoke-Sqlcmd -ServerInstance $EnvServer -Database $envDBOrig -Query $SQL4

        $SQL5 = "      
print '** BEGIN **'
declare @tabid int, @nextval bigint, @lastUsed bigint, @sql NVARCHAR(4000),
@msgName varchar(250), @tablename varchar(250)
DECLARE loopTrough CURSOR FOR
select TABID, NEXTVAL from systemsequences where systemsequences.Name =
'SEQNO' and
systemsequences.dataareaid = 'dat' and
systemsequences.TabId > 0

open loopTrough

FETCH next FROM loopTrough INTO @TABID, @nextval
WHILE @@FETCH_STATUS = 0
BEGIN

set @tablename = isnull((select [SQLNAME] from sqldictionary where
sqldictionary.fieldid = 0 and sqldictionary.TableId = @tabid), '')

if @tablename <> ''
set @msgName = @tablename + '(No. ' + convert(varchar(20), @tabid) + ')'
else
set @msgName = '(No. ' + convert(varchar(20), @tabid) + ')'

print 'Analyze ' + @msgName + ' ...'

IF @tablename <> '' and
EXISTS (SELECT 1
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE='BASE TABLE'
AND TABLE_NAME=@tablename)
begin

set @sql = N'SELECT @ret = MAX(RECID) FROM ' + @tablename
EXEC sp_executesql @sql, N'@ret bigint OUTPUT', @lastUsed OUTPUT

if (@nextVal < @lastUsed)
begin
print 'Update--> ' + @msgName + ' has to be corrected (next RecId: ' + convert(varchar(250),
@nextVal) + ' < max RecID: ' + convert(varchar(250), @lastUsed) + ')'
update systemsequences set nextval = (@lastUsed + 1) where
systemsequences.Name = 'SEQNO' and
systemsequences.tabId = @tabid and
systemsequences.dataareaid = 'dat'
print '> corrected; next RecId: ' + convert(varchar(250), @lastUsed + 1)
end
end
else
begin
print @msgName + ' not in SQLDictionary or Table not in DataBase'
end

FETCH next FROM loopTrough INTO @TABID, @nextval
END
close loopTrough
DEALLOCATE loopTrough
print '** Finish **'

        "

        Write-Verbose "Correcting RecIDs in $EnvDB - $envDBOrig" -Verbose
        Invoke-Sqlcmd -ServerInstance $EnvServer -Database $envDB -Query $SQL5

        Write-Verbose "Starting AX service on $EnvAOS" -Verbose
        Get-Service -ComputerName $EnvAOS -DisplayName "*AX Object Server*" | Start-Service

    }
    End {

        $End = Get-Date -Format "HH:mm:ss"

        $Start
        $End 

    }
}