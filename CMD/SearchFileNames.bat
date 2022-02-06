@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION						   

cd /d "%~dp0"

SET "resultsDir=%~dp0_SearchResults\"
CALL :CheckFolder resultsDir

SET "dtString=null"
CALL :GetDateTimeString dtString

SET log1="!resultsDir!Results_FileNames_!dtString!.txt"
SET log2="!resultsDir!Log_FileNames_!dtString!.txt"					   
(
	REM IF EXIST %log1% DEL %log1%
	IF EXIST %log2% DEL %log2%
) >nul 2>&1

:NewDir
SET /P root=[Root directory to perform search]:
:NewFileName
SET /P partialFileName=[Partial file name to search for (including * as wildcard)]:

SET "root=!root:/=\!"
if "!root:~-1!" neq "\" SET "root=!root!\"1
SET "partialFileName=!partialFileName:/=\!"
SET "resultsFound=false"
ECHO *Search started: %date% %time%>%log2%
(
	ECHO   ^|-Root Directory:  %root%
	ECHO   ^|-Search String:   !partialFileName!
	ECHO   ^|-Results File:    %log1%
) %1>>%log2% %2>>%log2%

CLS
ECHO Searching for "!partialFileName!" in "%root%"...
ECHO Searching for "!partialFileName!" in "%root%"...>>%log1%
SET /a "resultCount=0"
SET cmd="dir /s /l /b /c /x /a-d "%root%" | findstr /i "!partialFileName!" "
(
	ECHO   ^|-Command Text:    %cmd%
	ECHO   ^|-Files
) %1>>%log2% %2>>%log2%
for /f %%a in (' %cmd% ') DO (
	SET "resultsFound=true"
	SET /a "resultCount=!resultCount! + 1"
	ECHO   ^+ Found file^:  %%a
	ECHO   ^|  ^|-Found file^:  %%a>> %log1%
) 

ECHO ---^> Search complete!  
ECHO ---^> Search complete! >> %log1%
if "!resultCount!"=="1" (
	ECHO -- !resultCount! file found!
	ECHO -- !resultCount! file found! >> %log1%
) ELSE (
	ECHO -- !resultCount! files found!
	ECHO -- !resultCount! files found! >> %log1%
)
ECHO ----
ECHO ---- >> %log1%
ECHO. 
ECHO. >> %log1%

:PromptNewRun
ECHO Try again?
ECHO   ^* [1] - Yes - Use same root folder.
ECHO   ^* [2] - Yes - Change the root folder.
ECHO   ^* [q] - No  - Close the program.
:SetNewRun	
SET runAgain=q
SET /P runAgain=[Default=q]:
if "%runAgain%"=="1" GOTO NewFileName
if "%runAgain%"=="2" GOTO NewDir
if "%runAgain%"=="q" GOTO Cleanup
ECHO ****** Invalid option selected. ******
GOTO PromptNewRun


:Cleanup	
ENDLOCAL
exit /b


:GetDateString <returnStr>
(
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET "dateStr=!date:/=.!"
	SET "yStr=!dateStr:~10!"
	SET "mStr=!dateStr:~7,2!"
	SET "dStr=!dateStr:~4,2!"
	SET "newDateStr=!yStr!.!mStr!.!dStr!"
)
(
	ENDLOCAL
	SET "%~1=%newDateStr%"
	exit /b
)
:GetTimeString <returnStr>
(
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET "timeStr=!time::=.!"
	SET "newTimeStr=!timeStr:~0,8!"
	IF "!newTimeStr:~0,1!" == " " SET "newTimeStr=0!newTimeStr:~1!
)
(
	ENDLOCAL
	SET "%~1=%newTimeStr%"
	exit /b
)
:GetDateTimeString <returnStr>
(
	SETLOCAL ENABLEDELAYEDEXPANSION
	call :GetDateString dateStr
	call :GetTimeString timeStr
	SET "dateTimeStr=!dateStr!-!timeStr!"
)
(
	ENDLOCAL
	SET "%~1=%dateTimeStr%"
	exit /b
)
:CheckFolder <folder>
(
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET "folder=!%~1!"
	IF NOT EXIST "!folder!" MKDIR "!folder!"
)
(
	ENDLOCAL
	exit /b
)
