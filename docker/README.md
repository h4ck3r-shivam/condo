# Condo Docker Deployment

This directory contains all the necessary files to deploy the Condo property management system using Docker containers.

## Quick Start

1. Make your scripts executable:

```bash
chmod +x init.sh backup.sh restore.sh update.sh
```

2. Run the initialization script:

```bash
./init.sh
```

The script will:
- Create a `.env` file from `env.example` if it doesn't exist
- Build and start Docker containers
- Build application dependencies
- Run database migrations
- Start the Condo application

3. Access the application at http://localhost:3000 (or the port you configured)

## Available Scripts

### init.sh

Initialize and start the application. Run this when setting up for the first time.

```bash
./init.sh
```

### backup.sh

Create a database backup. Backups are stored in the `backups` directory.

```bash
./backup.sh
```

### restore.sh

Restore the database from a backup file.

```bash
./restore.sh backups/condo-YYYY-MM-DD-HH-MM.sql
```

### update.sh

Update the application to the latest version:
- Pull the latest code
- Create a backup
- Rebuild containers
- Run database migrations
- Restart containers

```bash
./update.sh
```

## Configuration

Edit the `.env` file to configure:
- Database credentials
- Application settings
- Admin credentials
- File storage options

## Maintenance

### View Logs

```bash
# View logs for a specific container
docker compose logs condo-app
docker compose logs condo-worker

# Follow logs in real-time
docker compose logs -f condo-app
```

### Restart Containers

```bash
# Restart all containers
docker compose restart

# Restart specific containers
docker compose restart condo-app condo-worker
```

### Access Container Shell

```bash
# Get a shell in the app container
docker compose exec condo-app /bin/bash
``` 