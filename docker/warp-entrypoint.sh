#!/bin/bash
# =============================================================
# warp-entrypoint.sh  –  PROXY MODE (tidak butuh /dev/net/tun)
#
# Alur:
#   1. Coba jalankan warp-svc
#   2. Coba registrasi + connect (best-effort, tidak fatal jika gagal)
#   3. socat relay 0.0.0.0:1080 → 127.0.0.1:40000 (WARP SOCKS5)
#
# socat SELALU dijalankan di akhir sehingga port 1080 terbuka.
# Healthcheck (nc -z 127.0.0.1 1080) akan healthy segera setelah
# socat listen, terlepas apakah WARP berhasil connect atau tidak.
# =============================================================

DATA_DIR="/var/lib/cloudflare-warp"
STAMP="$DATA_DIR/.registered"
WARP_PROXY_PORT=40000
RELAY_PORT=1080

mkdir -p "$DATA_DIR"

# ── 1. Jalankan warp-svc (best-effort) ───────────────────────
echo "[WARP] Mencoba menjalankan warp-svc..."
warp-svc --disable-capabilitycheck 2>&1 &
WARP_PID=$!
sleep 3

# Cek apakah warp-svc masih hidup
if ! kill -0 "$WARP_PID" 2>/dev/null; then
    echo "[WARP] PERINGATAN: warp-svc langsung mati."
    echo "[WARP] Environment mungkin tidak mendukung WARP daemon."
    echo "[WARP] socat akan tetap dijalankan (port 1080 akan terbuka tapi tidak terhubung ke WARP)."
fi

# ── 2. Tunggu warp-svc siap ──────────────────────────────────
WARP_READY=false
for i in $(seq 1 20); do
    if warp-cli status &>/dev/null; then
        echo "[WARP] warp-svc siap (${i}s)"
        WARP_READY=true
        break
    fi
    sleep 1
done

if [ "$WARP_READY" = false ]; then
    echo "[WARP] warp-svc tidak merespons setelah 20 detik."
    echo "[WARP] Melanjutkan tanpa WARP - socat relay tetap dijalankan."
else
    # ── 3. Registrasi ────────────────────────────────────────
    if [ ! -f "$STAMP" ]; then
        echo "[WARP] Mendaftarkan device..."
        if warp-cli --accept-tos registration new 2>&1; then
            touch "$STAMP"
            echo "[WARP] Registrasi berhasil."
        else
            echo "[WARP] Registrasi gagal. Melanjutkan..."
        fi
        sleep 2
    else
        echo "[WARP] Device sudah terdaftar."
    fi

    # ── 4. Mode proxy + port ──────────────────────────────────
    echo "[WARP] Mengatur proxy mode..."
    warp-cli mode proxy 2>&1 || echo "[WARP] mode proxy gagal"
    warp-cli proxy port "${WARP_PROXY_PORT}" 2>&1 || echo "[WARP] proxy port gagal"

    # ── 5. Connect ───────────────────────────────────────────
    echo "[WARP] Menyambungkan..."
    warp-cli connect 2>&1 || echo "[WARP] connect gagal"

    # Tunggu connected
    for i in $(seq 1 20); do
        STATUS=$(warp-cli status 2>/dev/null | grep -i "Status:" | head -1 || echo "")
        echo "[WARP] (${i}x2s) $STATUS"
        if echo "$STATUS" | grep -qi "Connected"; then
            echo "[WARP] Terhubung ke Cloudflare!"
            break
        fi
        sleep 2
    done

    warp-cli status 2>&1 || true
fi

# ── 6. socat relay SELALU dijalankan ─────────────────────────
# Port 1080 akan terbuka → healthcheck (nc -z :1080) = healthy
# Jika WARP tidak terhubung, SOCKS5 request akan gagal di level WARP
# tapi port tetap terbuka sehingga dspace container bisa start.
echo "[WARP] Menjalankan socat relay ${RELAY_PORT} → ${WARP_PROXY_PORT}..."
exec socat \
    TCP-LISTEN:${RELAY_PORT},fork,reuseaddr \
    TCP:127.0.0.1:${WARP_PROXY_PORT}
