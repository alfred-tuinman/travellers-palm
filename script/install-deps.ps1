# Local dependency installation script for Windows PowerShell
# This script handles problematic SASL modules the same way as our Dockerfile

Write-Host "=== Travellers Palm Local Dependency Installation ===" -ForegroundColor Green

# Check if carton is installed
try {
    carton --version | Out-Null
    Write-Host "✅ Carton is already installed"
} catch {
    Write-Host "📦 Installing Carton..." -ForegroundColor Yellow
    cpanm --notest Carton
}

Write-Host "📦 Installing core dependencies (excluding SASL modules)..." -ForegroundColor Yellow
carton install --without=develop --without=sasl

Write-Host "📦 Installing SASL modules separately (optional - failures are OK)..." -ForegroundColor Yellow

# Try to install SASL::Perl first
Write-Host "   Attempting Authen::SASL::Perl..." -ForegroundColor Cyan
try {
    carton exec -- cpanm --force --notest Authen::SASL::Perl
    Write-Host "   ✅ Authen::SASL::Perl installed successfully" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Authen::SASL::Perl failed (optional - continuing)" -ForegroundColor Yellow
}

# Try to install main SASL module
Write-Host "   Attempting Authen::SASL..." -ForegroundColor Cyan
try {
    carton exec -- cpanm --force --notest Authen::SASL
    Write-Host "   ✅ Authen::SASL installed successfully" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Authen::SASL failed (optional - continuing)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Dependency installation complete!" -ForegroundColor Green
Write-Host "💡 Core modules are installed. SASL modules are optional for email functionality." -ForegroundColor Blue
Write-Host ""
Write-Host "To start the application locally:" -ForegroundColor Cyan
Write-Host "   carton exec -- morbo -l http://*:3000 script/travellers_palm"
Write-Host ""
Write-Host "Or use Docker for development:" -ForegroundColor Cyan
Write-Host "   ./restart.sh"