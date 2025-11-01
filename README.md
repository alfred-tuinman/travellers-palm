# Travellers Palm

A Mojolicious-based Perl web application for travel and hotel management.

## Quick Start

### Development (with hot reload)
```bash
carton exec -- morbo -l http://*:3000 script/travellers_palm
```

### Docker Compose
```bash
docker-compose up --build
```

### Testing
```bash
carton exec -- prove -lv t/
```

Or use the Docker test helpers:
- **Windows**: `.\bin\test-in-docker.ps1`
- **Linux/macOS/WSL**: `bash bin/test-in-docker.sh`

## Architecture

### Database Core Structure

The database layer is organized with infrastructure modules in the Core namespace:

- **Core Modules**:
  - `Database/Core/Connector.pm` - Database connection management
  - `Database/Core/Validation.pm` - Input validation utilities
  - `Database/Core/Initializer.pm` - Database initialization and seeding
- **Backward Compatibility**: Shims available at old paths for compatibility

### Validation System
Centralized validation utility with comprehensive input validation:
- String length and required checks
- Integer format and range validation
- Whitelist-based filter validation
- Safe ORDER BY column validation
- Array element validation with callbacks

Applied to all database modules (Cities, Users, Images, etc.) with:
- SQL injection protection
- Graceful error handling
- Clear error messages
- Consistent validation patterns

### Testing Infrastructure
- Added Docker test helpers for cross-platform development
- Full test suite compatibility with Docker environment

## Project Structure

- **Entry Point**: `script/travellers_palm` and `lib/TravellersPalm.pm`
- **Modules**: `lib/TravellersPalm/` (Logger, Mailer, Helpers, Hooks, Routes, Database)
- **Templates**: Template Toolkit (`*.tt`) files in `templates/`
- **Static Assets**: `public/`
- **Configuration**: `config.yml`
- **Database Seeds**: `localdb/` (copied to `data/` on startup)

## Dependencies

- **Perl**: Mojolicious framework
- **Database**: SQLite (seeded from CSV files)
- **Templates**: Template Toolkit
- **Package Management**: Carton
- **Containerization**: Docker & Docker Compose

## Documentation

Comprehensive documentation is available in the [`docs/`](docs/) directory:

- 📖 **[Getting Started](docs/1.%20GETTING%20STARTED.md)** - Installation and setup
- 🛠️ **[Development](docs/2.%20DEVELOPMENT.md)** - Development workflow and architecture
- ⚙️ **[Configuration](docs/3.%20CONFIGURATION.md)** - Configuration reference
- 📧 **[Email System](docs/4.%20EMAIL%20SYSTEM.md)** - Email notification system

## License

This software is proprietary and confidential. It is intended for internal use only within the organization.

All rights reserved. No part of this software may be reproduced, distributed, or transmitted in any form without prior written permission.