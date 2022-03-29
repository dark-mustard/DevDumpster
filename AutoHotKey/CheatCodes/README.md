# CheatCodes
Script sets up following shortcuts:

| Key Bind        | Notes                                        | Additional Requirements                            |
|-----------------|----------------------------------------------|----------------------------------------------------|
| PrintScreen     | Launches selective capture w/ Snipping Tool  |                                                    |
| Ctrl + Alt + P  | Opens elevated PowerShell window             |                                                    |
| Ctrl + Alt + C  | Opens elevated CMD window                    |                                                    |
| Ctrl + Alt + T  | Opens elevated GitBash window                | Install Git-Bash for Windows, uncomment rule.      |
| Alt + e         | Types out provided %EMAIL_ADDRESS%           | Replace %EMAIL_ADDRESS%                            |
| Alt + Shift + e | Types out provided %ALTERNATE_EMAIL_ADDRESS% | Replace %ALTERNATE_EMAIL_ADDRESS%, uncomment rule. |

# Setup
1. Install Pre Requisites
   - AutoHotKey
   - Any additional KeyBind-specific PreReqs in table above
2. Download `CheatCodes.ahk` and `ActivateCheatCodes.bat` to a local directory of your choice 
   - Example:  `C:\ProgramData\_Customizations\CheatCodes.ahk`
3. Customize `CheatCodes.ahk`
   - Replace following variables (if using)
      | Variable                  | Key Bind        | Notes                     |
      |---------------------------|-----------------|---------------------------|
      | %EMAIL_ADDRESS%           | Alt + e         |                           |
      | %ALTERNATE_EMAIL_ADDRESS% | Alt + Shift + e | Only if enabled manually. |
   - Customize desired key binds 
     - Any line beginning with a `;` is considered a comment and will not be processed
     - Some included options are commented out by default
   - Save changes
4. Create Scheduled Task
   - Create a new basic Scheduled Task
      | Setting        | Value                                                     |
      |----------------|-----------------------------------------------------------|
      | Trigger        | `At log on of %USERNAME%`                                 |
      | Action         | `Start a program`                                         |
      | Program/script | `"C:\ProgramData\_Customizations\ActivateCheatCodes.bat"` |
5. Log off / log back on and test
