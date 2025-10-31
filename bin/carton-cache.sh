#!/bin/bash

# Carton cache management utility for Travellers Palm

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CARTON_CACHE_DIR="$PROJECT_ROOT/carton_cache"
SNAPSHOT_FILE="$CARTON_CACHE_DIR/cpanfile.snapshot"

usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    status      Show current snapshot status
    install     Run carton install locally and update cache
    clean       Remove carton cache
    copy-from   Copy snapshot from local directory to cache
    help        Show this help

This script helps manage the carton cache for consistent Docker builds.
EOF
}

status() {
    echo "=== Carton Cache Status ==="
    echo "Cache directory: $CARTON_CACHE_DIR"
    
    if [ -d "$CARTON_CACHE_DIR" ]; then
        echo "✅ Cache directory exists"
        
        if [ -f "$SNAPSHOT_FILE" ]; then
            echo "✅ cpanfile.snapshot found"
            SIZE=$(stat -f%z "$SNAPSHOT_FILE" 2>/dev/null || stat -c%s "$SNAPSHOT_FILE" 2>/dev/null || echo "unknown")
            MODIFIED=$(stat -f%Sm "$SNAPSHOT_FILE" 2>/dev/null || stat -c%y "$SNAPSHOT_FILE" 2>/dev/null || echo "unknown")
            echo "   Size: $SIZE bytes"
            echo "   Modified: $MODIFIED"
        else
            echo "❌ cpanfile.snapshot missing"
        fi
    else
        echo "❌ Cache directory missing"
    fi
    
    # Check if snapshot exists in project root
    if [ -f "$PROJECT_ROOT/cpanfile.snapshot" ]; then
        echo "ℹ️  Found cpanfile.snapshot in project root"
    fi
}

install_local() {
    echo "=== Running local carton install ==="
    
    cd "$PROJECT_ROOT"
    
    if ! command -v carton >/dev/null 2>&1; then
        echo "❌ carton command not found. Install with: cpanm Carton"
        exit 1
    fi
    
    echo "Running carton install..."
    if carton install --without=develop; then
        echo "✅ carton install completed"
        
        if [ -f "cpanfile.snapshot" ]; then
            mkdir -p "$CARTON_CACHE_DIR"
            cp "cpanfile.snapshot" "$CARTON_CACHE_DIR/"
            echo "✅ Copied cpanfile.snapshot to cache"
        else
            echo "⚠️  No cpanfile.snapshot created"
        fi
    else
        echo "❌ carton install failed"
        exit 1
    fi
}

clean_cache() {
    echo "=== Cleaning carton cache ==="
    
    if [ -d "$CARTON_CACHE_DIR" ]; then
        rm -rf "$CARTON_CACHE_DIR"
        echo "✅ Removed cache directory"
    else
        echo "ℹ️  Cache directory doesn't exist"
    fi
}

copy_from_root() {
    echo "=== Copying snapshot from project root ==="
    
    if [ -f "$PROJECT_ROOT/cpanfile.snapshot" ]; then
        mkdir -p "$CARTON_CACHE_DIR"
        cp "$PROJECT_ROOT/cpanfile.snapshot" "$CARTON_CACHE_DIR/"
        echo "✅ Copied cpanfile.snapshot to cache"
    else
        echo "❌ No cpanfile.snapshot found in project root"
        exit 1
    fi
}

case "${1:-status}" in
    status)
        status
        ;;
    install)
        install_local
        ;;
    clean)
        clean_cache
        ;;
    copy-from)
        copy_from_root
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac