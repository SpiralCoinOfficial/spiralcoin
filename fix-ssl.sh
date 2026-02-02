#!/bin/bash
# Quick SSL Certificate Fix for SpiralCoin
# This script provides an interactive menu to fix SSL certificate issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                    ║${NC}"
echo -e "${CYAN}║     SpiralCoin SSL Certificate Fix Tool           ║${NC}"
echo -e "${CYAN}║                                                    ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${YELLOW}Error: ERR_CERT_AUTHORITY_INVALID${NC}"
echo -e "${YELLOW}Browser won't trust the SSL certificate${NC}"
echo ""
echo -e "${BLUE}This tool will help you fix SSL certificate issues.${NC}"
echo ""

# Check current status
echo -e "${BLUE}Checking current SSL status...${NC}"
SSL_DIR="./ssl"

if [ -f "$SSL_DIR/fullchain.pem" ] && [ -f "$SSL_DIR/privkey.pem" ]; then
    echo -e "${GREEN}✓${NC} Certificate files found"
    
    # Check if self-signed
    ISSUER=$(openssl x509 -in "$SSL_DIR/fullchain.pem" -noout -issuer)
    if echo "$ISSUER" | grep -q "CN=spiralcoin.net"; then
        echo -e "${YELLOW}⚠${NC} Self-signed certificate detected"
        CERT_TYPE="self-signed"
    else
        echo -e "${GREEN}✓${NC} Certificate appears to be from a CA"
        
        # Check expiration
        if openssl x509 -checkend 0 -noout -in "$SSL_DIR/fullchain.pem" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Certificate is valid"
            CERT_TYPE="valid"
        else
            echo -e "${RED}✗${NC} Certificate has expired"
            CERT_TYPE="expired"
        fi
    fi
else
    echo -e "${RED}✗${NC} Certificate files not found"
    CERT_TYPE="missing"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo ""

# Show appropriate menu based on status
if [ "$CERT_TYPE" = "missing" ] || [ "$CERT_TYPE" = "self-signed" ] || [ "$CERT_TYPE" = "expired" ]; then
    echo -e "${YELLOW}Choose an option to fix SSL:${NC}"
    echo ""
    echo "  1) Get Let's Encrypt Certificate (Production)"
    echo "     • Trusted by all browsers"
    echo "     • Free and automatic renewal"
    echo "     • Requires: DNS configured, port 80/443 open"
    echo ""
    echo "  2) Generate Self-Signed Certificate (Development)"
    echo "     • For testing/development only"
    echo "     • Browser will show warnings"
    echo "     • Works without DNS configuration"
    echo ""
    echo "  3) Verify Current Certificate"
    echo "     • Check certificate status"
    echo "     • View certificate details"
    echo ""
    echo "  4) View Troubleshooting Guide"
    echo "     • Detailed fix instructions"
    echo "     • Common issues and solutions"
    echo ""
    echo "  5) Exit"
    echo ""
    read -p "Enter your choice (1-5): " choice
    echo ""
    
    case $choice in
        1)
            echo -e "${BLUE}Setting up Let's Encrypt certificate...${NC}"
            echo ""
            echo "This will:"
            echo "  • Install Certbot (if needed)"
            echo "  • Obtain a trusted SSL certificate"
            echo "  • Set up automatic renewal"
            echo "  • Restart nginx"
            echo ""
            read -p "Do you want to continue? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo bash scripts/setup-ssl.sh
                
                echo ""
                echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}SSL certificate setup complete!${NC}"
                echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
                echo ""
                echo "Next steps:"
                echo "1. Restart nginx: docker compose restart nginx"
                echo "2. Test HTTPS: curl -I https://www.spiralcoin.net"
                echo "3. Open browser: https://www.spiralcoin.net"
                echo ""
            fi
            ;;
        2)
            echo -e "${BLUE}Generating self-signed certificate...${NC}"
            echo ""
            echo -e "${YELLOW}WARNING: Self-signed certificates show browser warnings!${NC}"
            echo -e "${YELLOW}Use only for development/testing.${NC}"
            echo ""
            read -p "Do you want to continue? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                bash scripts/generate-self-signed-cert.sh
                
                echo ""
                echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
                echo -e "${GREEN}Self-signed certificate generated!${NC}"
                echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
                echo ""
                echo "Next steps:"
                echo "1. Restart nginx: docker compose restart nginx"
                echo "2. Open browser: https://www.spiralcoin.net"
                echo "3. Click 'Advanced' → 'Proceed anyway'"
                echo ""
                echo -e "${YELLOW}For production, use option 1 (Let's Encrypt)${NC}"
                echo ""
            fi
            ;;
        3)
            echo -e "${BLUE}Verifying certificate...${NC}"
            echo ""
            bash scripts/verify-ssl.sh
            ;;
        4)
            echo -e "${BLUE}Opening troubleshooting guide...${NC}"
            echo ""
            if command -v less &> /dev/null; then
                less SSL_FIX_GUIDE.md
            elif command -v more &> /dev/null; then
                more SSL_FIX_GUIDE.md
            else
                cat SSL_FIX_GUIDE.md
            fi
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${GREEN}✓ SSL certificate appears to be valid!${NC}"
    echo ""
    echo "If you're still seeing browser errors:"
    echo ""
    echo "1. Clear browser cache and cookies"
    echo "2. Try in incognito/private mode"
    echo "3. Check if DNS is properly configured"
    echo "4. Run verification: bash scripts/verify-ssl.sh"
    echo "5. View troubleshooting guide: less SSL_FIX_GUIDE.md"
    echo ""
fi

echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Need more help?${NC}"
echo "  • Read SSL_FIX_GUIDE.md for detailed instructions"
echo "  • Run: bash scripts/verify-ssl.sh to diagnose issues"
echo "  • Check nginx logs: docker compose logs nginx"
echo ""

exit 0
