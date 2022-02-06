@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

REM "/Datatel.Core.Crm.Services"
REM "/PaymentResponseService.svc"
REM "#Date: 2017-01-01 06:00:01"
SET /P searchString=[SearchString]:


SET log1="%~dp0Results.txt"
SET log2="%~dp0Log.txt"

SET LogDir="C:\inetpub\logs\LogFiles\W3SVC"
REM SET LogDir="C:\Users\gphillipssa\Desktop\IIS LOGS"

cd %LogDir%

SET "resultsFound=false"

ECHO *Search started: %date% %time%>%log2%
(
	ECHO   ^|-Search String: %searchString%
	ECHO   ^|-Results File:  %log1%
	ECHO   ^|-Files
) %1>>%log2% %2>>%log2%

for /r %%a in (u_ex*.log) DO (
	CLS
	ECHO Searching file:  %%a

	ECHO   ^|  ^|-File:  %%a>>%log2%

	SET "containsRef=false"
	FOR /F "delims=" %%b in ('"FINDSTR /C:"%searchString%" %%a"') DO (
		SET "containsRef=true"
		SET "resultsFound=true"
		ECHO   ^|  ^|  ^|-%%b>>%log2%
	)

	REM ECHO !resultsFound!>>%log2%
	REM ECHO !containsRef!>>%log2%

	if "!containsRef!"=="true" (
		ECHO %%a
	) %1 >> %log1% %2 >> %log1%

) 
CLS
ECHO Search Completed:  %date% %time%
ECHO   ^|-Search complete!>>%log2%
ECHO   ^\>>%log2%

:PromptViewLog
ECHO View log file?
:SetViewLog
SET /P viewLog=[y/n]:
if "%viewLog%"=="n" GOTO PromptViewResults
if "%viewLog%"=="N" GOTO PromptViewResults
if "%viewLog%"=="y" GOTO ViewLog
if "%viewLog%"=="Y" GOTO ViewLog
ECHO ^[ERROR!^] Invalid input...please try again.
GOTO SetViewLog

:ViewLog
notepad %log1%


:PromptViewResults
if "!resultsFound!"=="true" (
	ECHO View results file?
) else (
	GOTO End
)
:SetViewResults
SET /P viewResults=[y/n]:
if "%viewResults%"=="n" GOTO End
if "%viewResults%"=="N" GOTO End
if "%viewResults%"=="y" GOTO ViewResults
if "%viewResults%"=="Y" GOTO ViewResults
ECHO ^[ERROR!^] Invalid input...please try again.
GOTO SetViewResults

:ViewResults
notepad %log2%


:End
ENDLOCAL
pause
exit /b