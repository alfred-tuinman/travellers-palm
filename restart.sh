#!/bin/bash

# Stop, rebuild, start containers, measure startup time,
# and check if Carton installs anything.

set -e  # exit on errors

echo "Stopping and removing old containers..."
docker compose down

echo
echo "Rebuilding and starting containers..."
START_TIME=$(date +%s)

docker compose up --build -d

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo
echo "✅ Containers started in ${ELAPSED} seconds."
echo "Current running containers:"
docker compose ps

# Check logs of travellers_palm_app for Carton activity
echo
echo "Checking if Carton ran during startup..."
if docker compose logs travellers_palm_app | grep -q "Carton snapshot changed\|installing modules"; then
    echo "⚠️ Carton install ran during startup!"
else
    echo "✅ No Carton install ran during startup, using cached modules."
fi

# Optional: show last few log lines for verification
echo
echo "Last 10 lines of travellers_palm_app logs:"
docker compose logs --tail=10 travellers_palm_app
