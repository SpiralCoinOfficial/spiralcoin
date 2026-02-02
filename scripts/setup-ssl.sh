#!/bin/bash
# SpiralCoin SSL Certificate Setup Script
# This script sets up SSL certificates for spiralcoin.net using Let's Encrypt
# Prerequisites: Domain DNS must be pointing to this server

set -e

# Configuration
DOMAIN="${DOMAIN:-spiralcoin.net}"
EMAIL="${EMAIL:-admin@spiralcoin.net}"
SSL_DIR="/home/runner/work/spiralcoin/spiralcoin/ssl"
PROJECT_ROOT="/home/runner/work/spiralcoin/spiralcoin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  SpiralCoin SSL Certificate Setup${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Function to print colored messages
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ] && [ -z "$SUDO_USER" ]; then 
    print_warning "This script should be run with sudo privileges for production"
fi

# Create SSL directory
print_info "Creating SSL directory: $SSL_DIR"
mkdir -p "$SSL_DIR"

# Check if domain is accessible
print_info "Checking if domain $DOMAIN is accessible..."
if ! ping -c 1 "$DOMAIN" &> /dev/null; then
    print_warning "Domain $DOMAIN is not accessible. DNS may not be configured yet."
    print_info "You can still generate self-signed certificates for testing."
    echo ""
    read -p "Do you want to generate self-signed certificates for testing? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Generating self-signed certificates..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/privkey.pem" \
            -out "$SSL_DIR/fullchain.pem" \
            -subj "/C=US/ST=State/L=City/O=SpiralCoin/CN=$DOMAIN" \
            -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:api.$DOMAIN"
        
        print_success "Self-signed certificates generated!"
        print_warning "NOTE: Browsers will show a security warning for self-signed certificates."
        print_warning "For production, use Let's Encrypt certificates instead."
        exit 0
    else
        print_error "Cannot proceed without valid SSL certificates."
        exit 1
    fi
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    print_info "Certbot not found. Installing..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y certbot python3-certbot-nginx
    elif command -v yum &> /dev/null; then
        sudo yum install -y certbot python3-certbot-nginx
    elif command -v snap &> /dev/null; then
        sudo snap install --classic certbot
        sudo ln -s /snap/bin/certbot /usr/bin/certbot || true
    else
        print_error "Cannot install certbot. Please install it manually."
        exit 1
    fi
    
    print_success "Certbot installed successfully!"
fi

# Check if nginx is running
if ! pgrep -x "nginx" > /dev/null && ! docker ps | grep -q "nginx"; then
    print_warning "Nginx is not running. Starting nginx for certificate verification..."
    
    # Try to start nginx
    if command -v systemctl &> /dev/null; then
        sudo systemctl start nginx || true
    fi
fi

# Obtain Let's Encrypt certificate
print_info "Obtaining Let's Encrypt certificate for $DOMAIN and www.$DOMAIN..."

# Use standalone mode if nginx is not available, otherwise use webroot
if [ -d "/var/www/html" ] || [ -d "/usr/share/nginx/html" ]; then
    WEBROOT="/var/www/html"
    [ -d "/usr/share/nginx/html" ] && WEBROOT="/usr/share/nginx/html"
    
    sudo certbot certonly --webroot -w "$WEBROOT" \
        -d "$DOMAIN" -d "www.$DOMAIN" \
        --non-interactive --agree-tos --email "$EMAIL" \
        --deploy-hook "systemctl reload nginx || docker restart spiralcoin-nginx || true" || {
        
        print_warning "Webroot method failed. Trying standalone method..."
        sudo systemctl stop nginx 2>/dev/null || true
        sudo docker stop spiralcoin-nginx 2>/dev/null || true
        
        sudo certbot certonly --standalone \
            -d "$DOMAIN" -d "www.$DOMAIN" \
            --non-interactive --agree-tos --email "$EMAIL" || {
            print_error "Failed to obtain certificate. Please check DNS and firewall settings."
            exit 1
        }
        
        sudo systemctl start nginx 2>/dev/null || true
        sudo docker start spiralcoin-nginx 2>/dev/null || true
    }
