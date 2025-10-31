#!/bin/bash

# Stop, rebuild, start containers, measure startup time,
# and check if Carton installs anything.

set -e  # exit on errors

echo "=== Travellers Palm Restart Script ==="

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

# Check logs for carton activity
echo
echo "Checking build logs for carton activity..."
CARTON_LOGS=$(docker compose logs travellers_palm_app | grep -i "successfully installed" || true)
if [ -n "$CARTON_LOGS" ]; then
    INSTALL_COUNT=$(echo "$CARTON_LOGS" | wc -l)
    echo "📦 First build: installed $INSTALL_COUNT modules (creating Docker-compatible snapshot)"
    echo "   Next builds will be much faster using Docker layer caching!"
else
    echo "✅ No modules installed - using cached Docker layer (super fast!)"
fi

echo
echo "Last 5 lines of app logs:"
docker compose logs --tail=5 travellers_palm_app

echo
echo "=== Restart complete ==="
echo "Application should be available at: http://localhost:3000"
echo
echo "💡 Run ./restart.sh again to see Docker layer caching in action!"
