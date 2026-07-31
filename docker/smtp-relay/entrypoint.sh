#!/bin/bash
# =============================================================
# entrypoint.sh untuk smtp-relay
# Menjalankan SMTP server lokal (Python) yang menerima koneksi
# dari DSpace di port 25, lalu meneruskan via msmtp+proxychains
# ke smtp.gmail.com melalui WARP SOCKS5.
# =============================================================
set -e

# Kredensial dari environment variable (di-set di local.cfg atau compose)
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
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        -

account        default
host           ${SMTP_HOST}
port           ${SMTP_PORT}
from           ${SMTP_FROM}
user           ${SMTP_USER}
password       ${SMTP_PASS}
tls_starttls   on
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

echo "[RELAY] Menjalankan SMTP server lokal di port 25..."
echo "[RELAY]   - Menerima email dari DSpace → forward via WARP → ${SMTP_HOST}:${SMTP_PORT}"

# Python SMTP server sederhana yang meneruskan via msmtp+proxychains
exec python3 - << 'PYEOF'
import asyncio
import subprocess
import sys
import logging
from email import message_from_bytes
from aiosmtpd.controller import Controller
from aiosmtpd.handlers import BaseHandler

logging.basicConfig(level=logging.INFO, format='[RELAY] %(message)s')
log = logging.getLogger()

class WarpForwardHandler(BaseHandler):
    async def handle_DATA(self, server, session, envelope):
        log.info(f"Email dari {envelope.mail_from} ke {', '.join(envelope.rcpt_tos)}")
        try:
            result = subprocess.run(
                ['proxychains4', '-q', 'msmtp', '--read-envelope-from', '-t'],
                input=envelope.content,
                capture_output=True,
                timeout=30
            )
            if result.returncode == 0:
                log.info("Email berhasil dikirim via WARP!")
                return '250 OK'
            else:
                log.error(f"msmtp error: {result.stderr.decode()}")
                return f'554 Gagal kirim: {result.stderr.decode()[:100]}'
        except subprocess.TimeoutExpired:
            log.error("Timeout saat mengirim email")
            return '554 Timeout'
        except Exception as e:
            log.error(f"Error: {e}")
            return f'554 Error: {str(e)[:100]}'

async def main():
    handler = WarpForwardHandler()
    controller = Controller(handler, hostname='0.0.0.0', port=25)
    controller.start()
    log.info("SMTP relay siap di 0.0.0.0:25")
    log.info("DSpace harus set: mail.server=smtp-relay, mail.server.port=25")
    try:
        await asyncio.Event().wait()
    except KeyboardInterrupt:
        pass
    finally:
        controller.stop()

# Install aiosmtpd jika belum ada
try:
    import aiosmtpd
except ImportError:
    import subprocess as sp
    sp.run([sys.executable, '-m', 'pip', 'install', 'aiosmtpd', '-q'], check=True)
    import aiosmtpd
    from aiosmtpd.controller import Controller
    from aiosmtpd.handlers import BaseHandler

asyncio.run(main())
PYEOF
