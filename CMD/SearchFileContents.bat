@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

cd /d "%~dp0"

SET log1="%~dp0Results.txt"
SET log2="%~dp0Log.txt"
SET "FoundItems="

:NewDir
SET /P root=[Root directory to perform search]:
:NewSearchString
SET /P searchString=[Text to search for]:

REM cd /d "%root%"
pushd "%root%"

SET "resultsFound=false"

ECHO *Search started: %date% %time%>%log2%
(
	ECHO   ^|-Search String: %searchString%
	ECHO   ^|-Results File:  %log1%
	ECHO   ^|-Files
) %1>>%log2% %2>>%log2%

for /r %%a in (*) DO (
	CLS
	ECHO Searching file:  %%a
	ECHO !resultsFound!
	ECHO   ^|  ^|-File:  %%a>>%log2%

	SET "containsRef=false"
	FOR /F "delims=" %%b in ('"FINDSTR /C:"%searchString%" %%a"') DO (
		SET "result=%%b"
		SET "containsRef=true"
		SET "resultsFound=true"
		ECHO   ^|  ^|  ^|-%%b>>%log2%
		SET "FoundItems=!FoundItems!!result!^"
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

popd

:PromptNewRun
ECHO Try again?
ECHO   ^* [1] - Yes - Use same root folder.
ECHO   ^* [2] - Yes - Change the root folder.
ECHO   ^* [3] - No.
:SetNewRun
SET /P runAgain=[Default=3]:
if "%runAgain%"=="1" GOTO NewSearchString
if "%runAgain%"=="2" GOTO NewDir
if "%runAgain%"=="3" GOTO PromptViewLog
ECHO ****** Invalid option selected. ******
GOTO SetNewRun

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
call notepad "%log1%"


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
call notepad "%log2%"


:End
ENDLOCAL
pause
exit /b
