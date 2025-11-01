# Dependency Installation Guide

This project has multiple ways to handle dependencies, especially dealing with problematic SASL modules for email functionality.

## Quick Start Options

### Option 1: Docker (Recommended)
```bash
# Uses Docker with pre-configured SASL workarounds
./restart.sh
```

### Option 2: Local Development (Windows/WSL)
```powershell
# Windows PowerShell
.\install-deps.ps1

# Then start the app
carton exec -- morbo -l http://*:3000 script/travellers_palm
```

### Option 3: Local Development (Linux/macOS)
```bash
# Install dependencies with SASL workaround
./local-dev.sh install

# Start the application
./local-dev.sh start

# Or do both in one command
./local-dev.sh full
```

## The SASL Problem

The `Authen::SASL` modules are required for Gmail SMTP authentication but can be difficult to install due to system library dependencies. Our solutions:

### Docker Solution (Dockerfile)
- Installs system SASL libraries first
- Uses `--without sasl` to install core dependencies
- Separately installs SASL modules with `--force --notest`
- Allows SASL installation to fail gracefully

### Local Solution (install-deps scripts)
- Checks for system SASL libraries
- Mimics the Docker installation strategy
- Provides clear feedback on what succeeded/failed
- Application will work without SASL (email features disabled)

## Troubleshooting

### "Module 'Authen::SASL' is not installed" Error

This happens when running standard `carton install` without our workarounds.

**Solutions:**
1. Use our custom scripts: `./install-deps.sh` or `.\install-deps.ps1`
2. Use Docker: `./restart.sh`
3. Install system libraries first:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libsasl2-dev libsasl2-modules libssl-dev
   
   # Then run our install script
   ./install-deps.sh
   ```

### Email Not Working

If SASL modules failed to install:
- Application will still run
- Error notifications will be logged but not emailed
- Check logs for "SASL modules loaded successfully" message

### Dependencies Keep Reinstalling

- Docker: Dependencies are cached in layers. Only rebuilds when cpanfile changes.
- Local: Use `carton install` only when dependencies change

## Files Involved

- `cpanfile` - Lists all dependencies including SASL
- `cpanfile.snapshot` - Locks dependency versions
- `Dockerfile` - Docker build with SASL workarounds
- `install-deps.sh` / `install-deps.ps1` - Local installation scripts
- `local-dev.sh` - Comprehensive local development script
- `restart.sh` - Docker-based restart script