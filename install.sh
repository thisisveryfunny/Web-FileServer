#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FileServer Installation Script ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Nginx
echo -e "${YELLOW}Installing Nginx... (Please wait.)${NC}"
apt update > /dev/null 2>&1
apt install nginx -y > /dev/null 2>&1

# Check and install Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}Node.js is already installed: ${NODE_VERSION}${NC}"
else
    echo -e "${YELLOW}Node.js not found. Installing... (Please wait.)${NC}"
    apt install nodejs -y > /dev/null 2>&1
    if command_exists node; then
        echo -e "${GREEN}Node.js installed successfully: $(node --version)${NC}"
    else
        echo -e "${RED}Failed to install Node.js${NC}"
        exit 1
    fi
fi

# Check and install npm
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}npm is already installed: ${NPM_VERSION}${NC}"
else
    echo -e "${YELLOW}npm not found. Installing... (Please wait.)${NC}"
    apt install npm -y > /dev/null 2>&1
    if command_exists npm; then
        echo -e "${GREEN}npm installed successfully: $(npm --version)${NC}"
    else
        echo -e "${RED}Failed to install npm${NC}"
        exit 1
    fi
fi

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p /var/www/fileserver/backend
mkdir -p /var/www/fileserver/frontend
mkdir -p /srv/files

# Move frontend and backend
echo -e "${YELLOW}Setting up frontend and backend...${NC}"
mv ./frontend/* /var/www/fileserver/frontend/
mv ./backend/* /var/www/fileserver/backend/

# Install npm packages
echo -e "${YELLOW}Installing npm packages... (Please wait.)${NC}"
cd /var/www/fileserver/backend
npm init -y > /dev/null 2>&1
npm install express multer > /dev/null 2>&1

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chmod 755 -R /var/www/fileserver
chmod 755 -R /srv/files
chown www-data:www-data -R /var/www/fileserver
chown www-data:www-data -R /srv/files

# Create systemd service file
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/fileserver.service << 'EOF'
[Unit]
Description=FileServer Node.js Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/fileserver/backend
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=fileserver

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload > /dev/null 2>&1
systemctl enable fileserver > /dev/null 2>&1
echo -e "${GREEN}fileserver service created and enabled${NC}"

# Create Nginx configuration
echo -e "${YELLOW}Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/fileserver << 'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/fileserver/frontend;
    index index.html;

    client_max_body_size 10G;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/upload {
        proxy_pass http://127.0.0.1:3000/upload;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/files {
        proxy_pass http://127.0.0.1:3000/get-files;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/download {
        proxy_pass http://127.0.0.1:3000/download;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api/delete {
        proxy_pass http://127.0.0.1:3000/delete;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Enable site and remove default
ln -sf /etc/nginx/sites-available/fileserver /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
if nginx -t; then
    systemctl reload nginx > /dev/null 2>&1
    echo -e "${GREEN}Nginx configured and reloaded successfully${NC}"
else
    echo -e "${RED}Nginx configuration test failed${NC}"
    exit 1
fi

echo -e "${GREEN}=== Installation Complete ===${NC}"

echo -e "${YELLOW}Do you want to start the fileserver service now? (y/n)${NC}"
read -r START_SERVICE
if [[ "$START_SERVICE" == "y" || "$START_SERVICE" == "Y" ]]; then
    systemctl start fileserver > /dev/null 2>&1
    echo -e "${GREEN}Fileserver service started${NC}"
else
    echo -e "${YELLOW}You can start the service later with: sudo systemctl start fileserver${NC}"
fi
IP_ADDRESS=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)
echo -e "${YELLOW}Access the file server at: http://${IP_ADDRESS}/${NC}"
