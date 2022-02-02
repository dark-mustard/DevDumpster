function Get-VMClusterStorage{
    param(
        [String] 
            $ClusterName,
        [Switch] 
            $All
    )
    $CSVList=@(Get-ClusterSharedVolume -Cluster $ClusterName)
    
    $Return=@(if(-Not $All){
        # Limit to active only
        $CSVList | Where { $_.State -eq "Online" -and $_.SharedVolumeInfo.MaintenanceMode -eq $false }
    } else {
        $CSVList
    }) | Select-Object Id, `
                Name, `
                OwnerNode, `
                @{ Name="Path";            Expression={ $_.SharedVolumeInfo.FriendlyVolumeName } }, `
                @{ Name="DirectoryName";   Expression={ Split-Path $_.SharedVolumeInfo.FriendlyVolumeName -Leaf } }, `
                @{ Name="DiskFreePercent"; Expression={ $_.SharedVolumeInfo.Partition.PercentFree } }, `
                @{ Name="DiskUsed_TB";     Expression={ [Math]::Round((((($_.SharedVolumeInfo.Partition.UsedSpace / 1024) / 1024) / 1024) / 1024), 1) } }, `
                @{ Name="DiskTotal_TB";    Expression={ [Math]::Round((((($_.SharedVolumeInfo.Partition.Size / 1024) / 1024) / 1024) / 1024), 1) } }, `
                @{ Name="DiskUsed_GB";     Expression={ [Math]::Round(((($_.SharedVolumeInfo.Partition.UsedSpace / 1024) / 1024) / 1024), 2) } }, `
                @{ Name="DiskTotal_GB";    Expression={ [Math]::Round(((($_.SharedVolumeInfo.Partition.Size / 1024) / 1024) / 1024), 2) } }
    return $Return
}