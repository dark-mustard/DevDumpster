@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

cd /d "%~dp0"

SET "vbScript=GetPassword.vbs"
SET "psScript=GetPassword.ps1"

SET /p "User=Username: [DEFAULT=CCU_NET\gphillipssa] "
IF "!User!" == "" ( SET "User=CCU_NET\gphillipssa")

CALL :ToLower User

IF NOT "!User:~0,8!"=="ccu_net\" ( SET "User=CCU_NET\!User!" )

REM ECHO --------
REM   ECHO %User:~8%
REM   ECHO %User:~0,8%
REM   ECHO %User%
REM   ECHO !User:~8!
REM   ECHO !User:~0,8!
REM   ECHO !User!
REM ECHO --------

ECHO    //-------------------
ECHO    // Username = !User!
ECHO    //-------------------
ECHO.

<nul: set /p password=Enter password
REM #####
REM ## Windows XP / Server 2003 ONLY
REM #####
REM > !vbScript! (
REM	ECHO Set oScriptPW = CreateObject^(^"ScriptPW.Password^"^)
REM	ECHO strPassword = oScriptPW.GetPassword^(^)
REM	ECHO Wscript.StdOut.WriteLine strPassword
REM )
REM for /f "delims=" %%A in ('cscript /nologo GetPassword.vbs') do set "password=%%A"
REM DEL /Q %vbScript%

REM #####
REM ## >= Windows 7 / >= Server 2008
REM #####
> !psScript! (
REM 	ECHO ^$password = Read-Host "Enter password" -AsSecureString
	ECHO ^$password = Read-Host ":" -AsSecureString
	ECHO ^$password = ^[Runtime.InteropServices.Marshal^]^:^:SecureStringToBSTR^(^$password^)
	ECHO ^$password = ^[Runtime.InteropServices.Marshal^]^:^:PtrToStringAuto^(^$password^)
	ECHO echo ^$password
)

for /f "delims=" %%A in ('powershell -file !psScript!') do set "password=%%A"
DEL /Q !psScript!


REM ####
REM ## ADD CREDENTIALS
REM ####
ECHO    //-------------------
ECHO    // ^*Setting credentials for the following servers:
FOR /F "tokens=1,2 delims= " %%B in (SAServers.txt) DO (
	REM ECHO ^[%%B^] - ^[%%C^]
	
	IF [%%C] == [] (ECHO ^*Server:  %%B) ELSE ( ECHO    //   ^|-%%B ^/ %%C )
	
	(
		cmdkey /delete:%%B
		cmdkey /add:%%B /user:!User! /password:!password!
	) >nul 2>&1
)
ECHO    //   ^\
ECHO    // ^[Process complete^]
ECHO    //-------------------
ECHO.


SET /P "ListKeys=List current credentials? (y/n) [DEFAULT=y]:"
IF [!ListKeys!]==[y] (cmdkey /list) 

ENDLOCAL
pause
EXIT /B

:ToLower <string>
(
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET "text=!%~1!"
	
	SET "text=!text:A=a!"
	SET "text=!text:B=b!"
	SET "text=!text:C=c!"
	SET "text=!text:D=d!"
	SET "text=!text:E=e!"
	SET "text=!text:F=f!"
	SET "text=!text:G=g!"
	SET "text=!text:H=h!"
	SET "text=!text:I=i!"
	SET "text=!text:J=j!"
	SET "text=!text:K=k!"
	SET "text=!text:L=l!"
	SET "text=!text:M=m!"
	SET "text=!text:N=n!"
	SET "text=!text:O=o!"
	SET "text=!text:P=p!"
	SET "text=!text:Q=q!"
	SET "text=!text:R=r!"
	SET "text=!text:S=s!"
	SET "text=!text:T=t!"
	SET "text=!text:U=u!"
	SET "text=!text:V=v!"
	SET "text=!text:W=w!"
	SET "text=!text:X=x!"
	SET "text=!text:Y=y!"
	SET "text=!text:Z=z!"
)
(
	ENDLOCAL
	SET %1=%text%
	exit /b
)