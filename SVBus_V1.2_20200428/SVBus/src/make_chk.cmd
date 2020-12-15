REM set target path
set TARGETPATH=.\bin

REM set DDK path
set DDKDIR=C:\WinDDK\7600.16385.1

REM remove and recreate target path
rmdir %TARGETPATH% /S /Q
mkdir %TARGETPATH%

REM build x86 driver
setlocal
call %DDKDIR%\bin\setenv.bat %DDKDIR% chk x86 WNET
cd /d %~dp0
if not exist obj%BUILD_ALT_DIR% mkdir obj%BUILD_ALT_DIR%
build -cewgZ /jpath obj%BUILD_ALT_DIR%
endlocal
if errorlevel 1 goto :error

REM build x64 driver
setlocal
call %DDKDIR%\bin\setenv.bat %DDKDIR% chk x64 WNET
cd /d %~dp0
if not exist obj%BUILD_ALT_DIR% mkdir obj%BUILD_ALT_DIR%
build -cewgZ /jpath obj%BUILD_ALT_DIR%
endlocal
if errorlevel 1 goto :error

REM copy driver files to bin directory
copy gpl.txt %TARGETPATH%\
copy objchk_wnet_x86\i386\svbusx86.sys %TARGETPATH%\
copy objchk_wnet_AMD64\amd64\svbusx64.sys %TARGETPATH%\
copy svbus.inf %TARGETPATH%\
copy txtsetup.oem %TARGETPATH%\

REM sign driver files
setlocal
PATH=%PATH%;%DDKDIR%\bin\selfsign;%DDKDIR%\bin\x86
inf2cat /driver:%TARGETPATH% /os:Server2003_X86,Server2003_X64 /verbose
makecert -$ individual -r -pe -ss MY -n CN="SVBus" %TARGETPATH%\SVBus.cer
signtool.exe sign /v /s MY /n "SVBus" %TARGETPATH%\*.sys %TARGETPATH%\*.cat
certmgr -del -c -n "SVBus" -s -r currentUser MY
endlocal
if errorlevel 1 goto :error

REM cleanup
REM do not delete the checked object folders, because we need the PDB file for debugging
REM rmdir "objchk_wnet_x86" /S /Q
REM rmdir "objchk_wnet_amd64" /S /Q
del %TARGETPATH%\SVBus.cer
goto :end

REM show error message
:error
color 0C
echo Build errors occurred
pause
exit

:end
color 0A
echo Build succeeded
pause