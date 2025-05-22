#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create backup directory
BACKUP_DIR="./backups"
mkdir -p $BACKUP_DIR

# Generate timestamp for the backup file
DATE=$(date +%Y-%m-%d-%H-%M)

# Backup PostgreSQL database
echo "Creating database backup..."
docker compose exec -T postgres pg_dump -U postgres condo > "$BACKUP_DIR/condo-$DATE.sql"
echo "Database backup created: $BACKUP_DIR/condo-$DATE.sql"

# Keep only the last 7 backups
echo "Cleaning up old backups..."
ls -tp $BACKUP_DIR/*.sql | grep -v '/$' | tail -n +8 | xargs -I {} rm -- {}
echo "Backup process completed successfully!" 