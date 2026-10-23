#requires -version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AppRoot='C:\SSLCTF05'; $ApacheRoot='C:\Apache24'; $HostName='admin.sibertaruna.my.id'; $TargetIP='192.168.36.247'
function Fail($Message) { throw "[ERROR] $Message" }
function Check($Message) { Write-Host "[PASS] $Message" -ForegroundColor Green }
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Fail 'Buka Windows PowerShell dengan Run as Administrator.' }
if (-not [Environment]::Is64BitOperatingSystem) { Fail 'Windows Server harus 64-bit.' }
New-Item -ItemType Directory -Force $AppRoot, "$AppRoot\certs", "$AppRoot\logs" | Out-Null
# Runtime requires user-supplied installer; do not silently download unknown binaries.
$redist = Get-ChildItem (Join-Path $Root 'installers') -File | Where-Object { $_.Name -match '(?i)^(vc[_-]?redist.*x64|vc_redist\.x64).*\.exe$' } | Select-Object -First 1
if (-not $redist) { Fail 'Letakkan vc_redist.x64.exe atau VC_redist.x64.exe pada Windows\installers\.' }
Write-Host '[INFO] Memasang Microsoft VC++ Redistributable...'
$p=Start-Process -FilePath $redist.FullName -ArgumentList '/install','/quiet','/norestart' -Wait -PassThru
if ($p.ExitCode -notin @(0,1638,3010)) { Fail "Pemasangan VC++ Runtime gagal dengan exit code $($p.ExitCode)" }
if ($p.ExitCode -eq 3010) { Write-Warning 'Runtime meminta reboot. Reboot server sebelum uji akhir apabila Apache gagal start.' }
Check 'VC++ Runtime: perintah instalasi selesai'
$archives = Get-ChildItem (Join-Path $Root 'installers') -File | Where-Object { $_.Name -match '^httpd-2\.4\.69-261002-Win64-VS18\.(zip|7z)$' }
$folder = Join-Path $Root 'installers\Apache24'
if (-not (Test-Path (Join-Path $folder 'bin\httpd.exe'))) {
  $archive = $archives | Where-Object Extension -eq '.zip' | Select-Object -First 1
  if (-not $archive) { Fail 'Letakkan httpd-2.4.69-261002-Win64-VS18.zip ATAU folder hasil ekstraksi Apache24 di Windows\installers. Arsip .7z perlu diekstrak dulu.' }
  $temp=Join-Path $env:TEMP 'sslctf05-apache-extract'
  if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
  New-Item -ItemType Directory -Force $temp | Out-Null
  Expand-Archive -LiteralPath $archive.FullName -DestinationPath $temp -Force
  $found=Get-ChildItem $temp -Recurse -Filter httpd.exe -File | Where-Object {$_.DirectoryName -match '\\Apache24\\bin$'} | Select-Object -First 1
  if (-not $found) { Fail 'Arsip tidak berisi Apache24\bin\httpd.exe yang diharapkan.' }
  $folder=Split-Path (Split-Path $found.FullName -Parent) -Parent
}
if (Test-Path "$ApacheRoot\bin\httpd.exe") {
  if (-not (Test-Path "$AppRoot\apache-installed.txt")) { Fail 'C:\Apache24 sudah ada dan bukan instalasi paket ini. Demi keamanan, setup menolak menimpa. Gunakan VM bersih atau backup/rename instalasi Anda secara manual.' }
} else {
  Copy-Item -LiteralPath $folder -Destination $ApacheRoot -Recurse -Force
}
Check 'Apache24 tersedia di C:\Apache24'
$cert=Join-Path $Root 'cert-input\fullchain.pem'; $key=Join-Path $Root 'cert-input\sibertaruna.my.id.key'
if (-not (Test-Path $cert) -or -not (Test-Path $key)) { Fail 'Sertifikat belum ada: masukkan fullchain.pem dan sibertaruna.my.id.key ke Windows\cert-input\.' }
Copy-Item $cert "$AppRoot\certs\fullchain.pem" -Force
Copy-Item $key "$AppRoot\certs\sibertaruna.my.id.key" -Force
& icacls.exe "$AppRoot\certs\sibertaruna.my.id.key" /inheritance:r /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' | Out-Null
Copy-Item (Join-Path $Root 'app.ps1') "$AppRoot\app.ps1" -Force
Copy-Item (Join-Path $Root 'healthcheck.ps1') "$AppRoot\healthcheck.ps1" -Force
# On setup, retain pre-TLS exercise and unprotected demo cookie.
Remove-Item "$AppRoot\secure-cookie.txt" -ErrorAction SilentlyContinue
$httpdConf=@'
ServerRoot "C:/Apache24"
Listen 80
ServerName admin.sibertaruna.my.id:80
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule mime_module modules/mod_mime.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule headers_module modules/mod_headers.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
LoadModule rewrite_module modules/mod_rewrite.so
ErrorLog "C:/SSLCTF05/logs/apache-error.log"
LogLevel warn
LogFormat "%h %l %u %t \"%r\" %>s %b" common
PidFile "C:/SSLCTF05/logs/httpd.pid"
TypesConfig "conf/mime.types"
ProxyRequests Off
ProxyPreserveHost On
<VirtualHost *:80>
  ServerName admin.sibertaruna.my.id
  ProxyPass / http://127.0.0.1:8088/
  ProxyPassReverse / http://127.0.0.1:8088/
  ErrorLog "C:/SSLCTF05/logs/vhost-error.log"
  CustomLog "C:/SSLCTF05/logs/access.log" common
