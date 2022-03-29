@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
pushd "%~dp0"
START "CUSTOM - AHK CheatCodes" "%programfiles%\AutoHotkey\AutoHotkey.exe" CheatCodes.ahk
popd
ENDLOCAL
EXIT /B