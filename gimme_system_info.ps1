$OutFile = Read-Host "Enter output file path (or leave blank for console only)"
$TopProcesses = Read-Host "How many top processes to show? (default 10)"
if (-not $TopProcesses) { $TopProcesses = 10 }

function Get-Uptime { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptime = (Get-Date) - $boot; [PSCustomObject]@{LastBootUpTime=$boot; Uptime=$uptime.ToString(); UptimeDays=[math]::Round($uptime.TotalDays,2)} }

$computer=$env:COMPUTERNAME
$now=Get-Date
$os=Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,SerialNumber,@{Name='InstallDate';Expression={[Management.ManagementDateTimeConverter]::ToDateTime($_.InstallDate)}}
$compInfo=@{
ComputerName=$computer
CollectedAt=$now
OS=$os
ComputerInfo=if(Get-Command Get-ComputerInfo -ErrorAction SilentlyContinue){Get-ComputerInfo -Property CsManufacturer,CsModel,OsName,OsVersion,OsBuildNumber,OsArchitecture}else{$null}
BIOS=Get-CimInstance Win32_BIOS | Select-Object Manufacturer,SMBIOSBIOSVersion,ReleaseDate,SerialNumber
CPU=Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed
Memory=@{TotalVisibleMemoryMB=[math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize/1024,2);FreePhysicalMemoryMB=[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024,2)}
Drives=Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,VolumeName,FileSystem,Size,FreeSpace,@{Name='SizeGB';Expression={[math]::Round($_.Size/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.FreeSpace/1GB,2)}}
NetworkAdapters=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled = true" | Select-Object Description,MACAddress,IPAddress,DefaultIPGateway,DNSDomain,@{Name='DHCPEnabled';Expression={$_.DHCPEnabled}}
Uptime=Get-Uptime
Hotfixes=Get-HotFix -ErrorAction SilentlyContinue | Select-Object HotFixID,InstalledOn
TopProcessesByCPU=Get-Process | Sort-Object CPU -Descending | Select-Object -First $TopProcesses Id,ProcessName,CPU,WorkingSet
TopProcessesByMemory=Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First $TopProcesses Id,ProcessName,WorkingSet,@{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet/1MB,2)}}
}

Write-Host "=== Gimme System Info ===" -ForegroundColor Cyan
Write-Host "Computer: $computer   Collected: $now"
Write-Host "`n-- OS --"; $compInfo.OS | Format-List
Write-Host "`n-- CPU --"; $compInfo.CPU | Format-List
Write-Host "`n-- Memory (MB) --"; $compInfo.Memory | Format-List
Write-Host "`n-- Drives --"; $compInfo.Drives | Format-Table -AutoSize
Write-Host "`n-- Network Adapters (IP enabled) --"; $compInfo.NetworkAdapters | Format-Table -AutoSize
Write-Host "`n-- Uptime --"; $compInfo.Uptime | Format-List
Write-Host "`n-- Top Processes by CPU --"; $compInfo.TopProcessesByCPU | Format-Table -AutoSize
Write-Host "`n-- Top Processes by Memory --"; $compInfo.TopProcessesByMemory | Format-Table -AutoSize

if ($OutFile) {
    $ext=[IO.Path]::GetExtension($OutFile).ToLowerInvariant()
    switch ($ext) {
        '.json'{$compInfo|ConvertTo-Json -Depth 6|Out-File $OutFile -Encoding UTF8;Write-Host "`nSaved JSON report to $OutFile"}
        '.csv'{$summary=[PSCustomObject]@{ComputerName=$compInfo.ComputerName;CollectedAt=$compInfo.CollectedAt;OS=$compInfo.OS.Caption;OSVersion=$compInfo.OS.Version;CPU=($compInfo.CPU|Select-Object -First 1).Name;TotalMemoryMB=$compInfo.Memory.TotalVisibleMemoryMB;FreeMemoryMB=$compInfo.Memory.FreePhysicalMemoryMB;Drives=($compInfo.Drives|ForEach-Object{"$($_.DeviceID):$([math]::Round($_.FreeSpace/1GB,2))GBfree"}) -join '; ';IPs=($compInfo.NetworkAdapters|ForEach-Object{$_.IPAddress -join ','}) -join '; ';LastBoot=$compInfo.Uptime.LastBootUpTime};$summary|Export-Csv $OutFile -NoTypeInformation -Encoding UTF8;Write-Host "`nSaved CSV summary to $OutFile"}
        default{$sb=New-Object System.Text.StringBuilder;$sb.AppendLine("Gimme System Info Report")|Out-Null;$sb.AppendLine("Collected: $now")|Out-Null;$sb.AppendLine("OS:")|Out-Null;$sb.AppendLine(($compInfo.OS|Out-String))|Out-Null;$sb.AppendLine("CPU:")|Out-Null;$sb.AppendLine(($compInfo.CPU|Out-String))|Out-Null;$sb.AppendLine("Memory:")|Out-Null;$sb.AppendLine(($compInfo.Memory|Out-String))|Out-Null;$sb.AppendLine("Drives:")|Out-Null;$sb.AppendLine(($compInfo.Drives|Out-String))|Out-Null;$sb.AppendLine("Network Adapters:")|Out-Null;$sb.AppendLine(($compInfo.NetworkAdapters|Out-String))|Out-Null;$sb.AppendLine("Top Processes by CPU:")|Out-Null;$sb.AppendLine(($compInfo.TopProcessesByCPU|Out-String))|Out-Null;$sb.AppendLine("Top Processes by Memory:")|Out-Null;$sb.AppendLine(($compInfo.TopProcessesByMemory|Out-String))|Out-Null;$sb.ToString()|Out-File $OutFile -Encoding UTF8;Write-Host "`nSaved text report to $OutFile"}
    }
}

return $compInfo
