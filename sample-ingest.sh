#!/bin/bash
# Ingest official sample AIP test data into DSpace 10
# Note: Ensure an admin account (test@test.edu) exists first

echo "Ingesting sample AIP test data..."
docker compose -f docker-compose.yml -f docker/cli.yml -f docker/cli.ingest.yml run --rm dspace-cli
