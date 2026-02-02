#!/bin/bash
# SpiralCoin SSL Certificate Verification Script
# Checks if SSL certificates are properly installed and valid

set -e

DOMAIN="${DOMAIN:-spiralcoin.net}"
SSL_DIR="${SSL_DIR:-./ssl}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  SpiralCoin SSL Certificate Verification${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Check if certificate files exist
print_info "Checking certificate files..."
if [ -f "$SSL_DIR/fullchain.pem" ]; then
    print_success "Certificate file exists: $SSL_DIR/fullchain.pem"
else
    print_error "Certificate file not found: $SSL_DIR/fullchain.pem"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "$SSL_DIR/privkey.pem" ]; then
    print_success "Private key file exists: $SSL_DIR/privkey.pem"
else
    print_error "Private key file not found: $SSL_DIR/privkey.pem"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
    echo ""
    print_error "Certificate files are missing!"
    echo ""
    echo "To fix this:"
    echo "1. For production with Let's Encrypt:"
    echo "   sudo bash scripts/setup-ssl.sh"
    echo ""
    echo "2. For development with self-signed certificates:"
    echo "   bash scripts/generate-self-signed-cert.sh"
    echo ""
    exit 1
fi

# Check certificate validity
print_info "Checking certificate validity..."
CERT_INFO=$(openssl x509 -in "$SSL_DIR/fullchain.pem" -text -noout)

# Check subject
SUBJECT=$(echo "$CERT_INFO" | grep "Subject:" | head -1)
print_success "Certificate subject: $SUBJECT"

# Check issuer
ISSUER=$(echo "$CERT_INFO" | grep "Issuer:" | head -1)
if echo "$ISSUER" | grep -q "Let's Encrypt"; then
    print_success "Issuer: Let's Encrypt (Trusted CA)"
elif echo "$ISSUER" | grep -qi "CN=$DOMAIN"; then
    print_warning "Self-signed certificate (not trusted by browsers)"
    WARNINGS=$((WARNINGS + 1))
else
    print_info "Issuer: $ISSUER"
fi

# Check expiration
NOT_BEFORE=$(echo "$CERT_INFO" | grep "Not Before:" | cut -d: -f2-)
NOT_AFTER=$(echo "$CERT_INFO" | grep "Not After :" | cut -d: -f2-)
print_info "Valid from:$NOT_BEFORE"
print_info "Valid until:$NOT_AFTER"

# Check if expired
if openssl x509 -checkend 0 -noout -in "$SSL_DIR/fullchain.pem" > /dev/null; then
    print_success "Certificate is currently valid"
else
    print_error "Certificate has expired!"
    ERRORS=$((ERRORS + 1))
fi

# Check if expiring soon (30 days)
if openssl x509 -checkend 2592000 -noout -in "$SSL_DIR/fullchain.pem" > /dev/null; then
    print_success "Certificate valid for more than 30 days"
else
    print_warning "Certificate expires in less than 30 days!"
    WARNINGS=$((WARNINGS + 1))
fi

# Check SANs (Subject Alternative Names)
print_info "Checking domain names in certificate..."
SANS=$(echo "$CERT_INFO" | grep -A 1 "Subject Alternative Name:" | tail -1)
if echo "$SANS" | grep -q "$DOMAIN"; then
    print_success "Certificate includes domain: $DOMAIN"
else
    print_warning "Certificate may not include domain: $DOMAIN"
    WARNINGS=$((WARNINGS + 1))
fi

# Check private key
print_info "Checking private key..."
if openssl rsa -in "$SSL_DIR/privkey.pem" -check -noout > /dev/null 2>&1; then
    print_success "Private key is valid"
else
    print_error "Private key is invalid or corrupted!"
    ERRORS=$((ERRORS + 1))
fi

# Check if certificate and key match
print_info "Checking if certificate and private key match..."
CERT_MOD=$(openssl x509 -noout -modulus -in "$SSL_DIR/fullchain.pem" | openssl md5)
KEY_MOD=$(openssl rsa -noout -modulus -in "$SSL_DIR/privkey.pem" | openssl md5)

if [ "$CERT_MOD" = "$KEY_MOD" ]; then
    print_success "Certificate and private key match"
else
    print_error "Certificate and private key do NOT match!"
    ERRORS=$((ERRORS + 1))
fi

# Check file permissions
print_info "Checking file permissions..."
CERT_PERM=$(stat -c %a "$SSL_DIR/fullchain.pem" 2>/dev/null || stat -f %A "$SSL_DIR/fullchain.pem" 2>/dev/null)
KEY_PERM=$(stat -c %a "$SSL_DIR/privkey.pem" 2>/dev/null || stat -f %A "$SSL_DIR/privkey.pem" 2>/dev/null)

if [ "$CERT_PERM" = "644" ] || [ "$CERT_PERM" = "444" ]; then
    print_success "Certificate permissions: $CERT_PERM (OK)"
else
    print_warning "Certificate permissions: $CERT_PERM (should be 644)"
    WARNINGS=$((WARNINGS + 1))
fi

if [ "$KEY_PERM" = "600" ] || [ "$KEY_PERM" = "400" ]; then
    print_success "Private key permissions: $KEY_PERM (OK)"
else
    print_warning "Private key permissions: $KEY_PERM (should be 600)"
    print_info "Run: chmod 600 $SSL_DIR/privkey.pem"
    WARNINGS=$((WARNINGS + 1))
fi

# Test HTTPS connection (if nginx is running)
print_info "Testing HTTPS connection..."
if command -v curl &> /dev/null; then
    if curl -k -s -o /dev/null -w "%{http_code}" "https://localhost" 2>/dev/null | grep -q "200\|301\|302"; then
        print_success "HTTPS server is responding"
        
        # Test with domain
        if curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null | grep -q "200\|301\|302"; then
            print_success "HTTPS accessible at https://$DOMAIN"
        else
            print_warning "HTTPS not accessible at https://$DOMAIN (check DNS and firewall)"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        print_warning "HTTPS server not responding (nginx may not be running)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_info "curl not available for HTTPS test"
fi

# Summary
echo ""
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Verification Summary${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Your SSL certificates are properly configured."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Checks passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "SSL certificates are functional but some warnings were found."
    echo "Review the warnings above."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "SSL certificates have issues that need to be fixed."
    echo ""
    echo "Recommended actions:"
    if echo "$ISSUER" | grep -qi "CN=$DOMAIN"; then
        echo "1. You have a self-signed certificate. For production, obtain a Let's Encrypt certificate:"
        echo "   sudo bash scripts/setup-ssl.sh"
    else
        echo "1. Regenerate or re-obtain your SSL certificates"
    fi
    echo "2. Restart nginx after fixing certificates"
    echo ""
    exit 1
fi
