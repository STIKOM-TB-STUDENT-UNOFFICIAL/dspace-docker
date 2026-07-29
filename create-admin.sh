#!/bin/bash
# Create Administrator user in DSpace 10
# Usage: ./create-admin.sh [email] [firstname] [lastname] [password]

EMAIL="${1:-test@test.edu}"
FIRSTNAME="${2:-admin}"
LASTNAME="${3:-user}"
PASSWORD="${4:-admin}"

echo "Creating Administrator account ($EMAIL)..."
docker compose -f docker-compose.yml -f docker/cli.yml run --rm dspace-cli create-administrator -e "$EMAIL" -f "$FIRSTNAME" -l "$LASTNAME" -p "$PASSWORD" -c en