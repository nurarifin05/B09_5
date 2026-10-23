$ErrorActionPreference='Stop'
$listener=New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://127.0.0.1:8088/')
$listener.Start()
try {
while($listener.IsListening) {
  $ctx=$listener.GetContext(); $req=$ctx.Request; $res=$ctx.Response
  $path=$req.Url.AbsolutePath; $status=200; $type='text/html; charset=utf-8'
  $body='<h1>Portal Administrasi Taruna</h1><p>Latihan HTTP/TLS</p><form method="POST" action="/login"><input name="username" placeholder="Username"><input type="password" name="password" placeholder="Password"><button>Login Dummy</button></form><p>Semua akun adalah data simulasi.</p>'
  if ($path -eq '/health') { $body='OK'; $type='text/plain; charset=utf-8' }
  elseif ($path -eq '/login' -and $req.HttpMethod -eq 'POST') {
    $reader=New-Object System.IO.StreamReader($req.InputStream,$req.ContentEncoding)
    $posted=$reader.ReadToEnd(); $reader.Dispose()
    # Never echo or persist the submitted credentials.
    $body='<h1>Login dummy diproses</h1><p>Gunakan capture jaringan untuk analisis.</p>'
    if (Test-Path 'C:\SSLCTF05\secure-cookie.txt') { $res.Headers.Add('Set-Cookie','lab_session=dummy-session; Path=/; Secure; HttpOnly; SameSite=Lax') }
    else { $res.Headers.Add('Set-Cookie','lab_session=dummy-session; Path=/') }
  }
  elseif ($path -ne '/' -and $path -ne '/login' -and $path -ne '/health') { $status=404; $body='Not found' }
  $data=[Text.Encoding]::UTF8.GetBytes($body)
  $res.StatusCode=$status; $res.ContentType=$type; $res.ContentLength64=$data.Length
  if ($req.HttpMethod -ne 'HEAD') { $res.OutputStream.Write($data,0,$data.Length) }
  $res.Close()
}
} finally { $listener.Stop() }
