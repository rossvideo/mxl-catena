# Local Service Stack

A complete local development environment for the MXL Catena media infrastructure platform, featuring integrated services for media I/O, NDI conversion, and configuration management.

## Overview

This Docker Compose stack provides a fully functional local environment with:

| Service | Port | Purpose |
|---------|------|---------|
| **RPM (Platform Manager)** | 7280 | Web UI for managing media devices and configurations |
| **RPM Database** | 5432 | PostgreSQL database storing device and frame configurations |
| **MediaIO Engine** | 8180 | Core media I/O processing engine |
| **MediaIO Controller (Catena)** | 7248 | Catena protocol controller for media I/O |
| **NDI to MXL Sink** | 7269 | NDI to MXL video conversion service |
| **Python Proto Client** | N/A | gRPC client for service configuration and testing |

## Prerequisites

- Docker and Docker Compose installed
- 2GB+ available memory
- Shared memory support (`/dev/shm`)

## Quick Start

### Start All Services

```bash
docker compose up -d
```

This will:
- Start the PostgreSQL database with pre-loaded configurations
- Launch all media processing services
- Initialize database tables and device mappings

### Verify Services Are Running

```bash
docker compose ps
```

Expected output shows all services in `healthy` or `running` state.

### Stop All Services

```bash
docker compose down
```

To also remove volumes (database data):
```bash
docker compose down -v
```

## Service Details

### RPM (Ross Platform Manager)
- **Web UI**: http://localhost:7280
- **Database**: Initialized with 2 pre-configured OGP frames:
  - Media IO (port 7248 - Catena)
  - Catena NDI to MXL Sink (port 7269 - Catena)

### Database (PostgreSQL)
- **Purpose**: RPM

### MediaIO Engine
- **Port**: 8180
- **Configuration**: [`MediaIOSettings.json`](MediaIOSettings.json)
- **Data directory**: `./clips` (mounted to `/data`)
- **Shared memory**: `/dev/shm/mxl`

### Python Proto Client
- **Purpose**: gRPC-based st2138 service configuration injection
- **Build**: Automatic (on first run)
- **Dependencies**: Built after MIO Controller and NDI2MXL are healthys

## Resource Mounting

| Host Path | Container Path | Service | Purpose |
|-----------|-----------------|---------|---------|
| `./clips` | `/data` | media_io_engine, mio_controller | Media files and clips |
| `./MediaIOSettings.json` | `/root/Settings.json` | media_io_engine | Engine configuration |
| `./db_init.sql` | `/docker-entrypoint-initdb.d/00_db_init.sql` | rpm_database | Database initialization |

## Common Tasks

## Files Reference

- [`compose.yml`](compose.yml) - Docker Compose configuration
- [`db_init.sql`](db_init.sql) - Database initialization script
- [`MediaIOSettings.json`](MediaIOSettings.json) - MediaIO engine settings
- [`python-proto-client/`](python-proto-client/) - gRPC client for testing
- [`clips/`](clips/) - Media files directory
- [`images/`](images/) - Pre-built media images

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- Project README: [../readme.md](../readme.md)
- External documentation: [../external/readme.md](../external/readme.md)
