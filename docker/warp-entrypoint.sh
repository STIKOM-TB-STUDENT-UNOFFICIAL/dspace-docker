#!/bin/bash
# =============================================================
# warp-entrypoint.sh
# Script startup untuk container Cloudflare WARP.
# Alur:
#   1. Jalankan warp-svc (daemon)
#   2. Daftarkan device ke WARP (jika belum terdaftar)
#   3. Set mode ke proxy (SOCKS5 di 0.0.0.0:1080)
#   4. Sambungkan ke WARP
#   5. Jalankan microsocks (SOCKS5 server) di foreground
# =============================================================
set -e

DATA_DIR="/var/lib/cloudflare-warp"
mkdir -p "$DATA_DIR"

echo "[WARP] Memulai warp-svc daemon..."
warp-svc &
WARP_SVC_PID=$!

# Tunggu daemon siap
sleep 5

# ── Registrasi (hanya sekali, data tersimpan di volume) ──────
if [ ! -f "$DATA_DIR/reg.json" ]; then
    echo "[WARP] Mendaftarkan device ke Cloudflare WARP..."
    warp-cli --accept-tos registration new
    # Simpan penanda agar tidak daftar ulang
    touch "$DATA_DIR/reg.json"
    sleep 2
else
    echo "[WARP] Device sudah terdaftar, melanjutkan..."
fi

# ── Set mode: proxy (SOCKS5 di port 1080) ────────────────────
echo "[WARP] Mengatur mode ke 'proxy' (SOCKS5 :1080)..."
warp-cli mode proxy
warp-cli proxy port 1080

# ── Sambungkan ───────────────────────────────────────────────
echo "[WARP] Menyambungkan ke Cloudflare WARP..."
warp-cli connect
sleep 5

# ── Tampilkan status ─────────────────────────────────────────
warp-cli status || true

# ── Jalankan SOCKS5 proxy (foreground) ───────────────────────
echo "[WARP] Menjalankan microsocks SOCKS5 di 0.0.0.0:1080..."
exec microsocks -i 0.0.0.0 -p 1080
