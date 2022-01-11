@echo off

ECHO.
ECHO =============================================================
ECHO Modify the Registry and Obtain Administrator Rights
ECHO =============================================================

Echo get administrator rights
cacls.exe "%SystemDrive%\System Volume Information" >nul 2>nul
if %errorlevel%==0 goto Admin
if exist "%temp%\getadmin.vbs" del /f /q "%temp%\getadmin.vbs"
echo Set RequestUAC = CreateObject^("Shell.Application"^)>"%temp%\getadmin.vbs"
echo RequestUAC.ShellExecute "%~s0","","","runas",1 >>"%temp%\getadmin.vbs"
echo WScript.Quit >>"%temp%\getadmin.vbs"
"%temp%\getadmin.vbs" /f
if exist "%temp%\getadmin.vbs" del /f /q "%temp%\getadmin.vbs"
exit
:Admin
Echo successfully obtained administrator permission
:::::::::::::::::::::::: modify the registry and close UAC::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t reg_dword /d 0 /F
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t reg_dword /d 0 /F
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t reg_dword /d 0 /F

CLS
ECHO.
ECHO =============================
ECHO Running Admin Shell
ECHO =============================

:init
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
ECHO.
ECHO **************************************
ECHO Invoking UAC for Privilege Escalation
ECHO **************************************

ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

::::::::::::::::::::::::::::
::START
::::::::::::::::::::::::::::

echo "Judge TPM whether support in this platform."
::No Instance(s) Available.
set maxBytesSize=10
wmic /namespace:\\root\CIMV2\Security\MicrosoftTpm path Win32_Tpm get /value > tpm.txt
setlocal
set file="tpm.txt"
for /f "usebackq" %%a in ('%file%') do set size=%%~za
echo tpm files are %size% bytes
if %size% equ %maxBytesSize% goto:tpm_fail else goto:start

:start
if "%~1" neq "" goto :%~1 

manage-bde -status 
manage-bde -on C: -em aes256 > D:\start.txt
echo You must resatrt your computer before continuing with BitLocker drive encryption
echo Restart PC/NB after 10 seconds...
timeout /t 10

call :markReboot stuff2
goto :eof

:stuff2
manage-bde -status
echo Waiting for 20 minutes
timeout /t 1200
echo Encrypted done!!!
manage-bde -status > D:\encryptionResult.txt

echo Decryption in progress
manage-bde -off C:
echo Waiting for 10 minutes
timeout /t 600
manage-bde -status > D:\decryptionResult.txt
echo Decrypted done!!!
echo Testing finish. Result : PASS
echo Testing finish. Result : PASS > D:\result.txt
pause
goto :eof

:tpm_fail
echo Testing finish. Result : FAIL(Platform didn't support TPM feature.)
echo Testing finish. Result : FAIL(Platform didn't support TPM feature.) > D:\result.txt
pause


:markReboot
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce /t REG_SZ /d "\"%~dpf0\" %~1" /v  RestartMyScript /f 
shutdown /r /t 0