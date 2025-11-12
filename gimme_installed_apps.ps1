Write-Host "=== Gimme Installed Apps ===" -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator. Exiting." -ForegroundColor Red
    exit
}

$OutFile = Read-Host "Enter output file path (or leave blank for console only)"
$IncludeAppx = Read-Host "Include Appx/UWP packages? (Y/N)"
$IncludeAppx = if ($IncludeAppx -match '^[Yy]') {$true} else {$false}
$UninstallKeyFilter = Read-Host "Optional: filter by application name (wildcard), leave blank for all"

function Get-RegistryInstalledApps {
    param([string]$RegPath)
    if (-not (Test-Path $RegPath)) { return @() }
    Get-ChildItem $RegPath -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Source = $RegPath
            Key = $_.Name
            DisplayName = $p.DisplayName
            DisplayVersion = $p.DisplayVersion
            Publisher = $p.Publisher
            InstallDate = $p.InstallDate
            InstallLocation = $p.InstallLocation
            EstimatedSizeKB = $p.EstimatedSize
            UninstallString = $p.UninstallString
            QuietUninstallString = $p.QuietUninstallString
        }
    } | Where-Object { $_.DisplayName -and ($UninstallKeyFilter -eq $null -or ($_.DisplayName -like $UninstallKeyFilter)) }
}

$results = @()

$hklm32 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$hklm64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$hkcu = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

try { $results += Get-RegistryInstalledApps -RegPath $hklm32 } catch {}
try { $results += Get-RegistryInstalledApps -RegPath $hklm64 } catch {}
try { $results += Get-RegistryInstalledApps -RegPath $hkcu } catch {}

if ($IncludeAppx) {
    try {
        $appx = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | ForEach-Object {
            [PSCustomObject]@{
                Source = 'Appx'
                Key = $_.PackageFullName
                DisplayName = $_.Name
                DisplayVersion = $_.Version.ToString()
                Publisher = $_.PublisherDisplayName
                InstallDate = $_.InstallDate
                InstallLocation = $_.InstallLocation
                UninstallString = $null
                EstimatedSizeKB = $null
            }
        }
        $results += $appx
    } catch {}
}

$deduped = $results |
    Where-Object { $_.DisplayName } |
    Group-Object -Property @{Expression = { ($_.DisplayName.Trim() + '|' + ($_.DisplayVersion -as [string])) }} |
    ForEach-Object { $_.Group | Select-Object -First 1 }

Write-Host "Installed applications found: $($deduped.Count)" -ForegroundColor Cyan
$deduped | Select-Object DisplayName, DisplayVersion, Publisher, Source, InstallDate | Format-Table -AutoSize

if ($OutFile) {
    $ext = [IO.Path]::GetExtension($OutFile).ToLowerInvariant()
    switch ($ext) {
        '.json' { $deduped | ConvertTo-Json -Depth 4 | Out-File $OutFile -Encoding UTF8; Write-Host "Saved JSON to $OutFile" }
        '.csv' { $deduped | Select-Object DisplayName, DisplayVersion, Publisher, Source, InstallDate, InstallLocation, UninstallString | Export-Csv $OutFile -NoTypeInformation -Encoding UTF8; Write-Host "Saved CSV to $OutFile" }
        default { $deduped | Out-String | Out-File $OutFile -Encoding UTF8; Write-Host "Saved text output to $OutFile" }
    }
}

return $deduped
