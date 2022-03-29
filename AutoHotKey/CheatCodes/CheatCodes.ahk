; ^hotkey::
; ::hotstring::
;---------------------------
;-- Key / Symbol Mappings --
;--------------------------- 
; # = [Win]
; ! = [Alt]
; ^ = [Ctrl]
; + = [Shift]
; * = Wildcard - Fire the hotkey even if extra modifiers are being held down. This is often used in conjunction with remapping keys or buttons.
; ~ = 
; $ = 
; UP = 
; < = Use the left key of the pair. e.g. <!a is the same as !a except that only the left Alt will trigger it.
; > = Use the right key of the pair.
; & = An ampersand may be used between any two keys or mouse buttons to combine them into a custom hotkey.
; - - - - - - - - - - - - - 
; More at https://www.autohotkey.com/docs/Hotkeys.htm
;---------------------------

; #--> Custom Keyboard Shortcuts: Application
; PrintScreen to open Snipping Tool 
PrintScreen::Run explorer.exe ms-screenclip:

; Ctrl + Alt + P to open administrative Powershell
^!p::Run *runas "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"

; Ctrl + Alt + C to open administrative CMD
^!c::Run *runas "C:\windows\system32\cmd.exe"

; Ctrl + Alt + T to open administrative BASH shell (requires Git-Bash install)
^!t::Run *runas "C:\Program Files\Git\git-bash.exe"

; #--> Custom Keyboard Shortcuts: Saved Strings
; - Email Addresses [e]-
; Alt + e = Email address
!e::Send, <USERNAME>@<DOMAIN>.com
; Alt + Shift + e = Admin email address
!+e::Send, <ADMIN_USERNAME>@<DOMAIN>.com
