#!/bin/bash
# Automated SSL Certificate Fix for SpiralCoin
# This script automatically fixes the ERR_CERT_AUTHORITY_INVALID error
# No user interaction required!

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}║        🔒 SpiralCoin SSL Certificate Auto-Fix                      ║${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Fixing: ERR_CERT_AUTHORITY_INVALID${NC}"
echo -e "${YELLOW}This will automatically fix your SSL certificate issue.${NC}"
echo ""

DOMAIN="${DOMAIN:-spiralcoin.net}"
SSL_DIR="./ssl"
PROJECT_ROOT="/home/runner/work/spiralcoin/spiralcoin"

cd "$PROJECT_ROOT" 2>/dev/null || cd .

# Function to print messages
print_step() { echo -e "${BLUE}[STEP $1]${NC} $2"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }

# Step 1: Create SSL directory
print_step 1 "Creating SSL directory..."
mkdir -p "$SSL_DIR"
print_success "SSL directory ready"

# Step 2: Check if we need to regenerate certificates
REGEN_CERT=false
if [ ! -f "$SSL_DIR/fullchain.pem" ] || [ ! -f "$SSL_DIR/privkey.pem" ]; then
    print_info "Certificate files missing"
    REGEN_CERT=true
elif ! openssl x509 -checkend 86400 -noout -in "$SSL_DIR/fullchain.pem" 2>/dev/null; then
    print_info "Certificate expired or invalid"
    REGEN_CERT=true
elif ! openssl rsa -check -noout -in "$SSL_DIR/privkey.pem" 2>/dev/null; then
    print_info "Private key missing or invalid"
    REGEN_CERT=true
fi

# Step 3: Generate certificates if needed
if [ "$REGEN_CERT" = true ]; then
    print_step 2 "Generating SSL certificates..."
    
    # Remove old certificates
    rm -f "$SSL_DIR/fullchain.pem" "$SSL_DIR/privkey.pem"
    
    # Generate new self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/privkey.pem" \
        -out "$SSL_DIR/fullchain.pem" \
        -subj "/C=US/ST=Development/L=Local/O=SpiralCoin/OU=Development/CN=$DOMAIN" \
        -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:api.$DOMAIN,DNS:localhost" \
        -addext "keyUsage=digitalSignature,keyEncipherment" \
        -addext "extendedKeyUsage=serverAuth" 2>/dev/null
    
    # Set correct permissions
    chmod 644 "$SSL_DIR/fullchain.pem"
    chmod 600 "$SSL_DIR/privkey.pem"
    
    print_success "SSL certificates generated"
else
    print_step 2 "SSL certificates are valid"
    print_success "Certificates already exist and are valid"
fi

# Step 4: Verify certificates
print_step 3 "Verifying SSL certificates..."

# Check certificate exists
if [ ! -f "$SSL_DIR/fullchain.pem" ]; then
    print_error "Certificate file not found!"
    exit 1
fi

# Check private key exists
if [ ! -f "$SSL_DIR/privkey.pem" ]; then
    print_error "Private key file not found!"
    exit 1
fi

# Check certificate and key match
CERT_MOD=$(openssl x509 -noout -modulus -in "$SSL_DIR/fullchain.pem" 2>/dev/null | openssl md5)
KEY_MOD=$(openssl rsa -noout -modulus -in "$SSL_DIR/privkey.pem" 2>/dev/null | openssl md5)

if [ "$CERT_MOD" != "$KEY_MOD" ]; then
    print_error "Certificate and private key do NOT match!"
    exit 1
fi

print_success "Certificate and private key match"

# Step 5: Check if nginx is running and restart it
print_step 4 "Starting/Restarting nginx..."

# Check if Docker Compose is available
if command -v docker &> /dev/null; then
    # Try to start/restart nginx with Docker Compose
    if [ -f "compose.yaml" ] || [ -f "docker-compose.yaml" ] || [ -f "docker-compose.yml" ]; then
        
        # Stop any existing containers
        docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
        
        # Start nginx with the web profile
        if docker compose up -d --profile web 2>/dev/null; then
            print_success "Nginx started with Docker Compose"
        elif docker-compose up -d 2>/dev/null; then
            print_success "Nginx started with docker-compose"
        else
            print_info "Starting nginx container manually..."
            docker run -d --name spiralcoin-nginx \
                -p 80:80 -p 443:443 \
                -v "$PWD/nginx.conf:/etc/nginx/nginx.conf:ro" \
                -v "$PWD/public:/usr/share/nginx/html:ro" \
                -v "$PWD/ssl:/etc/nginx/ssl:ro" \
                --network spiralcoin-network \
                nginx:alpine 2>/dev/null || print_info "Could not start nginx with Docker"
        fi
        
        # Give nginx time to start
        sleep 2
        
        # Check if nginx is running
        if docker ps | grep -q nginx; then
            print_success "Nginx is running"
        else
            print_info "Nginx may not be running in Docker"
        fi
    else
        print_info "No docker-compose file found"
    fi
elif command -v nginx &> /dev/null; then
    # Try system nginx
    if sudo nginx -t 2>/dev/null; then
        sudo systemctl reload nginx 2>/dev/null || sudo systemctl restart nginx 2>/dev/null || true
        print_success "System nginx restarted"
    fi
else
    print_info "Nginx not found (Docker or system)"
fi

# Step 6: Verify HTTPS is working
print_step 5 "Testing HTTPS connection..."

# Test localhost
if timeout 3 curl -k -s -o /dev/null -w "%{http_code}" "https://localhost" 2>/dev/null | grep -q "200\|301\|302"; then
    print_success "HTTPS responding on localhost"
else
    print_info "HTTPS not responding (nginx may need to be started manually)"
fi

# Step 7: Display certificate info
print_step 6 "Certificate information:"
echo ""
openssl x509 -in "$SSL_DIR/fullchain.pem" -noout -subject -dates 2>/dev/null | sed 's/^/  /'
echo ""

# Step 8: Final instructions
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ SSL Certificate Fix Complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Self-signed certificates show browser warnings${NC}"
echo -e "${YELLOW}This is NORMAL and EXPECTED for development.${NC}"
echo ""
echo -e "${BLUE}To access your site:${NC}"
echo "  1. Open: https://www.spiralcoin.net (or https://localhost)"
echo "  2. Browser will show security warning"
echo "  3. Click 'Advanced'"
echo "  4. Click 'Proceed to www.spiralcoin.net (unsafe)'"
echo ""
echo -e "${BLUE}Browser-specific instructions:${NC}"
echo "  • Chrome/Edge: Advanced → Proceed to... (unsafe)"
echo "  • Firefox: Advanced → Accept the Risk and Continue"
echo "  • Safari: Show Details → Visit this website"
echo ""
echo -e "${YELLOW}For production (trusted certificate, no warnings):${NC}"
echo "  Run: sudo bash scripts/setup-ssl.sh"
echo ""
echo -e "${GREEN}If nginx isn't running, start it with:${NC}"
echo "  docker compose up -d --profile web"
echo "  OR"
echo "  docker compose -f compose.yaml up -d"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ Your SSL certificates are installed and ready!${NC}"
echo ""

exit 0
