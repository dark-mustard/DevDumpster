function Get-VMClusterVMs{
    param(
        [String]
            $ClusterName,
        [Switch]
            $All
    )
    $ClusterVMs = @(Get-ClusterNode -Cluster $ClusterName | %{
        $ClusterNode = $_
        $ParamList = @{
            "ComputerName" = ($ClusterNode.Name)
        }
        if(-Not $All){
            # Limit to active only
            #Get-VM @ParamList | Where { $_.State -eq "Online" -and $_.SharedVolumeInfo.MaintenanceMode -eq $false }
            Get-VM @ParamList | Where { $_.State -eq "Running" }
        } else {
            Get-VM @ParamList
        }
    })

    return $ClusterVMs
}
