#!/bin/bash
set -e

# Load environment variables jika file .env ada
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

echo "=========================================================="
echo "⚠️  PERINGATAN HARD FACTORY RESET DSPACE 10 DOCKER ⚠️"
echo "=========================================================="
echo "Proses ini akan:"
echo " 1. Menghentikan seluruh container DSpace"
echo " 2. MENGHAPUS SELURUH IMAGE Docker (rmi all)"
echo " 3. MENGHAPUS SELURUH VOLUME DATA (Database, Solr, File PDF)"
echo " 4. Men-download ulang image DSpace 10 bersih & menyalakan kembali"
echo "----------------------------------------------------------"
read -p "Apakah Anda YAKIN ingin melakukan Factory Reset total? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Proses Factory Reset dibatalkan."
  exit 0
fi

echo ">> 1. Menghentikan container, menghapus volume & image (down -v --rmi all)..."
docker compose down -v --rmi all --remove-orphans

echo ">> 2. Men-download ulang image DSpace 10 bersih..."
docker compose pull

echo ">> 3. Menyalakan kembali seluruh container DSpace 10 dari nol..."
docker compose up -d

echo ">> 4. Membuat akun Administrator default..."
./create-admin.sh

echo "=========================================================="
echo "✅ FACTORY RESET SELESAI!"
echo " Seluruh sistem DSpace 10 telah diset ulang ke kondisi awal."
echo "=========================================================="
