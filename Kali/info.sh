#!/usr/bin/env bash
cat <<'END'
WEB05 - Gateway Administrasi Taruna
Windows Server: 192.168.36.247 / admin.sibertaruna.my.id
Kali: 192.168.36.228
Kredensial DUMMY: admin_demo_05 / Latihan-05!
Terminal A: sudo tcpdump -i any -s 0 -w ~/sslctf-evidence/before.pcap 'host 192.168.36.247 and port 80'
Terminal B: curl --noproxy '*' --resolve 'admin.sibertaruna.my.id:80:192.168.36.247' -d 'username=admin_demo_05&password=Latihan-05!' http://admin.sibertaruna.my.id/login
Stop TCPDUMP Ctrl+C. Jalankan sslctf-validate untuk flag 01-02. Kemudian kerjakan HTTPS dan uji TLS serta flag 03-10 sesuai dokumen.
END
