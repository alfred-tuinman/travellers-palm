#!/bin/bash

# Comprehensive local development setup script
# Handles SASL modules and provides alternatives to Docker

set -e  # exit on errors

echo "=== Travellers Palm Local Development Setup ==="

# Function to check if running in WSL
check_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "📍 Running in WSL environment"
        return 0
    fi
    return 1
}

# Function to install system dependencies
install_system_deps() {
    echo "📦 Checking system dependencies..."
    
    if command -v apt-get &> /dev/null; then
        echo "   Installing SASL development libraries..."
        sudo apt-get update
        sudo apt-get install -y libsasl2-dev libsasl2-modules libssl-dev
        echo "   ✅ System dependencies installed"
    elif command -v yum &> /dev/null; then
        echo "   Installing SASL development libraries (RedHat/CentOS)..."
        sudo yum install -y cyrus-sasl-devel openssl-devel
        echo "   ✅ System dependencies installed"
    elif command -v brew &> /dev/null; then
        echo "   Installing SASL development libraries (macOS)..."
        brew install cyrus-sasl openssl
        echo "   ✅ System dependencies installed"
    else
        echo "   ⚠️  Could not detect package manager. You may need to install SASL libraries manually."
    fi
}

# Main installation function
install_dependencies() {
    echo "📦 Installing Perl dependencies with SASL workaround..."
    
    # Install carton if not present
    if ! command -v carton &> /dev/null; then
        echo "   Installing Carton..."
        cpanm --notest Carton
    fi
    
    # Install core dependencies (excluding SASL)
    echo "   Installing core dependencies..."
    carton install --without=develop --without=sasl
    
    # Try to install SASL modules separately
    echo "   Installing SASL modules (optional)..."
    
    # First try with system libraries
    export PERL_MM_USE_DEFAULT=1
    
    echo "     Attempting Authen::SASL::Perl..."
    if carton exec -- cpanm --force --notest Authen::SASL::Perl 2>/dev/null; then
        echo "     ✅ Authen::SASL::Perl installed"
    else
        echo "     ⚠️  Authen::SASL::Perl failed (optional)"
    fi
    
    echo "     Attempting Authen::SASL..."
    if carton exec -- cpanm --force --notest Authen::SASL 2>/dev/null; then
        echo "     ✅ Authen::SASL installed"
    else
        echo "     ⚠️  Authen::SASL failed (optional)"
    fi
    
    unset PERL_MM_USE_DEFAULT
}

# Function to check if dependencies are installed
check_dependencies() {
    echo "🔍 Checking if dependencies are installed..."
    
    # Check if carton is available
    if ! command -v carton &> /dev/null; then
        echo "❌ Carton not found. Dependencies not installed."
        return 1
    fi
    
    # Check if core modules are available
    if ! carton exec -- perl -MDBI -e 'print "DBI OK\n"' 2>/dev/null; then
        echo "❌ Core dependencies not installed (DBI missing)."
        return 1
    fi
    
    echo "✅ Dependencies appear to be installed"
    return 0
}

# Function to start the application
start_app() {
    echo "🚀 Starting Travellers Palm application..."
    echo "   Application will be available at: http://localhost:3000"
    echo "   Press Ctrl+C to stop"
    echo ""
    carton exec -- morbo -l http://*:3000 script/travellers_palm
}

# Main execution
case "${1:-install}" in
    "install"|"deps"|"dependencies")
        if check_wsl; then
            install_system_deps
        fi
        install_dependencies
        echo ""
        echo "✅ Setup complete!"
        echo ""
        echo "To start the application:"
        echo "   ./local-dev.sh start"
        echo "   or: carton exec -- morbo -l http://*:3000 script/travellers_palm"
        ;;
    "start"|"run")
        if ! check_dependencies; then
            echo ""
            echo "💡 Dependencies not installed. Installing now..."
            echo ""
            if check_wsl; then
                install_system_deps
            fi
            install_dependencies
            echo ""
            echo "✅ Dependencies installed! Starting application..."
            echo ""
        fi
        start_app
        ;;
    "full"|"setup")
        if check_wsl; then
            install_system_deps
        fi
        install_dependencies
        echo ""
        echo "🚀 Starting application after installation..."
        sleep 2
        start_app
        ;;
    *)
        echo "Usage: $0 [install|start|full]"
        echo ""
        echo "Commands:"
        echo "  install    - Install dependencies only"
        echo "  start      - Start the application (assumes deps are installed)"
        echo "  full       - Install dependencies and start application"
        echo ""
        echo "Examples:"
        echo "  ./local-dev.sh install    # Just install dependencies"
        echo "  ./local-dev.sh start      # Start the app"
        echo "  ./local-dev.sh full       # Do everything"
        ;;
esac