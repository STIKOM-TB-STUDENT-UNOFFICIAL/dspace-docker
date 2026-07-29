#!/bin/bash
set -e

# Load environment variables jika file .env ada
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

PROJECT_PREFIX="${COMPOSE_PROJECT_NAME:-d10}"
DB_CONTAINER="dspacedb"
DB_USER="${POSTGRES_USER:-dspace}"
DB_NAME="${POSTGRES_DB:-dspace}"

BACKUP_DIR="./backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo ">> Backup ke: $BACKUP_DIR (Project Prefix: $PROJECT_PREFIX)"

echo ">> Dumping database..."
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/dspace.sql"

echo ">> Backup Solr volume..."
docker run --rm \
  -v "${PROJECT_PREFIX}_solr_data":/data \
  -v "$(pwd)/$BACKUP_DIR":/backup \
  alpine tar czf /backup/solr.tar.gz -C /data .

echo ">> Backup Assetstore volume..."
docker run --rm \
  -v "${PROJECT_PREFIX}_assetstore":/data \
  -v "$(pwd)/$BACKUP_DIR":/backup \
  alpine tar czf /backup/assetstore.tar.gz -C /data .

echo ">> Selesai. File backup ada di: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"