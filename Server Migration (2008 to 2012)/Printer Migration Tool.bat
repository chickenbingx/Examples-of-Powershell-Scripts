@echo off
for /f "tokens=4-7 delims=[.] " %%i in ('ver') do (if %%i==Version (set v=%%j.%%k) else (set v=%%i.%%j))

if exist d:\ set drive=D:\
if exist e:\ set drive=E:\

set servername=%computername%
set printerfolder=%Drive%\Printer_Migration
set printbrm_Local=c:\Windows\System32\spool\tools

if "%V%"=="6.1" goto s2008
if "%V%"=="6.3" goto s2012


:s2008

if exist %printerfolder% (goto Printer_Migration) else goto Create_Folder

:create_Folder

mkdir "%PrinterFolder%"

goto Printer_Migration

:Printer_Migration

cd /d %printbrm_Local%

printbrm -b -s \\%servername% -f %PrinterFolder%\Printer_BKUP.printerexport

goto Finish

:s2012

cd /d %printbrm_Local%

PrintBrm /R /F %PrinterFolder%\Printer_BKUP.printerexport

goto finish

:Finish