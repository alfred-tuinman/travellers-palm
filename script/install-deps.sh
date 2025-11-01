#!/bin/bash

# Local dependency installation script that mimics Docker SASL handling
# This script handles problematic SASL modules the same way as our Dockerfile

set -e  # exit on errors

echo "=== Travellers Palm Local Dependency Installation ==="

# Check if carton is installed
if ! command -v carton &> /dev/null; then
    echo "📦 Installing Carton..."
    cpanm --notest Carton
fi

echo "📦 Installing core dependencies (excluding SASL modules)..."
carton install --without=develop --without=sasl

echo "📦 Installing SASL modules separately (optional - failures are OK)..."

# Try to install SASL::Perl first
echo "   Attempting Authen::SASL::Perl..."
if carton exec -- cpanm --force --notest Authen::SASL::Perl; then
    echo "   ✅ Authen::SASL::Perl installed successfully"
else
    echo "   ⚠️  Authen::SASL::Perl failed (optional - continuing)"
fi

# Try to install main SASL module
echo "   Attempting Authen::SASL..."
if carton exec -- cpanm --force --notest Authen::SASL; then
    echo "   ✅ Authen::SASL installed successfully"
else
    echo "   ⚠️  Authen::SASL failed (optional - continuing)"
fi

echo
echo "✅ Dependency installation complete!"
echo "💡 Core modules are installed. SASL modules are optional for email functionality."
echo
echo "To start the application locally:"
echo "   carton exec -- morbo -l http://*:3000 script/travellers_palm"
echo
echo "Or use Docker for development:"
echo "   ./restart.sh"