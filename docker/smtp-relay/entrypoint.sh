#!/bin/bash
# =============================================================
# entrypoint.sh untuk smtp-relay
# Menerima SMTP di port 25 (lokal Docker), forward via
# proxychains4 + msmtp → WARP SOCKS5 → smtp.gmail.com
# =============================================================
set -e

SMTP_USER="${SMTP_USER:-user@gmail.com}"
SMTP_PASS="${SMTP_PASS:-app-password}"
SMTP_FROM="${SMTP_FROM:-noreply@example.com}"
SMTP_HOST="${SMTP_HOST:-smtp.gmail.com}"
SMTP_PORT="${SMTP_PORT:-587}"

echo "[RELAY] Menulis konfigurasi msmtp..."
cat > /etc/msmtprc << EOF
defaults
auth           on
tls            on
tls_starttls   on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        -

account        default
host           ${SMTP_HOST}
port           ${SMTP_PORT}
from           ${SMTP_FROM}
user           ${SMTP_USER}
password       ${SMTP_PASS}
EOF
chmod 600 /etc/msmtprc

echo "[RELAY] Menunggu WARP proxy siap di warp:1080..."
for i in $(seq 1 30); do
    if nc -z warp 1080 2>/dev/null; then
        echo "[RELAY] WARP proxy siap (${i}s)"
        break
    fi
    sleep 2
done

echo "[RELAY] Menjalankan SMTP relay server di 0.0.0.0:25..."
echo "[RELAY]   DSpace → smtp-relay:25 → proxychains → WARP → ${SMTP_HOST}:${SMTP_PORT}"

exec python3 /smtp_server.py
