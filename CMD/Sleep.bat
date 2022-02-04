:Sleep <seconds>
(
    SETLOCAL ENABLEDELAYEDEXPANSION

    SET /a "seconds=!%~1!"
        ECHO ^{seconds^} --^> ^[!seconds!^]

    ping 127.0.0.1 -n !seconds! >nul 2>&1
)
(
    ENDLOCAL
    EXIT /B
)