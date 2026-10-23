#!/usr/bin/env bash
set -u
HOST='admin.sibertaruna.my.id'; IP='192.168.36.247'; E="${SSLCTF_EVIDENCE:-$HOME/sslctf-evidence}"; mkdir -p "$E"
flag() { local n="$1"; shift; if "$@"; then printf '[LULUS] %02d => {FLAG_SSL05_%02d_%s}\n' "$n" "$n" "$(printf '%s' "${HOST}:$n:CTF-LMS-2026" | sha256sum | cut -c1-12 | tr '[:lower:]' '[:upper:]')"; else printf '[BELUM] %02d\n' "$n"; fi; }
before() { [[ -s "$E/before.pcap" ]] && tshark -r "$E/before.pcap" -Y 'http.request.method == "POST"' -T fields -e http.request.uri 2>/dev/null | grep -q '/login'; }
leaked() { [[ -s "$E/before.pcap" ]] && tshark -r "$E/before.pcap" -V 2>/dev/null | grep -Fq 'admin_demo_05' && tshark -r "$E/before.pcap" -V 2>/dev/null | grep -Fq 'Latihan-05!'; }
certname() { echo | timeout 8 openssl s_client -connect "$IP:443" -servername "$HOST" 2>/dev/null | openssl x509 -noout -checkhost "$HOST" 2>/dev/null | grep -q 'does match'; }
web() { curl --noproxy '*' -kfsS --resolve "$HOST:443:$IP" --max-time 8 "https://$HOST/" >/dev/null 2>&1; }
chain() { local n; n=$(echo | timeout 8 openssl s_client -connect "$IP:443" -servername "$HOST" -showcerts 2>/dev/null | grep -c 'BEGIN CERTIFICATE'); [[ "$n" -ge 2 ]]; }
redirect() { curl --noproxy '*' -s -o /dev/null --resolve "$HOST:80:$IP" -w '%{http_code} %{redirect_url}' "http://$HOST/" | grep -Eq '^30[1278] https://'; }
tls12() { echo | timeout 8 openssl s_client -connect "$IP:443" -servername "$HOST" -tls1_2 2>&1 | grep -Eq 'New, TLSv1.2|Protocol *: TLSv1.2'; }
hsts() { curl --noproxy '*' -ksSD - -o /dev/null --resolve "$HOST:443:$IP" "https://$HOST/" | grep -Eiq '^Strict-Transport-Security: *max-age=[0-9]+'; }
after() { [[ -s "$E/after.pcap" ]] && tshark -r "$E/after.pcap" -Y 'tls' -T fields -e frame.number 2>/dev/null | grep -q '[0-9]' && ! tshark -r "$E/after.pcap" -V 2>/dev/null | grep -Fq 'Latihan-05!'; }
cookie() { local h; h=$(curl --noproxy '*' -ksS -D - -o /dev/null --resolve "$HOST:443:$IP" -d 'username=admin_demo_05&password=Latihan-05!' "https://$HOST/login"); echo "$h" | grep -Ei '^Set-Cookie:' | grep -Eiq 'Secure' && echo "$h" | grep -Ei '^Set-Cookie:' | grep -Eiq 'HttpOnly' && echo "$h" | grep -Ei '^Set-Cookie:' | grep -Eiq 'SameSite='; }
flag 1 before
flag 2 leaked
flag 3 certname
flag 4 web
flag 5 chain
flag 6 redirect
flag 7 tls12
flag 8 hsts
flag 9 after
flag 10 cookie
