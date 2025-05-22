#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if .env file exists, if not, create it from the example
if [ ! -f .env ]; then
    echo "Creating .env file from env.example..."
    cp env.example .env
    echo "Please edit the .env file with your actual settings before continuing."
    echo "Press Enter to continue or Ctrl+C to abort..."
    read
fi

# Build and start the Docker containers
echo "Building Condo dependencies..."
docker compose build

echo "Starting database containers..."
docker compose up -d postgres redis

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 10

# Build dependencies and run migrations
echo "Building application dependencies..."
docker compose run --rm condo-app yarn workspace @app/condo build:deps

echo "Building the main application..."
docker compose run --rm condo-app yarn workspace @app/condo build

echo "Running database migrations..."
docker compose run --rm condo-app yarn workspace @app/condo migrate

# Start all containers
echo "Starting all containers..."
docker compose up -d

# Print access information
PORT=$(grep "^PORT=" .env | cut -d'=' -f2 || echo "3000")
echo ""
echo "==================================================="
echo "Condo application is now running!"
echo "Access the application at: http://localhost:${PORT}"
echo "Admin login: $(grep "^DEFAULT_TEST_ADMIN_IDENTITY=" .env | cut -d'=' -f2)"
echo "Admin password: $(grep "^DEFAULT_TEST_ADMIN_SECRET=" .env | cut -d'=' -f2)"
echo "===================================================" 