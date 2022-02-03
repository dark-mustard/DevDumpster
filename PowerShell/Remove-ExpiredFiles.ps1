function Remove-ExpiredFiles{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName="MaxAge", Mandatory)]
        [Parameter(ParameterSetName="MaxVersionCount", Mandatory)]
        [String]
        [ValidateNotNullOrEmpty()]
            $Directory,
        [Parameter(ParameterSetName="MaxAge")]
        [Parameter(ParameterSetName="MaxVersionCount")]
        [String]
            $FilePattern,
        [Parameter(ParameterSetName="MaxVersionCount", Mandatory)]
        [Int]
        [ValidateRange(0, [Int]::MaxValue)]
            $MaxVersions,
        [Parameter(ParameterSetName="MaxAge", Mandatory)]
        [Int]
        [ValidateRange(0, [Int]::MaxValue)]
            $MaxAgeHours
    )
    BEGIN{
        $SelectFieldList = @( 
            "FullName"
            "Name"
            "CreationTime"
            "LastAccessTime"
            "LastWriteTime" 
        )
        $SortFieldList   = @(
            "CreationTime"
            "LastWriteTime"
            "LastAccessTime"
        )
        #-----------------------
        $SelectFields = @(if(($null -ne $SelectFieldList) -and ($SelectFieldList.Count -gt 0)){
                $SelectFieldList
            } else {
                "*"
            })
        $SortFields = @(if(($null -ne $SortFieldList) -and ($SortFieldList.Count -gt 0)){
                $SortFieldList
            } else {
                "*"
            })
        #---
        $ActionsTaken = @()
    }
    PROCESS{
        try{
            #----------
            # Get ALL matching files from the directory
            $Params_KeepFiles = @{
                Path = $Directory
            }
            if(-Not [String]::IsNullOrWhiteSpace($FilePattern)){
                $Params_KeepFiles.Add("Filter", $FilePattern)
            }
            $FullFileList = @(Get-ChildItem @Params_KeepFiles)
            #----------

            $KeepFiles   = @()
            $RemoveFiles = @()

            switch($PSCmdlet.ParameterSetName){
                ("MaxAge"){
                    $OldestValidWriteTime = (Get-Date).AddHours(-$MaxAgeHours)
                    $KeepFiles = @($FullFileList | Where-Object { $_.LastWriteTime -le $OldestValidWriteTime } | Sort-Object $SortFields -Descending)
                }
                ("MaxVersionCount"){
                    $KeepFiles = @($FullFileList | Sort-Object $SelectFields -Descending | Select-Object * -First $MaxVersions)
                }
                default{
                    throw ("Unhandled parameter set encountered. [{0}]" -f $PSCmdlet.ParameterSetName)
                }
            }

            $RemoveFiles = @($FullFileList | Where-Object { $_.FullName -notin $KeepFiles.FullName })

            $RemoveFiles | ForEach-Object{
                $FilePath = $_.FullName
                $RemovalParams = @{
                    Path        = $FilePath
                    WhatIf      = $WhatIfPreference
                    ErrorAction = "Stop"
                }
                
                $ItemSuccess = $false
                try{ 
                    Remove-Item @RemovalParams
                    $ItemSuccess = $true
                } catch {
                    $ItemSuccess = $false
                }
                #if($PSCmdlet.ShouldProcess($FilePath, "Remove File")){
                #    Remove-Item -Path $FilePath
                #    $ItemSuccess = $true
                #} elseif($WhatIfPreference){
                #    try{
                #        Remove-Item @RemovalParams
                #        $ItemSuccess = $true
                #    } catch {
                #        #Throw custom error if test fails
                #    }
                #}
                $ActionsTaken+=,[PSCustomObject]@{
                    Action    = "Delete"
                    Target    = $FilePath
                    Succeeded = $ItemSuccess
                }
            }
        } catch {
            throw $_
        }
    }
    END{
        return $ActionsTaken
    }
}