else
    # Use standalone method
    print_info "Using standalone method (nginx will be temporarily stopped)..."
    sudo systemctl stop nginx 2>/dev/null || true
    sudo docker stop spiralcoin-nginx 2>/dev/null || true
    
    sudo certbot certonly --standalone \
        -d "$DOMAIN" -d "www.$DOMAIN" \
        --non-interactive --agree-tos --email "$EMAIL" || {
        print_error "Failed to obtain certificate. Please check DNS and firewall settings."
        sudo systemctl start nginx 2>/dev/null || true
        sudo docker start spiralcoin-nginx 2>/dev/null || true
        exit 1
    }
    
    sudo systemctl start nginx 2>/dev/null || true
    sudo docker start spiralcoin-nginx 2>/dev/null || true
fi

print_success "Certificate obtained successfully!"

# Copy certificates to project SSL directory
print_info "Copying certificates to $SSL_DIR..."
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/fullchain.pem"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/privkey.pem"
    sudo chmod 644 "$SSL_DIR/fullchain.pem"
    sudo chmod 600 "$SSL_DIR/privkey.pem"
    print_success "Certificates copied to project directory!"
else
    print_error "Certificate directory not found at /etc/letsencrypt/live/$DOMAIN"
    exit 1
fi

# Set up auto-renewal
print_info "Setting up automatic certificate renewal..."
if command -v systemctl &> /dev/null; then
    sudo systemctl enable certbot.timer || sudo systemctl enable snap.certbot.renew.timer || true
    sudo systemctl start certbot.timer || sudo systemctl start snap.certbot.renew.timer || true
fi

# Create renewal hook script
RENEWAL_HOOK="/etc/letsencrypt/renewal-hooks/deploy/spiralcoin-renewal.sh"
print_info "Creating certificate renewal hook..."
sudo mkdir -p "$(dirname "$RENEWAL_HOOK")"
sudo tee "$RENEWAL_HOOK" > /dev/null << 'EOF'
#!/bin/bash
# SpiralCoin certificate renewal hook
DOMAIN="spiralcoin.net"
SSL_DIR="/home/runner/work/spiralcoin/spiralcoin/ssl"

if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/fullchain.pem"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/privkey.pem"
    chmod 644 "$SSL_DIR/fullchain.pem"
    chmod 600 "$SSL_DIR/privkey.pem"
    
    # Restart nginx
    systemctl reload nginx 2>/dev/null || docker restart spiralcoin-nginx 2>/dev/null || true
fi
EOF
sudo chmod +x "$RENEWAL_HOOK"

print_success "Renewal hook created!"

# Test certificate renewal
print_info "Testing certificate renewal (dry run)..."
sudo certbot renew --dry-run || print_warning "Renewal dry-run failed, but certificates are installed"

# Verify certificates
print_info "Verifying certificates..."
if [ -f "$SSL_DIR/fullchain.pem" ] && [ -f "$SSL_DIR/privkey.pem" ]; then
    print_success "Certificates are installed and ready!"
    echo ""
    echo -e "${GREEN}Certificate Details:${NC}"
    openssl x509 -in "$SSL_DIR/fullchain.pem" -text -noout | grep -A 2 "Subject:"
    openssl x509 -in "$SSL_DIR/fullchain.pem" -text -noout | grep -A 2 "Not After"
    echo ""
else
    print_error "Certificate files not found!"
    exit 1
fi

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  SSL Setup Complete!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Restart your nginx/web server:"
echo "   sudo systemctl restart nginx"
echo "   OR"
echo "   docker compose restart nginx"
echo ""
echo "2. Test HTTPS access:"
echo "   curl -I https://$DOMAIN"
echo ""
echo "3. Certificates will auto-renew every 90 days"
echo ""
echo -e "${YELLOW}Certificate locations:${NC}"
echo "  Project: $SSL_DIR/fullchain.pem"
echo "  Project: $SSL_DIR/privkey.pem"
echo "  System:  /etc/letsencrypt/live/$DOMAIN/"
echo ""

exit 0
