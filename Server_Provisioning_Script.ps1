#Specify the App pools you want to create
$ApplicationPoolNames=@("Audit","Dashboard","ProtocolManager","Radmetrix","Realtime","TeachingFiles","Tools")

#Install Features
 
function InstallFeature($name) {
Enable-WindowsOptionalFeature -Online -FeatureName $name
}
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
 
InstallFeature IIS-WebServerRole
InstallFeature IIS-WebServer
InstallFeature IIS-CommonHttpFeatures
InstallFeature IIS-DefaultDocument
InstallFeature IIS-DirectoryBrowsing
InstallFeature IIS-HttpErrors
InstallFeature IIS-HttpRedirect
InstallFeature IIS-StaticContent
InstallFeature IIS-HealthAndDiagnostics
InstallFeature IIS-LoggingLibraries
InstallFeature IIS-ODBCLogging
InstallFeature IIS-HttpLogging
InstallFeature IIS-HttpTracing
InstallFeature IIS-Security
InstallFeature IIS-RequestFiltering
InstallFeature IIS-BasicAuthentication
Add-WindowsFeature NET-Framework-45-ASPNET
InstallFeature IIS-ApplicationDevelopment
InstallFeature IIS-ApplicationInit 
InstallFeature IIS-NetFxExtensibility
InstallFeature IIS-NetFxExtensibility45
InstallFeature IIS-WebSockets
InstallFeature IIS-ISAPIExtensions
InstallFeature IIS-ISAPIFilter
InstallFeature IIS-ASPNET
InstallFeature IIS-WebServerManagementTools 
InstallFeature IIS-ManagementConsole 
InstallFeature IIS-ManagementScriptingTools
InstallFeature IIS-ServerSideIncludes
InstallFeature IIS-RequestMonitor
InstallFeature IIS-CGI
InstallFeature IIS-Performance
InstallFeature IIS-HttpCompressionDynamic
InstallFeature IIS-HttpCompressionStatic
InstallFeature IIS-ManagementService                   
InstallFeature IIS-FTPServer
InstallFeature IIS-FTPSvc
InstallFeature IIS-FTPExtensibility
InstallFeature IIS-ASP
InstallFeature IIS-AspNet45

sleep -Seconds 5

#Create App Pools

import-module WebAdministration
$SiteDirectory = 'C:\inetpub\wwwroot\'+$ApplicationPool
ForEach ($ApplicationPool in $ApplicationPoolNames)
{

if ((Test-Path IIS:\apppools\$ApplicationPool) -eq $false) {
    Write-Output 'Creating new app pool ...'
New-WebAppPool $ApplicationPool
$AppPool = Get-Item iis:\apppools\$ApplicationPool
$AppPool.Stop()
Set-ItemProperty IIS:\AppPools\$ApplicationPool managedPipelineMode 0
Set-ItemProperty IIS:\AppPools\$ApplicationPool managedRuntimeVersion v4.0
Set-WebConfiguration -Filter '/system.applicationHost/serviceAutoStartProviders' -Value (@{name="ApplicationPreload";type="WebApplication1.ApplicationPreload, WebApplication1"})  
Set-ItemProperty IIS:\Sites\$websiteName -Name applicationDefaults.serviceAutoStartEnabled -Value True  
Set-ItemProperty IIS:\Sites\$websiteName -Name applicationDefaults.serviceAutoStartProvider -Value 'ApplicationPreload'  
Set-ItemProperty IIS:\AppPools\$appPoolName -Name autoStart -Value True  
Set-ItemProperty IIS:\AppPools\$appPoolName -Name startMode -Value 1 #1 = AlwaysRunning, 0 = OnDemand  
Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout -Value "00:00:00" #0 = No timeout
$AppPool.Start()
New-Item C:\inetpub\wwwroot\$ApplicationPool -type Directory }

}

sleep -Seconds 5

#App Pools Post-Installation configuration

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

#Set app pools recycling

Set-WebConfiguration `/system.applicationHost/applicationPools/applicationPoolDefaults/recycling/periodicRestart ` -value "0"
Add-WebConfiguration `/system.applicationHost/applicationPools/applicationPoolDefaults/recycling/periodicRestart/schedule ` -value (New-TimeSpan -h 3 -m 00)

#Unlock ASP section
C:\Windows\system32\inetsrv\appcmd.exe unlock config -section:system.webServer/asp

#Enable Parent Paths
C:\Windows\system32\inetsrv\appcmd set config /section:system.webServer/asp /enableparentpaths:True /commit

#Send Errors to browser
C:\Windows\system32\inetsrv\appcmd set config /section:system.webServer/asp /scriptErrorSentToBrowser:"True" /commit

#Log Errors to NT log
C:\Windows\system32\inetsrv\appcmd set config /section:system.webServer/asp /errorsToNTLog:True /commit

#Set App Pools Idle Timeout to 0
ForEach ($ApplicationPool in $ApplicationPoolNames)
{Set-ItemProperty ("IIS:\AppPools\$ApplicationPool") -Name processModel.idleTimeout -value ( [TimeSpan]::FromMinutes(0))}

sleep -Seconds 10

#Install chocolatey

Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco feature enable -n allowGlobalConfirmation

sleep -Seconds 5

#Install Notepad ++

choco install notepadplusplus

sleep -Seconds 5
