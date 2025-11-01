#!/bin/bash

# NOTE for Copilot and developers:
# This script intelligently rebuilds only when dependencies change.
# It checks if cpanfile or cpanfile.snapshot are newer than the last build.
# Rebuilds reinstall all Perl modules and are only needed when dependencies change.
#
# Usage:
#   ./restart.sh           # Smart restart (rebuild only if deps changed)
#   ./restart.sh --build   # Force rebuild
#   ./restart.sh --no-build # Skip build, just restart containers

# Stop, restart containers with intelligent rebuild detection,
# measure startup time, and check if Carton installs anything.

set -e  # exit on errors

echo "=== Travellers Palm Restart Script ==="

# Check for command line arguments
FORCE_BUILD=false
SKIP_BUILD=false

case "${1:-}" in
    --build|--force-build|-b)
        FORCE_BUILD=true
        echo "🔨 Force rebuild requested"
        ;;
    --no-build|--skip-build|-s)
        SKIP_BUILD=true
        echo "⚡ Skipping build, using existing images"
        ;;
    --help|-h)
        echo "Usage: $0 [--build|--no-build|--help]"
        echo "  --build     Force rebuild even if dependencies unchanged"
        echo "  --no-build  Skip build, just restart existing containers"
        echo "  --help      Show this help"
        exit 0
        ;;
    "")
        # Default behavior - smart detection
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

echo "Stopping and removing old containers..."
docker compose down

echo
echo "Starting containers (using cached images)..."
START_TIME=$(date +%s)

# Only rebuild if cpanfile or cpanfile.snapshot changed
NEEDS_REBUILD=false

if [ "$FORCE_BUILD" = true ]; then
    echo "🔨 Force rebuild requested via command line"
    NEEDS_REBUILD=true
elif [ "$SKIP_BUILD" = true ]; then
    echo "⚡ Build skipped via command line"
    NEEDS_REBUILD=false
elif [ ! -f .docker-deps-cache ]; then
    echo "🔍 No cache file found - first build required"
    NEEDS_REBUILD=true
elif [ cpanfile -nt .docker-deps-cache ]; then
    echo "🔍 cpanfile newer than cache - rebuild required"
    NEEDS_REBUILD=true
elif [ cpanfile.snapshot -nt .docker-deps-cache ]; then
    echo "🔍 cpanfile.snapshot newer than cache - rebuild required"
    NEEDS_REBUILD=true
else
    echo "🔍 Dependencies unchanged since last build"
    NEEDS_REBUILD=false
fi

if [ "$NEEDS_REBUILD" = true ]; then
    echo "📦 Building image with latest dependencies..."
    docker compose up --build -d
    touch .docker-deps-cache
    echo "💾 Cache file updated"
else
    echo "✅ Using cached image (no dependency changes detected)"
    docker compose up -d
fi

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
echo "💡 Dependencies are cached - next restart will be even faster if no cpanfile changes!"
