#Cleanup IIS Logs Directory

$LogPath = "C:\inetpub\logs" 
$maxDaystoKeep = -30 
$outputPath = "D:\Logs\Cleanup_Old_logs.log" 
  
$itemsToDelete = dir $LogPath -Recurse -File *.log | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep)) 
  
if ($itemsToDelete.Count -gt 0){ 
    ForEach ($item in $itemsToDelete){ 
        "$($item.BaseName) is older than $((get-date).AddDays($maxDaystoKeep)) and will be deleted" | Add-Content $outputPath 
        Get-item $item | Remove-Item -Verbose 
    } 
} 
ELSE{ 
    "No items to be deleted today $($(Get-Date).DateTime)"  | Add-Content $outputPath 
    } 
   
Write-Output "Cleanup of log files older than $((get-date).AddDays($maxDaystoKeep)) completed..." 


#Disable IIS Logging
$dontLog = (get-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog).Value
Write-Output " IIS Logging (dontLog) was set to $dontLog" 
set-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog -value $true
$dontLog = (get-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog).Value
Write-Output " IIS Logging (dontLog) was now to $dontLog"  