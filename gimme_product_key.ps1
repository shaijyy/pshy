Write-Host "=== Gimme Product Key ===" -ForegroundColor Cyan
echo "Sure bro! here's ur Product Key:" (Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
