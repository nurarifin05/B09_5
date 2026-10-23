#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Gunakan sudo bash setup.sh'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl openssl nmap tcpdump tshark wireshark-common ca-certificates python3
install -m 755 "$(dirname "$0")/validate.sh" /usr/local/bin/sslctf-validate
install -m 755 "$(dirname "$0")/info.sh" /usr/local/bin/sslctf-info
USER_HOME="$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)"
install -d -m 755 "$USER_HOME/sslctf-evidence"
chown "${SUDO_USER:-root}" "$USER_HOME/sslctf-evidence"
if ! grep -Eq '^192\.168\.36\.247[[:space:]]+admin\.sibertaruna\.my\.id([[:space:]]|$)' /etc/hosts; then echo '192.168.36.247 admin.sibertaruna.my.id' >>/etc/hosts; fi
curl --noproxy '*' -fsS --max-time 6 http://192.168.36.247/health | grep -qx 'OK' || { echo 'ERROR: HTTP /health VM Windows tidak reachable; setup Kali belum READY.'; exit 1; }
echo 'READY: Kali WEB05 terpasang. Jalankan sslctf-info.'
