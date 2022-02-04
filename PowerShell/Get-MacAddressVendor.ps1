$script:APIKey_MacAddressio = ""
function Get-MacAddressVendor{
    <#
        .SYNOPSIS
        

        .DESCRIPTION
        

        .EXAMPLE
        PS> 

    #>
    [Alias()]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        [ValidateNotNull()]
            $MacAddress
    )
    BEGIN{
        #region Cache Management
            $script:MacAddressVendorCache=@()
            function Test-MacAddressVendorCached{
                param(
                    [String]$MacAddress
                )
                $IsCached = if($script:MacAddressVendorCache.MacAddress -contains $MacAddress){
                        $true
                    } else {
                        $false
                    }
                return $IsCached
            }
            function New-MacAddressVendorCacheEntry{
                param(
                    [String]$MacAddress,
                    $VendorInfo
                )
                $Success = $false

                try{
                    if(-Not (Test-MacAddressVendorCached -MacAddress $MacAddress)){
                        $script:MacAddressVendorCache+=,[PSCustomObject]@{
                                MacAddress = $MacAddress
                                VendorInfo = $VendorInfo
                            }
                        $Success = $true
                    } else {
                        $Success = $true
                    }
                } catch {
                    $Success = $false
                    Write-Error $_
                }

                return $Success
            }
        #endregion
        function Request-MacVendor{
            param(
                $APUUri,
                $RequestDelaySeconds = 1
                #$RequestLimit
            )
            Start-Sleep -Seconds $RequestDelaySeconds
            return Invoke-WebRequest -Uri $RequestUrl
        }
        function Invoke-APIRequest{
            param(
                [Parameter(Mandatory)]
                [String]
                [ValidateNotNull()]
                    $APUUrlFormat,
                [Parameter(Mandatory)]
                [String]
                [ValidateNotNull()]
                    $MacAddress,
                [Parameter()]
                [String]
                [ValidateNotNull()]
                [ValidateSet('xml', 'json', 'csv')]
                    $OutputType = 'json',
                [Parameter()]
                [String]
                [ValidateNotNull()]
                    $APIKey,
                [Parameter()]
                [Int]
                [ValidateNotNull()]
                    $RequestDelaySeconds = 0
                #$RequestLimit
            )
            BEGIN {
                throw "NOT FULLY IMPLEMENTED"
                $Return = $null
            }
            PROCESS {
                # Pause requested amount of time prior to making the request (if applicable)
                if(($null -ne $RequestDelaySeconds) -and ($RequestDelaySeconds -gt 0)){
                    Start-Sleep -Seconds $RequestDelaySeconds
                }

                try{
                    #region Format request uri
                    
                        $RequestUri = $APUUrlFormat
                        $Substitutions = @(
                            $MacAddress
                        )
                        if($APUUrlFormat -contains '{2}'){
                            if(-Not [String]::IsNullOrWhiteSpace($OutputType)){
                                $Substitutions+=,$OutputType
                            } else {
                                throw ("No Output Type was provided. `{ 'RequestUrlFormat':'{0}' `}" -f $APUUrlFormat)
                            }
                        }
                        if($APUUrlFormat -contains '{3}'){
                            if(-Not [String]::IsNullOrWhiteSpace($APIKey)){
                                $Substitutions+=,$APIKey
                            } else {
                                throw ("Null or invalid API Key provided. `{ 'RequestUrlFormat':'{0}' `}" -f $APUUrlFormat)
                            }
                        }

                        $RequestUri = $RequestUri -f $Substitutions
                        $RequestUri = [uri]::EscapeUriString($RequestUrl)

                    #endregion

                    # Execute Request
                    $Return = Invoke-WebRequest -Uri $RequestUrl
                } catch {
                    $Return = $null
                    Write-Error $_
                }
            }
            END {
                return $Return
            }
        }
        
        $APIConfigList = @(
            #region Option 1: https://macaddress.io/api/documentation/making-requests
                # {0} = MacAddress  / Search String
                # {1} = Output Type (json, etc)
                # {2} = API Key
                [PSCustomObject]@{
                    APIKey              = $script:APIKey_MacAddressio
                    RequestFormat       = 'https://api.macaddress.io/v1?apiKey={2}&output={1}&search={0}'
                    RequestDelay        = 1
                    SupportedOuputTypes = @(
                        'json'
                        # NEED TO UPDATE THIS
                    )
                    DefaultOutputType   = 'json'
                    AcceptedInputFormats = @(
                        '00:11:22:33:44:55'
                        # NEED TO UPDATE THIS
                    )
                    Documentation = @(
                        'https://api.macaddress.io/v1?apiKey==json&search=44:38:39:ff:ef:57'
                    )
                }
            #endregion
            #region Option 2: https://macvendors.com/api
                [PSCustomObject]@{
                    APIKey              = $null
                    RequestFormat       = 'https://www.macvendorlookup.com/api/v2/{0}/{1}'
                    RequestDelay        = 1
                    SupportedOuputTypes = @(
                        'json'
                        'xml'
                        # NEED TO UPDATE THIS
                    )
                    DefaultOutputType   = 'json'
                    AcceptedInputFormats = @(
                        # NEED TO UPDATE THIS
                    )
                    Documentation = @(
                        'https://www.macvendorlookup.comapi'
                    )
                }
                <# 
                $RequestUrl = [uri]::EscapeUriString(("https://www.macvendorlookup.com/api/v2/{0}/{1}" -f $($MacAddress.Replace(":", "")), "xml"))
                Write-Host $RequestUrl
                $Return = Request-MacVendor -APUUri $RequestUrl -RequestDelaySeconds 5
                #$Return     = $VendorName
                #>
            #endregion
            #region Option 3 (Vendor Only)
                [PSCustomObject]@{
                    APIKey              = $null
                    RequestFormat       = 'https://api.macvendors.com/{0}'
                    RequestDelay        = 1
                    SupportedOuputTypes = @(
                        'xml'
                        'csv'
                        # NEED TO UPDATE THIS
                    )
                    DefaultOutputType   = 'xml'
                    AcceptedInputFormats = @(
                        '00-11-22-33-44-55'
                        '00:11:22:33:44:55'
                        '00.11.22.33.44.55'
                        '001122334455'
                        '0011.2233.4455'
                    )
                    Documentation = @(
                        'https://macvendors.com/api'
                    )
                }
                <#
                    # https://macvendors.com/api
                    $RequestUrl = [uri]::EscapeUriString("https://api.macvendors.com/$MacAddress")
                    $VendorName = Request-MacVendor -APUUri $RequestUrl -RequestDelaySeconds 5
                    if(-Not [String]::IsNullOrEmpty($MacAddress)){
                        $Return = [PSCustomObject]@{
                            MacAddress = $MacAddress
                            Vendor     = $VendorName
                        }
                        $TryAgain = $false
                    } else {
                        $TryAgain = $true
                    }
                #>
            #endregion
        )
        
    }
    PROCESS{

        #region Sanitize $MacAddress
            #  -All uppercase letters
            #  -##:##:##:##:##:##
            $PreferredDelim = ":"
            $MacAddress = $MacAddress.ToUpper()
            $MacAddress = $MacAddress.Replace(":", $PreferredDelim)
            $MacAddress = $MacAddress.Replace("-", $PreferredDelim)
            $MacAddress = $MacAddress.Replace(".", $PreferredDelim)
            # XXXXXXXXXXXX      | 12
            # XXXXXX-XXXXXX     | 13
            # XX-XX-XX-XX-XX-XX | 17
            switch($MacAddress.Length){
                (12){
                    for($a = 10; $a -ge 2; $a -= 2){
                        $Segment1 = $MacAddress.Substring(0, $a)
                        $Segment2 = $MacAddress.Substring($a)
                        $MacAddress = "{0}$PreferredDelim{1}" -f $Segment1, $Segment2
                    }
                }
                (13){
                    $MacAddress = $MacAddress.Replace($PreferredDelim, "")
                    for($a = 10; $a -ge 2; $a -= 2){
                        $Segment1 = $MacAddress.Substring(0, $a)
                        $Segment2 = $MacAddress.Substring($a)
                        $MacAddress = "{0}$PreferredDelim{1}" -f $Segment1, $Segment2
                    }
                }
                (17){
                    # DO NOTHING
                }
                default{
                    throw "Unexpected input length for Mac Address. [$MacAddress]"
                }
            }
            $MacAddress = $MacAddress.Replace("-", ":")
        #endregion
        
        #region Initialize / Sanitixe $OutputType
            # Initialize splat variable $OutputType if not provided
            if([String]::IsNullOrWhiteSpace($OutputType)){
                $OutputType = $APIConfig.DefaultOutputType
            } 
            # Save initial value to check in case a manual conversion is necessary due to unsupported output formats in the API itself
            $InitialOutputType = $OutputType
        #endregion

        # Make sure MACAddress vendor info isn't already cached
        $IsCached = Test-MacAddressVendorCached -MacAddress $MacAddress

        if(-Not $IsCached){
            # Initialize splat params
            $InitialInvocationParams = @{
                MacAddress = $MacAddress
            }
            
            # Iterate through configured APIConfigs until successful
            $VendorInfoRetrieved = $false
            $APIConfigList | %{
                if($VendorInfoRetrieved -eq $false){
                    # API Config specific invocation params
                    $InvocationParams    = $InitialInvocationParams

                    # Update splat variable $OutputType to the default output type if $InitialOutputType unsupported by the API
                    if($APIConfig.SupportedOutputTypes -notcontains $OutputType){
                        $OutputType = $APIConfig.DefaultOutputType
                    }

                    # Add additional splat parameters specific to $APIConfig
                    $InvocationParams.Add("APIUrlFormat", $APIConfig.RequestFormat)
                    $InvocationParams.Add("OutputType", $OutputType)
                    $InvocationParams.Add("APIKey", $APIConfig.APIKey)
                    $InvocationParams.Add("RequestDelaySeconds", $APIConfig.RequestDelay)

                    # Invoke request
                    $Return = Invoke-APIRequest @InvocationParams

                    if($null -ne $Return){
                        #region Perform manual output conversions (if necessary)
                            if($InitialOutputType -ne $OutputType){
                                switch($InitialOutputType){
                                    ('json') {
                                        $Return = ($Return | ConvertTo-Json)
                                    }
                                    ('xml') {
                                        $Return = ($Return | ConvertTo-Xml)
                                    }
                                    ('csv') {
                                        $Return = ($Return | ConvertTo-Csv)
                                    }
                                    #('html') {
                                    #    $Return = ($Return | ConvertTo-html)
                                    #}
                                    default {
                                        # Leave as is?
                                    }
                                }
                            }
                        #endregion
            
                        # Add MACAddress vendor info to cache
                        New-MacAddressVendorCacheEntry -MacAddress $MacAddress -VendorInfo $Return

                        # Update $VendorInfoRetrieved
                        $VendorInfoRetrieved = $true
                    }
                }
            }
        }
    }
    END{
        return $Return
    }
}
