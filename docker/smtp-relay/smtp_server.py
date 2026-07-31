#!/usr/bin/env python3
"""
smtp_server.py — SMTP relay server untuk dspace-smtp-relay container.
Menerima email dari DSpace di port 25 (lokal Docker),
meneruskan via proxychains4 + msmtp → WARP SOCKS5 → smtp.gmail.com
"""
import asyncio
import subprocess
import logging

from aiosmtpd.controller import Controller
from aiosmtpd.handlers import BaseHandler

logging.basicConfig(
    level=logging.INFO,
    format='[RELAY] %(asctime)s %(message)s',
    datefmt='%H:%M:%S'
)
log = logging.getLogger()


class WarpForwardHandler(BaseHandler):
    async def handle_DATA(self, server, session, envelope):
        recipients = ', '.join(envelope.rcpt_tos)
        log.info(f"Email: {envelope.mail_from} → {recipients} ({len(envelope.content)} bytes)")
        try:
            result = subprocess.run(
                ['proxychains4', '-q', 'msmtp', '--read-envelope-from', '-t'],
                input=envelope.content,
                capture_output=True,
                timeout=30
            )
            if result.returncode == 0:
                log.info("✓ Email berhasil dikirim via WARP!")
                return '250 OK'
            else:
                err = result.stderr.decode(errors='replace').strip()
                log.error(f"✗ msmtp gagal (exit {result.returncode}): {err}")
                return f'554 Delivery failed: {err[:120]}'
        except subprocess.TimeoutExpired:
            log.error("✗ Timeout (30s) saat mengirim email")
            return '554 Timeout sending message'
        except Exception as exc:
            log.error(f"✗ Exception: {exc}")
            return f'554 Internal error: {str(exc)[:100]}'


async def main():
    handler = WarpForwardHandler()
    controller = Controller(handler, hostname='0.0.0.0', port=25)
    controller.start()
    log.info("SMTP relay siap di 0.0.0.0:25")
    log.info("DSpace harus pakai: mail.server=smtp-relay, mail.server.port=25")
    try:
        await asyncio.Event().wait()
    except (KeyboardInterrupt, SystemExit):
        pass
    finally:
        controller.stop()


if __name__ == '__main__':
    asyncio.run(main())
