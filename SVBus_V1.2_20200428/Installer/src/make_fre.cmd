REM set target path
set TARGETPATH=.\bin

REM set DDK path
set DDKDIR=C:\WinDDK\7600.16385.1

REM remove and recreate target path
rmdir %TARGETPATH% /S /Q
mkdir %TARGETPATH%

REM build x86 executable
setlocal
call %DDKDIR%\bin\setenv.bat %DDKDIR% fre x86 WNET
cd /d %~dp0
if not exist obj%BUILD_ALT_DIR% mkdir obj%BUILD_ALT_DIR%
build -cewgZ /jpath obj%BUILD_ALT_DIR%
endlocal
if errorlevel 1 goto :error

REM build x64 executable
setlocal
call %DDKDIR%\bin\setenv.bat %DDKDIR% fre x64 WNET
cd /d %~dp0
if not exist obj%BUILD_ALT_DIR% mkdir obj%BUILD_ALT_DIR%
build -cewgZ /jpath obj%BUILD_ALT_DIR%
endlocal
if errorlevel 1 goto :error

REM copy executables to bin directory
copy objfre_wnet_x86\i386\instx86.exe %TARGETPATH%\
copy objfre_wnet_AMD64\amd64\instx64.exe %TARGETPATH%\

REM cleanup
rmdir "objfre_wnet_x86" /S /Q
rmdir "objfre_wnet_amd64" /S /Q
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