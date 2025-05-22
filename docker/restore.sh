#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Error: Please provide the backup file path."
    echo "Usage: ./restore.sh backups/condo-YYYY-MM-DD-HH-MM.sql"
    exit 1
fi

# Check if the backup file exists
if [ ! -f "$1" ]; then
    echo "Error: Backup file not found: $1"
    exit 1
fi

echo "WARNING: This will overwrite the current database!"
echo "Are you sure you want to continue? (y/N): "
read -r confirmation

if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
    echo "Restore aborted."
    exit 0
fi

# Stop the application containers while keeping the database running
echo "Stopping application containers..."
docker compose stop condo-app condo-worker

# Restore the database
echo "Restoring database from backup: $1"
cat "$1" | docker compose exec -T postgres psql -U postgres condo

# Start the application containers again
echo "Starting application containers..."
docker compose start condo-app condo-worker

echo "Database restore completed successfully!" 