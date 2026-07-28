#!/bin/bash
set -e

PROJECT_PREFIX="dspace-docker"
DB_CONTAINER="dspacedb"
DB_USER="dspace"
DB_NAME="dspace"

if [ -z "$1" ]; then
  echo "Cara pakai: ./restore.sh <folder_backup>"
  echo "Contoh   : ./restore.sh ./backup/20260728_120000"
  exit 1
fi

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Folder backup tidak ditemukan: $BACKUP_DIR"
  exit 1
fi

echo ">> Restore dari: $BACKUP_DIR"
read -p ">> Ini akan MENIMPA data yang ada sekarang. Lanjut? (y/n) " confirm
if [ "$confirm" != "y" ]; then
  echo "Dibatalkan."
  exit 0
fi

if [ -f "$BACKUP_DIR/dspace.sql" ]; then
  echo ">> Restore database..."
  docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" "$DB_NAME"
  cat "$BACKUP_DIR/dspace.sql" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" "$DB_NAME"
else
  echo "!! dspace.sql tidak ditemukan, skip restore database"
fi

if [ -f "$BACKUP_DIR/solr.tar.gz" ]; then
  echo ">> Restore Solr volume..."
  docker run --rm \
    -v "${PROJECT_PREFIX}_dspace_solr":/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine sh -c "rm -rf /data/* && tar xzf /backup/solr.tar.gz -C /data"
else
  echo "!! solr.tar.gz tidak ditemukan, skip restore solr"
fi

if [ -f "$BACKUP_DIR/assetstore.tar.gz" ]; then
  echo ">> Restore Assetstore volume..."
  docker run --rm \
    -v "${PROJECT_PREFIX}_dspace_assetstore":/data \
    -v "$(pwd)/$BACKUP_DIR":/backup \
    alpine sh -c "rm -rf /data/* && tar xzf /backup/assetstore.tar.gz -C /data"
else
  echo "!! assetstore.tar.gz tidak ditemukan, skip restore assetstore"
fi

echo ">> Restore selesai. Restart container backend/solr agar perubahan terbaca:"
echo "   docker compose restart dspace-backend dspacesolr"