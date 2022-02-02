function Get-AppInfo {
    <#
        .SYNOPSIS
        Returns list of installed applications.

        .DESCRIPTION
        Returns list of installed applications from the current computer.
        It attempts various methods of doing so if  using the following priority:
            1) Registry

        .PARAMETER FilterBy_AppName
        Name or partial name of an applicatoin to filter the results.  
        Fields evaluated:
            1) DisplayName
            2) Registry Key Name (if not a Guid)

        *Not case sensitive*

        Example: "vpn"

        .PARAMETER FilterBy_AppVendor
        Name or partial name of a vendor to filter the results.  
        Fields evaluated:
            1) Publisher
            2) Contact

        *Not case sensitive*
        Example: "Microsoft"

        .PARAMETER OutFile
        CSV file path to save results.
        Example: "C:\AppList.csv"

        .PARAMETER AppSource
        Where to get the list of applications from
        Accepted Values: "REG", "WMI"

        .INPUTS
        None. You cannot pipe objects to Get-AppInfo.

        .OUTPUTS
        [PSCustomObject[]]. Get-AppInfo returns an array of Applications with various properties.

        .EXAMPLE
        PS> Get-AppInfo
        Returns full list of applications.

        .EXAMPLE
        PS> Get-AppInfo -FilterBy_AppVendor "Microsoft"
        Returns list of applications from vendors whose name contains "*microsoft*".
        
        .EXAMPLE
        PS> Get-AppInfo -FilterBy_AppName "vpn"
        Returns list of applications whose name contains "*vpn*".
        
        .EXAMPLE
        PS> Get-AppInfo -OutFile "C:\TestFile.csv"
        Saves results to a CSV file at the specified location on the file system.
    #>
    param(
        [String]
            $FilterBy_AppName   = $null, 
        [String]
            $FilterBy_AppVendor = $null,
        [String]
            $OutFile            = $null,
        [String]
        [ValidateSet("Registry", "WMI")]
            $AppSource          = "Registry"
    )
    BEGIN{
        #region Custom Functions
            enum LogMessageLevel{
                Verbose = 0
                Debug = 1
                Information = 2
                Warning = 3
                Error = 4
            }
            function LogMessage {
                param(
                    [String]$Message,
                    [String]$MessagePrefixAddition = $null,
                    [LogMessageLevel]$LogMessageLevel = ([LogMessageLevel]::Information),
                    [Nullable[ConsoleColor]]$MessageColor = $null
                )
                $DisplayMessage = $false
                switch($LogMessageLevel){
                    ([LogMessageLevel]::Debug){
                        if($DebugPreference -eq "Continue"){
                            $DisplayMessage = $true
                        }
                    }
                    ([LogMessageLevel]::Verbose){
                        if($VerbosePreference -eq "Continue"){
                            $DisplayMessage = $true
                        }
                    }
                    Default{
                        $DisplayMessage = $true
                    }
                }
                if($true -eq $DisplayMessage){
                    $DICT_LogMessageLevelStrings=@{
                        ([LogMessageLevel]::Verbose)     = "VERBOSE"
                        ([LogMessageLevel]::Debug)       = "DEBUG"
                        ([LogMessageLevel]::Information) = "INFO"
                        ([LogMessageLevel]::Warning)     = "WARNING"
                        ([LogMessageLevel]::Error)       = "ERROR"
                    }
                    [Nullable[ConsoleColor]]$DelimColor = [ConsoleColor]::Gray
                    [Nullable[ConsoleColor]]$DefaultColor = $null
                    [Nullable[ConsoleColor]]$DefaultColor_Debug = ([ConsoleColor]::Cyan)
                    [Nullable[ConsoleColor]]$DefaultColor_Verbose = ([ConsoleColor]::DarkCyan)
                    $DICT_MessageAdditionalPrefixColors=@{
                        ([LogMessageLevel]::Verbose)     = $DefaultColor_Verbose
                        ([LogMessageLevel]::Debug)       = $DefaultColor_Debug
                        ([LogMessageLevel]::Information) = $DefaultColor
                        ([LogMessageLevel]::Warning)     = $DefaultColor
                        ([LogMessageLevel]::Error)       = $DefaultColor
                    }
                    $DICT_LogMessageLevelColors=@{
                        ([LogMessageLevel]::Verbose)     = $DefaultColor_Verbose
                        ([LogMessageLevel]::Debug)       = $DefaultColor_Debug
                        #([LogMessageLevel]::Information) = $(if($null -ne $MessageColor) { $MessageColor } else { $DefaultColor })
                        ([LogMessageLevel]::Information) = $DefaultColor
                        ([LogMessageLevel]::Warning)     = ([ConsoleColor]::Yellow)
                        ([LogMessageLevel]::Error)       = ([ConsoleColor]::DarkRed)
                    }
                    [Nullable[ConsoleColor]]$LogMessageLevelColor=$DICT_LogMessageLevelColors[$LogMessageLevel]
                    $MessageElements=[Ordered]@{}
                    $MessageColor = if($null -ne $MessageColor) { $MessageColor } else { $LogMessageLevelColor }
                    $MessagePrefix = "$((Get-Date).ToString('yyyy-MM-dd hh:mm:ss')) | "
                        $MessageElements.Add($MessagePrefix, $DelimColor) 
                    $LogMessageLevelString = "$(('[{0}]' -f $DICT_LogMessageLevelStrings[$LogMessageLevel]).PadRight(9, ' '))"
                        $MessageElements.Add($LogMessageLevelString, $LogMessageLevelColor) 
                    $MessageElements.Add(" | ", $DelimColor) 
                    if($MessagePrefixAddition) {
                        $MessageElements.Add($MessagePrefixAddition, $DICT_MessageAdditionalPrefixColors[$LogMessageLevel])
                    }
                    $MessageElements.Add($Message, $MessageColor)
                    $MessageElements.Keys | %{
                        $Msg=$_
                        $MsgColor=$MessageElements[$Msg]
                        $CurrentItemIndex=@($MessageElements.Keys).IndexOf($Msg)
                        $TotalItemCount=@($MessageElements.Keys).Count
                        $NoNewLine=if($CurrentItemIndex -eq ($TotalItemCount - 1)){
                                $false
                            } else {
                                $true
                            }
                        if($null -eq $MsgColor) {
                            Write-Host $Msg -NoNewline:$NoNewLine
                        } else {
                            Write-Host $Msg -NoNewline:$NoNewLine -ForegroundColor $MsgColor
                        }
                    }
                }
            }
            function Get-EvalType{
                param([string]$FilterBy_AppName=$null, [string]$FilterBy_AppVendor=$null)
                $EvalType=0
                if(-Not [String]::IsNullOrWhiteSpace($FilterBy_AppName)){
                    $EvalType += 1
                }
                if(-Not [String]::IsNullOrWhiteSpace($FilterBy_AppVendor)){
                    $EvalType += 2
                }
                return $EvalType
            }
        #endregion

        #region Custom Expressions
            $FN_AppArchitecture = @{
                Label="AppArchitecture";
                Expression={
                    if(($_.PSParentPath.ToLower() -like "*wow6432node*") -or (![Environment]::Is64BitOperatingSystem) ) {
                        "x86"
                    } else {
                        "x64"
                    }
                }
            }
            $FN_AppGuid = @{
                Label="AppGuid";
                Expression={
                    $appGuid=$null
                    if($_.PSChildName){
                        if(($_.PSChildName.Length -ge 38) -and ($_.PSChildName -like '*{*-*-*-*-*}*')) {
                            #$_.PSChildName.Substring($_.PSChildName.IndexOf("{"), 38)
                            $appGuid=$_.PSChildName.Substring($_.PSChildName.IndexOf("{") + 1, 36)
                        } elseif(($_.PSChildName.Length -eq 36) -and ($_.PSChildName -like '*-*-*-*-*')){
                            $appGuid=$_.PSChildName
                        } 
                    } 
                    if($null -eq $appGuid){
                        $appGuid=$_.GetValue("ProductGuid", $null)
                    }
                    if($null -eq $appGuid){
                        $RegexMatchString="\{[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}\}"
                        $installSource=$_.GetValue("InstallSource", $null)
                        $modifyPath=$_.GetValue("ModifyPath", $null)
                        $uninstallString=$_.GetValue("UninstallString", $null)
                        $quietUninstallString=$_.GetValue("QuietUninstallString", $null)
                        if($null -ne $uninstallString -and $uninstallString -match $RegexMatchString){
                            $appGuid=$Matches[0].TrimStart("{").TrimEnd("}")
                            #$appGuid=$uninstallString.Substring($uninstallString.IndexOf("{") + 1, 36)
                        }elseif($null -ne $quietUninstallString -and $quietUninstallString -match $RegexMatchString) {
                            $appGuid=$Matches[0].TrimStart("{").TrimEnd("}")
                            #$appGuid=$installSource.Substring($installSource.IndexOf("{") + 1, 36)
                        }elseif($null -ne $installSource -and $installSource -match $RegexMatchString) {
                            $appGuid=$Matches[0].TrimStart("{").TrimEnd("}")
                            #$appGuid=$installSource.Substring($installSource.IndexOf("{") + 1, 36)
                        } elseif($null -ne $modifyPath -and $modifyPath -match $RegexMatchString){
                            $appGuid=$Matches[0].TrimStart("{").TrimEnd("}")
                            #$appGuid=$modifyPath.Substring($modifyPath.IndexOf("{") + 1, 36)
                        }
                    }
                    $appGuid
                }
            }
            $FN_AppNameValues = @{
                Label="AppName";
                Expression={
                    $appName=$_.GetValue("DisplayName", $null)
                    if($null -eq $appName){
                        $RegexMatchString="^(\{|)[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}(\}|)$"
                        if((-Not [String]::IsNullOrWhiteSpace($_.PSChildName)) -and ($_.PSChildName -notmatch $RegexMatchString)){
                            $appName=$_.PSChildName
                        }
                    }
                    $appName
                }
            }
            $FN_AppName = @{
                Label="AppName";
                Expression={
                    $appName=$_.GetValue("DisplayName", $null)
                    if($null -eq $appName){
                        $RegexMatchString="^(\{|)[0-9a-zA-Z]{8}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{4}-[0-9a-zA-Z]{12}(\}|)$"
                        if((-Not [String]::IsNullOrWhiteSpace($_.PSChildName)) -and ($_.PSChildName -notmatch $RegexMatchString)){
                            $appName=$_.PSChildName
                        }
                    }
                    $appName
                }
            }
            $FN_AppVendor = @{
                Label="AppVendor";
                Expression={
                    $vendor = $null
                    $publisher=$_.GetValue("Publisher", $null)
                    $contact=$_.GetValue("Contact", $null)
                    if($null -ne $publisher){
                        $vendor=$publisher
                    } elseif(
                        $null -ne $contact -and
                        $contact -notlike '*://*' -and
                        $contact -notlike '*@*'
                    ){
                        $vendor = $contact.Replace("Support", "").Replace("Customer", "").Trim()
                    }
                    $vendor
                }
            }
        #endregion
        
        #region Logging...
            LogMessage -MessagePrefixAddition "*"      -Message "Get-AppInfo"
            LogMessage -MessagePrefixAddition " |-"    -Message "Params:"                                     -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  |-" -Message "[FilterBy_AppName] $($FilterBy_AppName)"     -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  |-" -Message "[FilterBy_AppVendor] $($FilterBy_AppVendor)" -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  |-" -Message "[OutFile] $($OutFile)"                       -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  |-" -Message "[AppSource] $($AppSource)"                   -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  "   -Message "\"                                           -LogMessageLevel Debug
        #endregion
        
        #region Initialize Variables
            $PropList=@(
                'DisplayName'
                #---
                'DisplayVersion'
                'Version'
                'VersionMajor'
                'VersionMinor'
                #---
                'Publisher'
                'Contact'
                #---
                'URLInfoAbout'
                'URLUpdateInfo'
                'HelpLink'
                'Comments'
                'Readme'
                'HelpTelephone'
                #---
                'InstallDate'
                'InstallLocation'
                'InstallSource'
                'ModifyPath'
                'WindowsInstaller'
                'UninstallString'
                'QuietUninstallString'
                #---
                #'SystemComponent'
                'Language'
                'AuthorizedCDFPrefix'
                'Size'
                'EstimatedSize'
            )
            $RegKeyRelativePaths = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
            $EvalType    = Get-EvalType -FilterBy_AppName $FilterBy_AppName -FilterBy_AppVendor $FilterBy_AppVendor
            $ReturnValue = @()
        #endregion
    }
    PROCESS{
        #region Initialize Variables
            $AppList=@()
            $EvalIndex=0
        #endregion

        #region Logging...
            LogMessage -MessagePrefixAddition " |-"    -Message "Process:"              -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  |-" -Message "[Eval Type] $EvalType" -LogMessageLevel Debug
            LogMessage -MessagePrefixAddition " |  |-" -Message "Item List:"            -LogMessageLevel Verbose
        #endregion

        switch($AppSource){
            ('Registry'){
                #region Get App Data from REGISTRY
                    #$RegKeyRelativePaths | Get-ChildItem | Get-Item | Where { ($null -eq $_.GetValue("CorrespondingDevice", $null)) -and ($_.GetValue("SystemComponent", 0) -eq 0) -and ($_.ValueCount -gt 5) }
                    $RegKeyRelativePaths | Get-ChildItem | Select-Object $FN_AppArchitecture, $FN_AppGuid, $FN_AppName, $FN_AppVendor, * | ForEach-Object{
                        $RegKey=Get-Item -Path $_.PSPath 
                        
                        if(($null -eq $RegKey.GetValue("CorrespondingDevice", $null)) -and ($RegKey.GetValue("SystemComponent", 0) -eq 0) -and ($RegKey.ValueCount -gt 5) ){
                            $AppInfo=[PSCustomObject] @{
                                RegKeyPath      = ($_.PSPath)
                                RegKeyParent    = $(Split-Path $_.PSPath)
                                RegKeyName      = $(Split-Path $_.PSPath -Leaf)
                                PropertyCount   = $($RegKey.ValueCount)
                                AppGuid         = ($_.AppGuid)
                                AppName         = ($_.AppName)
                                AppVendor       = ($_.AppVendor)
                                AppArchitecture = ($_.AppArchitecture)
                            }
                            $PropList | ForEach-Object{
                                $Prop = $_
                                $AppInfo | Add-Member -MemberType NoteProperty -Name $Prop -Value $RegKey.GetValue($Prop, $null)
                            }
                            #region Logging...
                                LogMessage -MessagePrefixAddition " |  |  |-"       -Message "Item $($EvalIndex + 1):"                        -LogMessageLevel Verbose
                                LogMessage -MessagePrefixAddition " |  |  |  |-"    -Message "Properties:"                                    -LogMessageLevel Verbose
                                LogMessage -MessagePrefixAddition " |  |  |  |  |-" -Message "[App Name] $($AppInfo.AppName)"                 -LogMessageLevel Verbose
                                LogMessage -MessagePrefixAddition " |  |  |  |  |-" -Message "[App Vendor] $($AppInfo.AppVendor)"             -LogMessageLevel Verbose
                                LogMessage -MessagePrefixAddition " |  |  |  |  |-" -Message "[App Architecture] $($AppInfo.AppArchitecture)" -LogMessageLevel Verbose
                                LogMessage -MessagePrefixAddition " |  |  |  |  |-" -Message "[App Guid] $($AppInfo.AppGuid)"                 -LogMessageLevel Verbose
                                LogMessage -MessagePrefixAddition " |  |  |  |  "   -Message "\"                                              -LogMessageLevel Verbose
                            #endregion 
                            $AddToList=$false
                            $EvalLogMessage=$null
                            switch ($EvalType) {
                                # (none)
                                (0) {
                                    $AddToList=$true
                                }
                                # [AppName]
                                (1) {                
                                    if($AppInfo.DisplayName -like "*$FilterBy_AppName*"){
                                        $EvalLogMessage="[$($AppInfo.DisplayName)] LIKE [*$($FilterBy_AppName)*]"
                                        $AddToList=$true
                                    } else {
                                        $EvalLogMessage="[$($AppInfo.DisplayName)] NOT LIKE [*$($FilterBy_AppName)*]"
                                    }
                                }
                                # [AppVendor]
                                (2) {           
                                    if($AppInfo.AppVendor -like "*$FilterBy_AppVendor*"){
                                        $EvalLogMessage="[$($AppInfo.AppVendor)] LIKE [*$($FilterBy_AppVendor)*]"
                                        $AddToList=$true
                                    } else {
                                        $EvalLogMessage="[$($AppInfo.AppVendor)] NOT LIKE [*$($FilterBy_AppVendor)*]"
                                    }
                                }
                                # [AppName] + [AppVendor]
                                (3) {             
                                    if($AppInfo.DisplayName -like "*$FilterBy_AppName*" -and
                                    $AppInfo.AppVendor -like "*$FilterBy_AppVendor*"){
                                        $EvalLogMessage="[$($AppInfo.DisplayName)] LIKE [*$($FilterBy_AppName)*] AND [$($AppInfo.AppVendor)] LIKE [*$($FilterBy_AppVendor)*]"
                                        $AddToList=$true
                                    } else {
                                        $EvalLogMessage="[$($AppInfo.DisplayName)] NOT LIKE [*$($FilterBy_AppName)*] OR [$($AppInfo.AppVendor)] NOT LIKE [*$($FilterBy_AppVendor)*]"
                                    }
                                }
                                Default {
                                    throw "Invalid evaluation type. [$($script:EvalType)]"
                                }
                            }
                            if(-Not [String]::IsNullOrWhiteSpace($EvalLogMessage)){
                                LogMessage -MessagePrefixAddition " |  |  |  |-" -Message "Evaluation:" -LogMessageLevel Verbose 
                            }
                            if($true -eq $AddToList){
                                if(-Not [String]::IsNullOrWhiteSpace($EvalLogMessage)){
                                    #LogMessage -MessagePrefixAddition " |  |  |  |-Evaluation: " -Message "$EvalLogMessage" -LogMessageLevel Debug  -MessageColor Green
                                    LogMessage -MessagePrefixAddition " |  |  |  |  |-" -Message $EvalLogMessage -LogMessageLevel Verbose -MessageColor Green
                                }
                                $AppList+=,($AppInfo)
                            } else {
                                if(-Not [String]::IsNullOrWhiteSpace($EvalLogMessage)){
                                    #LogMessage -MessagePrefixAddition " |  |  |  |-Evaluation: " -Message "$EvalLogMessage" -LogMessageLevel Debug  -MessageColor Red
                                    LogMessage -MessagePrefixAddition " |  |  |  |  |-" -Message $EvalLogMessage -LogMessageLevel Verbose -MessageColor Red
                                }
                            }
                            if(-Not [String]::IsNullOrWhiteSpace($EvalLogMessage)){
                                LogMessage -MessagePrefixAddition " |  |  |  |  " -Message "\" -LogMessageLevel Verbose
                            }
                            LogMessage -MessagePrefixAddition " |  |  |  |-" -Message "[AddToList] $($AddToList)" -LogMessageLevel Verbose
                            LogMessage -MessagePrefixAddition " |  |  |  " -Message "\" -LogMessageLevel Verbose

                            $EvalIndex += 1
                        }
                    }
                #endregion
                #region Logging...
                    LogMessage -MessagePrefixAddition " |  |  " -Message "\" -LogMessageLevel Verbose
                    LogMessage -MessagePrefixAddition " |   " -Message "\" -LogMessageLevel Verbose
                    LogMessage -MessagePrefixAddition " |-" -Message "Result Count: $($AppList.Count)" -LogMessageLevel Debug
                #endregion 
            }
            ('WMI'){
                throw "NOT IMPLEMENTED"
                #region Get App Data from WMI
                #endregion
            }
            default{
                throw "Invalid [AppSource] encountered `{ 'AppSource':'$AppSource' `}"
            }
        }

        $AppList = @($AppList | Sort-Object -Property AppVendor,AppName,DisplayVersion,AppGuid)

        if(-Not [String]::IsNullOrWhiteSpace($OutFile)){
            $AppList | Select-Object * | Export-CSV $OutFile -NoClobber -NoTypeInformation -Force:$true -Append:$false -Confirm:$false

            if(Test-Path($OutFile)){
                LogMessage -MessagePrefixAddition " |-" -Message "Results exported successfullty. [$OutFile]" -LogMessageLevel Debug -MessageColor Green
                LogMessage -MessagePrefixAddition " "   -Message "\"                                          -LogMessageLevel Debug
                $ReturnValue+=,($OutFile)
            } else {
                LogMessage -MessagePrefixAddition " |-" -Message "Failed to export results. [$OutFile]"       -LogMessageLevel Debug -MessageColor Red
                LogMessage -MessagePrefixAddition " "   -Message "\"                                          -LogMessageLevel Debug
                return $null
            }
        } else {
            LogMessage -MessagePrefixAddition " " -Message "\" -LogMessageLevel Debug
            $ReturnValue+=,@($AppList)
        }
    }
    END{
        return @($ReturnValue)
    }
}