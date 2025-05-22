# CONDO DEPLOYMENT GUIDE FOR UBUNTU SERVER

This guide provides step-by-step instructions for deploying the Condo property management SaaS application on an Ubuntu server.

## SERVER REQUIREMENTS

- Ubuntu Server 20.04 LTS or newer
- At least 4GB RAM (8GB+ recommended)
- At least 20GB free disk space
- Public IP address with ports 80/443 open for web access

## 1. INITIAL SERVER SETUP

### Update system packages
```bash
sudo apt update && sudo apt upgrade -y
```

### Install required tools
```bash
sudo apt install -y curl git build-essential
```

## 2. INSTALL NODE.JS 16.x

```bash
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
```

### Verify Node.js installation
```bash
node -v  # Should show v16.x.x
```

### Install Yarn
```bash
npm install -g yarn@3.2.2
```

## 3. INSTALL PYTHON 3

```bash
sudo apt install -y python3 python3-pip
pip3 install Django psycopg2-binary
```

## 4. INSTALL POSTGRESQL 16

### Add PostgreSQL repository
```bash
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
```

### Install PostgreSQL
```bash
sudo apt install -y postgresql-16 postgresql-contrib-16
```

### Configure PostgreSQL
```bash
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE condo;"
sudo -u postgres psql -c "CREATE USER condouser WITH ENCRYPTED PASSWORD 'your_strong_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE condo TO condouser;"
sudo -u postgres psql -c "ALTER USER condouser WITH SUPERUSER;"
```

## 5. INSTALL REDIS

```bash
sudo apt install -y redis-server

# Configure Redis to start on boot
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

## 6. CLONE THE REPOSITORY

```bash
# Create a directory for the app
mkdir -p /opt/condo
cd /opt/condo

# Clone the repository
git clone https://github.com/open-condo-software/condo.git .
```

## 7. INSTALL PROJECT DEPENDENCIES

```bash
cd /opt/condo
yarn install
```

## 8. BUILD DEPENDENCIES

```bash
yarn workspace @app/condo build:deps
```

## 9. CONFIGURE ENVIRONMENT VARIABLES

Create environment file:

```bash
cp apps/condo/.env.example apps/condo/.env
```

Edit the .env file with your production settings:

```bash
nano apps/condo/.env
```

Important variables to configure:

```
# Database connection
DATABASE_URL=postgresql://condouser:your_strong_password@localhost:5432/condo

# Redis connection
REDIS_URL=redis://localhost:6379/0

# App secret key (generate a random string)
COOKIE_SECRET=your_random_secure_string

# Domain settings
SERVER_URL=https://your-domain.com
DOMAIN_NAME=your-domain.com

# File storage (local or S3)
FILE_FIELD_ADAPTER=local
LOCAL_FILE_STORAGE_DIR=/opt/condo/storage

# Set to production
NODE_ENV=production
```

## 10. RUN DATABASE MIGRATIONS

```bash
cd /opt/condo
yarn workspace @app/condo migrate
```

## 11. BUILD THE APPLICATION

```bash
cd /opt/condo
yarn workspace @app/condo build
```

## 12. SET UP PROCESS MANAGER (PM2)

```bash
# Install PM2
sudo npm install -g pm2

# Start the main application
cd /opt/condo
pm2 start "yarn workspace @app/condo start" --name condo-app

# Start the worker
pm2 start "yarn workspace @app/condo worker" --name condo-worker

# Save the PM2 configuration
pm2 save

# Set up PM2 to start on system boot
pm2 startup
```

## 13. SET UP NGINX AS REVERSE PROXY

### Install Nginx
```bash
sudo apt install -y nginx
```

### Create Nginx configuration
```bash
sudo nano /etc/nginx/sites-available/condo
```

Add the following configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:4006;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Increase max file upload size (if needed)
    client_max_body_size 20M;
}
```

### Enable the site and restart Nginx
```bash
sudo ln -s /etc/nginx/sites-available/condo /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## 14. SET UP SSL WITH CERTBOT

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

## 15. SECURITY CONSIDERATIONS

### Configure firewall
```bash
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### Set up regular backups
For database backups:
```bash
# Create a backup script
cat > /opt/condo/backup.sh << 'EOL'
#!/bin/bash
BACKUP_DIR="/opt/condo/backups"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y-%m-%d-%H-%M)
pg_dump -U condouser condo > "$BACKUP_DIR/condo-$DATE.sql"
# Keep only last 7 backups
ls -tp $BACKUP_DIR/*.sql | grep -v '/$' | tail -n +8 | xargs -I {} rm -- {}
EOL

# Make it executable
chmod +x /opt/condo/backup.sh

# Set up cron job to run daily
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/condo/backup.sh") | crontab -
```

## 16. MAINTENANCE COMMANDS

### Restart the application
```bash
pm2 restart condo-app condo-worker
```

### View logs
```bash
pm2 logs condo-app
pm2 logs condo-worker
```

### Update the application
```bash
cd /opt/condo
git pull
yarn install
yarn workspace @app/condo build:deps
yarn workspace @app/condo build
yarn workspace @app/condo migrate
pm2 restart condo-app condo-worker
```

## TROUBLESHOOTING

### If the app doesn't start
Check the logs:
```bash
pm2 logs condo-app
```

### If database migrations fail
```bash
cd /opt/condo
yarn workspace @app/condo migrate:unlock
yarn workspace @app/condo migrate
```

### If you need to reset the database
```bash
sudo -u postgres psql -c "DROP DATABASE condo;"
sudo -u postgres psql -c "CREATE DATABASE condo;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE condo TO condouser;"
cd /opt/condo
yarn workspace @app/condo migrate
```

### Check service status
```bash
systemctl status postgresql
systemctl status redis
systemctl status nginx
pm2 status
``` 