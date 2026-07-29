#!/bin/bash
# Ingest official sample AIP test data into DSpace 10
# Note: Ensure an admin account (test@test.edu) exists first

echo "Ingesting sample AIP test data..."
docker compose -p d10 -f docker/docker-compose-dist.yml -f docker/docker-compose-rest.yml -f docker-compose.override.yml -f docker/cli.yml -f docker/cli.ingest.yml run --rm dspace-cli
