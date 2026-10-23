$ErrorActionPreference='Continue'
Write-Host '== WEB05 Windows health check =='
& 'C:\Apache24\bin\httpd.exe' -t
Get-Service SSLCTF05Apache | Format-Table Name,Status
Get-ScheduledTask SSLCTF05-Backend | Format-Table TaskName,State
try { (Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1/health').StatusCode } catch { Write-Host "Health failed: $_" }
