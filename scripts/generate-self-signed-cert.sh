#!/bin/bash
# Generate self-signed SSL certificates for SpiralCoin development/testing
# WARNING: These certificates will show browser warnings. Use only for development!

set -e

DOMAIN="${DOMAIN:-spiralcoin.net}"
SSL_DIR="${SSL_DIR:-./ssl}"
DAYS="${DAYS:-365}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}=================================================${NC}"
echo -e "${YELLOW}  Self-Signed Certificate Generator${NC}"
echo -e "${YELLOW}  FOR DEVELOPMENT/TESTING ONLY${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo ""

echo -e "${YELLOW}WARNING: Self-signed certificates will show security warnings in browsers!${NC}"
echo -e "${YELLOW}For production, use Let's Encrypt certificates instead.${NC}"
echo ""

# Create SSL directory
mkdir -p "$SSL_DIR"

echo -e "${BLUE}[INFO]${NC} Generating self-signed certificate for $DOMAIN..."
echo -e "${BLUE}[INFO]${NC} Valid for $DAYS days"
echo ""

# Generate certificate
openssl req -x509 -nodes -days "$DAYS" -newkey rsa:2048 \
    -keyout "$SSL_DIR/privkey.pem" \
    -out "$SSL_DIR/fullchain.pem" \
    -subj "/C=US/ST=Development/L=Local/O=SpiralCoin/OU=Development/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:api.$DOMAIN,DNS:localhost" \
    -addext "keyUsage=digitalSignature,keyEncipherment" \
    -addext "extendedKeyUsage=serverAuth"

# Set permissions
chmod 644 "$SSL_DIR/fullchain.pem"
chmod 600 "$SSL_DIR/privkey.pem"

echo ""
echo -e "${GREEN}[SUCCESS]${NC} Self-signed certificates generated!"
echo ""
echo -e "${BLUE}Certificate details:${NC}"
openssl x509 -in "$SSL_DIR/fullchain.pem" -text -noout | grep -E "(Subject:|Not Before|Not After|DNS:)"
echo ""
echo -e "${BLUE}Files created:${NC}"
echo "  Certificate: $SSL_DIR/fullchain.pem"
echo "  Private Key: $SSL_DIR/privkey.pem"
echo ""
echo -e "${YELLOW}Note:${NC} Browsers will show a security warning for self-signed certificates."
echo "You can bypass this in development by:"
echo "  - Chrome/Edge: Click 'Advanced' → 'Proceed to $DOMAIN (unsafe)'"
echo "  - Firefox: Click 'Advanced' → 'Accept the Risk and Continue'"
echo ""
echo -e "${BLUE}To use these certificates:${NC}"
echo "1. Update your nginx.conf to point to these files"
echo "2. Restart nginx: docker compose restart nginx"
echo "3. Access https://$DOMAIN (accept security warning)"
echo ""
echo -e "${GREEN}For production, run: ./scripts/setup-ssl.sh${NC}"
echo ""

exit 0
