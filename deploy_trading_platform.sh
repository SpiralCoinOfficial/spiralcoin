#!/bin/bash
# SpiralCoin Trading Platform Deployment Script
# This script deploys the professional trading platform to spiralcoin.net

set -e

echo "🚀 SpiralCoin Trading Platform Deployment"
echo "========================================="

# Configuration - Update these values for your deployment
DOMAIN="${DOMAIN:-spiralcoin.net}"
WWW_DOMAIN="${WWW_DOMAIN:-www.spiralcoin.net}"
SERVER_IP="${SERVER_IP:-127.0.0.1}"
SSH_USER="${SSH_USER:-root}"
SSH_PORT="${SSH_PORT:-22}"
REMOTE_PATH="${REMOTE_PATH:-/var/www/spiralcoin.net}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if domain is configured
check_domain() {
    echo -e "${YELLOW}Checking domain configuration...${NC}"

    # Check if domains resolve to server IP
    DOMAIN_IP=$(dig +short $DOMAIN 2>/dev/null || echo "")
    WWW_DOMAIN_IP=$(dig +short $WWW_DOMAIN 2>/dev/null || echo "")

    if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
        echo -e "${RED}Warning: $DOMAIN does not resolve to $SERVER_IP${NC}"
        echo -e "${YELLOW}Current IP: $DOMAIN_IP${NC}"
    fi

    if [ "$WWW_DOMAIN_IP" != "$SERVER_IP" ]; then
        echo -e "${RED}Warning: $WWW_DOMAIN does not resolve to $SERVER_IP${NC}"
        echo -e "${YELLOW}Current IP: $WWW_DOMAIN_IP${NC}"
    fi

    echo -e "${GREEN}Domain check complete${NC}"
}

# Setup nginx configuration
setup_nginx() {
    echo -e "${YELLOW}Setting up nginx configuration...${NC}"

    # Create nginx site configuration
    cat > spiralcoin.net.conf << 'EOF'
server {
    listen 80;
    server_name spiralcoin.net www.spiralcoin.net;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name spiralcoin.net www.spiralcoin.net;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/spiralcoin.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spiralcoin.net/privkey.pem;

    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Root directory
    root /var/www/spiralcoin.net;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Static file caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API proxy to local services (port 5000)
    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Market feed proxy (port 4000)
    location /feed/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support for market feed
    location /ws {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Main location
    location / {
        try_files $uri $uri/ /index.html;

        # Disable access to hidden files
        location ~ /\. {
            deny all;
        }
    }

    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF

    echo -e "${GREEN}Nginx configuration created${NC}"
}

# Deploy files to server
deploy_files() {
    echo -e "${YELLOW}Deploying files to server...${NC}"

    # Create remote directory
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo mkdir -p $REMOTE_PATH"

    # Copy trading platform files
    scp -P $SSH_PORT trading_platform.html $SSH_USER@$SERVER_IP:$REMOTE_PATH/index.html

    # Create additional pages
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "cat > $REMOTE_PATH/404.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Page Not Found - SpiralCoin</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #0f0f23; color: white; }
        h1 { color: #ffcc00; }
        a { color: #ffcc00; text-decoration: none; }
    </style>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
    <a href="/">Return to Trading Platform</a>
</body>
</html>
EOF

    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "cat > $REMOTE_PATH/50x.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Server Error - SpiralCoin</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #0f0f23; color: white; }
        h1 { color: #ffcc00; }
        a { color: #ffcc00; text-decoration: none; }
    </style>
</head>
<body>
    <h1>Server Error</h1>
    <p>We're experiencing technical difficulties. Please try again later.</p>
    <a href="/">Return to Trading Platform</a>
</body>
</html>
EOF

    # Set proper permissions
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo chown -R www-data:www-data $REMOTE_PATH"
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo chmod -R 755 $REMOTE_PATH"

    echo -e "${GREEN}Files deployed successfully${NC}"
}

# Setup SSL certificates
setup_ssl() {
    echo -e "${YELLOW}Setting up SSL certificates...${NC}"

    # Install certbot if not present
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo apt update && sudo apt install -y certbot python3-certbot-nginx"

    # Obtain SSL certificate
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo certbot certonly --standalone -d $DOMAIN -d $WWW_DOMAIN --agree-tos --email admin@$DOMAIN --no-eff-email"

    echo -e "${GREEN}SSL certificates configured${NC}"
}

# Configure firewall
setup_firewall() {
    echo -e "${YELLOW}Configuring firewall...${NC}"

    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo ufw allow 22/tcp" || true
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo ufw allow 80/tcp" || true
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo ufw allow 443/tcp" || true
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo ufw --force enable" || true

    echo -e "${GREEN}Firewall configured${NC}"
}

# Install and configure nginx
setup_web_server() {
    echo -e "${YELLOW}Setting up web server...${NC}"

    # Install nginx
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo apt install -y nginx"

    # Copy nginx configuration
    scp -P $SSH_PORT spiralcoin.net.conf $SSH_USER@$SERVER_IP:/tmp/
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo mv /tmp/spiralcoin.net.conf /etc/nginx/sites-available/"
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo ln -sf /etc/nginx/sites-available/spiralcoin.net.conf /etc/nginx/sites-enabled/" || true

    # Remove default site
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo rm -f /etc/nginx/sites-enabled/default"

    # Test nginx configuration
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo nginx -t"

    # Restart nginx
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo systemctl restart nginx"
    ssh -p $SSH_PORT $SSH_USER@$SERVER_IP "sudo systemctl enable nginx"

    echo -e "${GREEN}Web server configured${NC}"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v scp &> /dev/null; then
        echo -e "${RED}Error: scp command not found. Please install OpenSSH client.${NC}"
        exit 1
    fi

    if ! command -v ssh &> /dev/null; then
        echo -e "${RED}Error: ssh command not found. Please install OpenSSH client.${NC}"
        exit 1
    fi
}

# Main deployment function
main() {
    echo -e "${GREEN}Starting SpiralCoin Trading Platform deployment...${NC}"
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Domain: $DOMAIN"
    echo "  Server IP: $SERVER_IP"
    echo "  SSH User: $SSH_USER"
    echo "  SSH Port: $SSH_PORT"
    echo ""

    check_domain
    setup_nginx
    deploy_files
    setup_firewall
    setup_web_server
    setup_ssl

    echo -e "${GREEN}🎉 Deployment complete!${NC}"
    echo -e "${YELLOW}Your trading platform is now live at:${NC}"
    echo -e "${GREEN}https://$DOMAIN${NC}"
    echo -e "${GREEN}https://$WWW_DOMAIN${NC}"

    echo -e "\n${YELLOW}API Endpoints:${NC}"
    echo "  https://$DOMAIN/api/          -> http://127.0.0.1:5000"
    echo "  https://$DOMAIN/feed/         -> http://127.0.0.1:4000"
    echo "  wss://$DOMAIN/ws              -> ws://127.0.0.1:4000"

    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Verify the website is accessible at https://$DOMAIN"
    echo "2. Test API connectivity: curl https://$DOMAIN/api/blockchain"
    echo "3. Monitor logs on server: ssh -p $SSH_PORT $SSH_USER@$SERVER_IP"
    echo "4. Configure monitoring and analytics"
}

# Run prerequisite check
check_prerequisites

# Run main deployment
main
