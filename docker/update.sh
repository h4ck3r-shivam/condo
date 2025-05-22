#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Pull the latest code from the repository
echo "Pulling the latest code from the repository..."
cd "$REPO_ROOT"
git pull
cd "$SCRIPT_DIR"

# Backup the database before updating
echo "Creating a database backup before updating..."
./backup.sh

# Rebuild containers
echo "Rebuilding containers..."
docker compose build condo-app condo-worker

# Run dependencies build and migrations
echo "Building dependencies..."
docker compose run --rm condo-app yarn workspace @app/condo build:deps

echo "Building the main application..."
docker compose run --rm condo-app yarn workspace @app/condo build

echo "Running database migrations..."
docker compose run --rm condo-app yarn workspace @app/condo migrate

# Restart containers
echo "Restarting containers..."
docker compose up -d

echo "Update completed successfully!" 