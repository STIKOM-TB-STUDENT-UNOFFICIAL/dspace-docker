#!/bin/bash
set -e

# Script untuk rebuild container dspace-angular jika menggunakan repo custom Git
echo ">> Rebuilding dspace-angular dari repo custom..."
docker compose build --build-arg CACHE_BUST=$(date +%s) dspace-angular
echo ">> Restarting dspace-angular container..."
docker compose up -d dspace-angular
echo ">> Rebuild selesai!"
