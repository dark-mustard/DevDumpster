@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

SET "OSType=null"
SET "OSVer=null"

CALL :GetWMIValue "OS" "ProductType" OSType
REM	ECHO !OSType!
	
CALL :GetWMIValue "OS" "Caption" OSName
REM	ECHO !OSName!

CALL :GetWMIValue "OS" "Version" OSVer
REM	ECHO !OSVer!
REM	ECHO !OSVer:~0,3!
REM	ECHO !OSVer:~0,4!

IF "!OSType!"=="1" (
REM	ECHO Desktop
	IF "!OSVer:~0,4!"=="10.0" ( 
		ECHO Win10
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.3" ( 
		ECHO Win8.1
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.2" ( 
		ECHO Win8 
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.1" ( 
		ECHO Win7 
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.0" ( 
		ECHO Vista 
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="5.1" ( 
		ECHO WinXP 
		GOTO TypeIsSet
	)
) ELSE (
REM	ECHO Server
	IF "!OSVer:~0,3!"=="6.3" ( 
		ECHO Srv2012R2
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.2" ( 
		ECHO Srv2012
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.1" ( 
		ECHO Srv2008R2
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="6.0" ( 
		ECHO Srv2008
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,5!"=="5.2.3" ( 
		ECHO Srv2003R2
		GOTO TypeIsSet
	)
	IF "!OSVer:~0,3!"=="5.2" ( 
		ECHO Srv2003 
		GOTO TypeIsSet
	)
)
:TypeIsSet

ENDLOCAL
pause
EXIT /b



:GetWMIValue <class> <property> <value>
(
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET "class=%~1"
	SET "prop=%~2"
REM		ECHO test !class!
REM		ECHO test !prop!
	SET "cmd=wmic !class! get !prop!"
REM		ECHO '!cmd!'

	SET "val=null"

	FOR /F "skip=1" %%a IN ('"!cmd!"') DO (
		FOR /F "delims=" %%b IN ("%%a") DO (
			SET "val=%%b"
			SET "val=!val: =!"
		)
	)
REM 	ECHO !val!
)
(
	ENDLOCAL
	SET %3=%val%
	EXIT /b
)