</VirtualHost>
'@
# Backup the installation's initial config once; the learner's file remains unmanaged afterwards.
if (Test-Path "$ApacheRoot\conf\httpd.conf") { Copy-Item "$ApacheRoot\conf\httpd.conf" "$AppRoot\httpd.conf.original" -Force }
Set-Content -LiteralPath "$ApacheRoot\conf\httpd.conf" -Value $httpdConf -Encoding Ascii
Set-Content "$AppRoot\apache-installed.txt" 'owned by SSLCTF05 setup' -Encoding Ascii
# Dedicated SYSTEM startup task for local-only HTTP demo backend.
$taskName='SSLCTF05-Backend'
$action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\SSLCTF05\app.ps1'
$trigger=New-ScheduledTaskTrigger -AtStartup
$principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Days 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 2
$httpd="$ApacheRoot\bin\httpd.exe"
& $httpd -t
if ($LASTEXITCODE -ne 0) { Fail 'Konfigurasi Apache tidak valid. Periksa output httpd -t.' }
$svc=Get-Service -Name SSLCTF05Apache -ErrorAction SilentlyContinue
if (-not $svc) { & $httpd -k install -n SSLCTF05Apache; if ($LASTEXITCODE -ne 0) { Fail 'Gagal memasang Apache Windows service.' } }
$svc=Get-Service -Name SSLCTF05Apache
if ($svc.Status -eq 'Running') { Restart-Service SSLCTF05Apache } else { Start-Service SSLCTF05Apache }
if (-not (Get-NetFirewallRule -DisplayName 'SSLCTF05 Lab HTTP' -ErrorAction SilentlyContinue)) { New-NetFirewallRule -DisplayName 'SSLCTF05 Lab HTTP' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80 -Profile Any -RemoteAddress '192.168.36.0/24' | Out-Null }
if (-not (Get-NetFirewallRule -DisplayName 'SSLCTF05 Lab HTTPS' -ErrorAction SilentlyContinue)) { New-NetFirewallRule -DisplayName 'SSLCTF05 Lab HTTPS' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 443 -Profile Any -RemoteAddress '192.168.36.0/24' | Out-Null }
$hostsPath="$env:SystemRoot\System32\drivers\etc\hosts"
$lines=Get-Content $hostsPath
if (-not ($lines | Where-Object { $_ -match '^\s*192\.168\.36\.247\s+admin\.sibertaruna\.my\.id\s*$' })) { Add-Content $hostsPath "`r`n192.168.36.247 admin.sibertaruna.my.id" }
$ok=$false
for($i=0;$i -lt 12;$i++) { try { $resp=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1/health' -TimeoutSec 3; if($resp.StatusCode -eq 200 -and $resp.Content.Trim() -eq 'OK'){ $ok=$true; break }} catch{}; Start-Sleep -Seconds 2 }
if (-not $ok) { Fail 'SELF-TEST GAGAL: HTTP /health belum 200. Periksa Get-ScheduledTask SSLCTF05-Backend dan C:\SSLCTF05\logs\apache-error.log. TIDAK menampilkan READY.' }
Check 'Apache config OK; service running; backend /health HTTP 200'
Write-Host 'READY: HTTP AKTIF, HTTPS SENGAJA BELUM AKTIF. SIMPAN SNAPSHOT VM SEKARANG.' -ForegroundColor Green
Write-Host 'Target: http://admin.sibertaruna.my.id / IP 192.168.36.247'
Write-Host 'Certificate stored: C:\SSLCTF05\certs (jangan dibagikan ke Kali/LMS)'
