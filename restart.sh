#!/bin/bash

# This will stop all containers defined in your docker-compose.yml and emove them 
# and leave other containers (from other projects) untouched

set -e  # exit on errors

echo "Stopping and removing old containers..."
docker compose down

echo "Rebuilding and starting containers..."
docker compose up --build -d

echo "Done. Current running containers:"
docker compose ps

