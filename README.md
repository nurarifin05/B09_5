# WEB-05 CTF SSL/TLS — Windows Server 2016 + Apache 2.4.69
Windows 192.168.36.247, Kali 192.168.36.228, hostname admin.sibertaruna.my.id.

1. Pada Windows, masukkan VC_redist.x64.exe dan ZIP Apache httpd-2.4.69-261002-Win64-VS18.zip ke `Windows/installers/`. Bila Apache berupa folder, ekstrak menjadi `Windows/installers/Apache24/`.
2. Masukkan `fullchain.pem` dan `sibertaruna.my.id.key` pada `Windows/cert-input/`.
3. Buka Windows PowerShell **Run as Administrator** pada folder `Windows/`, jalankan `Set-ExecutionPolicy -Scope Process Bypass -Force` lalu `.\setup.ps1`.
4. Script memasang runtime, menyalin Apache ke C:\Apache24, memasang service SSLCTF05Apache, mendaftarkan backend sebagai scheduled task SYSTEM, firewall lokal, dan self-test HTTP. Output READY **hanya setelah /health HTTP 200**.
5. Di Kali, jalankan `sudo bash Kali/setup.sh`, lalu `sslctf-info`, lakukan capture HTTP pertama, dan `sslctf-validate`.
6. Berikan hanya folder `Materi-Taruna` dan akses VM kepada taruna. Jangan berikan `Panduan-Dosen-RAHASIA`, private key, atau kunci flag.
7. HTTPS memang sengaja BELUM aktif setelah setup. Taruna yang mengaktifkan dan melakukan hardening berdasarkan dokumen dosen.
8. Snapshot segera setelah semua self-test lulus. Pengujian lengkap sepuluh challenge pada VM nyata tetap perlu dilakukan sebelum ujian.

PENTING: Firewall dibatasi subnet 192.168.36.0/24. Pastikan Windows mendapat IP 192.168.36.247 secara statis sebelum instalasi. ZIP tidak menyertakan Apache maupun runtime berlisensi pihak ketiga. `setup.ps1` menghentikan proses jika file belum ditemukan.
