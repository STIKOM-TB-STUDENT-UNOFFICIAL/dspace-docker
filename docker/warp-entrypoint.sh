#!/bin/bash
# =============================================================
# warp-entrypoint.sh
# Alur:
#   1. Jalankan warp-svc (daemon background)
#   2. Daftarkan device (hanya sekali, tersimpan di volume)
#   3. Set mode ke 'warp' (full VPN via TUN interface)
#   4. Sambungkan ke Cloudflare WARP
#   5. Jalankan microsocks di 0.0.0.0:1080 (foreground)
#      -> microsocks buat koneksi langsung, otomatis lewat TUN WARP
# =============================================================
set -e

DATA_DIR="/var/lib/cloudflare-warp"
STAMP="$DATA_DIR/.registered"
mkdir -p "$DATA_DIR"

# ── 1. Pastikan TUN tersedia ─────────────────────────────────
if [ ! -c /dev/net/tun ]; then
    echo "[WARP] ERROR: /dev/net/tun tidak tersedia!"
    echo "       Tambahkan 'devices: - /dev/net/tun:/dev/net/tun' di docker-compose.yml"
    exit 1
fi

echo "[WARP] Memulai warp-svc daemon..."
warp-svc --disable-capabilitycheck &
WARP_SVC_PID=$!

# Tunggu daemon siap (cek socket-nya)
for i in $(seq 1 20); do
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

# ── 3. Set mode ke 'warp' (full VPN lewat TUN) ───────────────
echo "[WARP] Mengatur mode ke 'warp' (bukan proxy - hindari port conflict)..."
warp-cli mode warp

# ── 4. Sambungkan ────────────────────────────────────────────
echo "[WARP] Menyambungkan ke Cloudflare WARP..."
warp-cli connect

# Tunggu sampai status Connected
for i in $(seq 1 30); do
    STATUS=$(warp-cli status 2>/dev/null | grep -i "status" | head -1 || echo "unknown")
    echo "[WARP] Status (${i}s): $STATUS"
    if echo "$STATUS" | grep -qi "Connected"; then
        echo "[WARP] Terhubung ke Cloudflare!"
        break
    fi
    sleep 2
done

warp-cli status || true

# ── 5. Jalankan microsocks di semua interface ─────────────────
# microsocks buat koneksi direct -> otomatis lewat TUN WARP
echo "[WARP] Menjalankan microsocks SOCKS5 di 0.0.0.0:1080..."
exec microsocks -i 0.0.0.0 -p 1080

