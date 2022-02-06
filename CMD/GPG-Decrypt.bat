@ECHO OFF
cd /d "%~dp0"
gpg -d --output %2 %1