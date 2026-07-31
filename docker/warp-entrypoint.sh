#!/bin/bash
# =============================================================
# warp-entrypoint.sh  –  PROXY MODE (tidak butuh /dev/net/tun)
# Alur:
#   1. Jalankan warp-svc (daemon background)
#   2. Daftarkan device (hanya sekali, tersimpan di volume)
#   3. Set mode ke 'proxy' → warp-svc listen di 127.0.0.1:40000
#   4. Sambungkan ke Cloudflare WARP
#   5. socat relay: 0.0.0.0:1080 → 127.0.0.1:40000 (foreground)
#      sehingga container lain bisa akses via warp:1080
# =============================================================
set -e

DATA_DIR="/var/lib/cloudflare-warp"
STAMP="$DATA_DIR/.registered"
WARP_PROXY_PORT=40000   # port internal warp-svc
RELAY_PORT=1080         # port yang diakses container lain

mkdir -p "$DATA_DIR"

# ── 1. Jalankan warp-svc ─────────────────────────────────────
echo "[WARP] Memulai warp-svc daemon..."
warp-svc --disable-capabilitycheck &

# Tunggu daemon siap (poll status)
echo "[WARP] Menunggu warp-svc siap..."
for i in $(seq 1 30); do
    if warp-cli status &>/dev/null; then
        echo "[WARP] warp-svc siap (${i}s)"
        break
    fi
    sleep 1
done

# ── 2. Registrasi (hanya sekali) ─────────────────────────────
if [ ! -f "$STAMP" ]; then
    echo "[WARP] Mendaftarkan device ke Cloudflare WARP..."
    warp-cli --accept-tos registration new && touch "$STAMP"
    sleep 2
else
    echo "[WARP] Device sudah terdaftar."
fi

# ── 3. Mode proxy + set port ──────────────────────────────────
echo "[WARP] Mengatur mode proxy pada port ${WARP_PROXY_PORT}..."
warp-cli mode proxy
warp-cli proxy port "${WARP_PROXY_PORT}"

# ── 4. Sambungkan ────────────────────────────────────────────
echo "[WARP] Menyambungkan ke Cloudflare WARP..."
warp-cli connect

# Tunggu sampai Connected (max 60 detik)
for i in $(seq 1 30); do
    STATUS=$(warp-cli status 2>/dev/null | grep -i "Status:" | head -1 || echo "unknown")
    echo "[WARP] (${i}s) $STATUS"
    if echo "$STATUS" | grep -qi "Connected"; then
        echo "[WARP] Terhubung ke Cloudflare!"
        break
    fi
    sleep 2
done

warp-cli status || true

# ── 5. socat relay: 0.0.0.0:1080 → 127.0.0.1:40000 ──────────
# Membuat warp-svc SOCKS5 proxy dapat diakses dari container lain
echo "[WARP] Menjalankan socat relay ${RELAY_PORT} → ${WARP_PROXY_PORT}..."
exec socat \
    TCP-LISTEN:${RELAY_PORT},fork,reuseaddr \
    TCP:127.0.0.1:${WARP_PROXY_PORT}
