#!/bin/bash

APP_CONTAINER=travellers_palm_app

echo "Stopping the app container..."
docker compose stop $APP_CONTAINER

echo
echo "Starting the app container..."
START_TIME=$(date +%s)

docker compose start $APP_CONTAINER

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo
echo "✅ Container '$APP_CONTAINER' restarted in ${ELAPSED} seconds."

echo
echo "Current running containers:"
docker compose ps

# Optional: check for Carton install messages
echo
if docker compose logs $APP_CONTAINER | grep -q "Carton snapshot changed\|installing modules"; then
    echo "⚠️ Carton install ran (unexpected!)"
else
    echo "✅ No Carton install ran, modules are cached."
fi
