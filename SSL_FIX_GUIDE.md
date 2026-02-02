# SSL Certificate Error Fix Guide

## Problem

Browser shows error: **"Your connection isn't private - ERR_CERT_AUTHORITY_INVALID"**

This error occurs when:
1. SSL certificates are missing
2. SSL certificates are self-signed (not from a trusted Certificate Authority)
3. SSL certificates have expired
4. SSL certificates are for a different domain
5. Certificate chain is incomplete

---

## Quick Fix (Choose One)

### Option 1: Production Setup with Let's Encrypt (Recommended)

**Prerequisites:**
- Domain DNS must be pointing to your server
- Port 80 and 443 must be open
- Server must be accessible from the internet

```bash
cd /home/runner/work/spiralcoin/spiralcoin
sudo bash scripts/setup-ssl.sh
```

This will:
- Install Certbot if needed
- Obtain trusted SSL certificate from Let's Encrypt
- Copy certificates to the correct location
- Set up automatic renewal
- Restart nginx

**After running:**
```bash
# Restart nginx
sudo systemctl restart nginx
# OR if using Docker:
docker compose restart nginx

# Test HTTPS
curl -I https://www.spiralcoin.net
```

---

### Option 2: Development/Testing with Self-Signed Certificate

**Use this if:**
- DNS is not yet configured
- Testing locally
- Development environment

```bash
cd /home/runner/work/spiralcoin/spiralcoin
bash scripts/generate-self-signed-cert.sh
```

This will:
- Generate self-signed certificates
- Place them in `./ssl/` directory
- Show instructions for bypassing browser warnings

**Note:** Self-signed certificates will still show browser warnings, but you can proceed by clicking "Advanced" → "Proceed anyway"

**After generating:**
```bash
# Restart nginx
docker compose restart nginx

# Access site (you'll need to accept security warning)
# Chrome/Edge: Click "Advanced" → "Proceed to www.spiralcoin.net (unsafe)"
# Firefox: Click "Advanced" → "Accept the Risk and Continue"
```

---

## Verification

After fixing, verify your SSL setup:

```bash
cd /home/runner/work/spiralcoin/spiralcoin
bash scripts/verify-ssl.sh
```

This will check:
- Certificate files exist
- Certificates are valid
- Certificates haven't expired
- Certificate and private key match
- File permissions are correct
- HTTPS is responding

---

## Detailed Troubleshooting

### Error: Certificate files not found

**Symptoms:**
```
nginx: [emerg] cannot load certificate "/etc/nginx/ssl/fullchain.pem"
```

**Solution:**
1. Run one of the setup scripts above
2. Ensure certificates are in the correct location:
   - `/home/runner/work/spiralcoin/spiralcoin/ssl/fullchain.pem`
   - `/home/runner/work/spiralcoin/spiralcoin/ssl/privkey.pem`

### Error: Certificate has expired

**Solution:**
```bash
# Renew Let's Encrypt certificate
sudo certbot renew

# Copy renewed certificate
sudo cp /etc/letsencrypt/live/spiralcoin.net/fullchain.pem /home/runner/work/spiralcoin/spiralcoin/ssl/
sudo cp /etc/letsencrypt/live/spiralcoin.net/privkey.pem /home/runner/work/spiralcoin/spiralcoin/ssl/

# Restart nginx
docker compose restart nginx
```

### Error: Self-signed certificate

**Symptoms:**
- Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"
- Certificate issuer is same as subject

**Solution:**
For production, obtain Let's Encrypt certificate:
```bash
sudo bash scripts/setup-ssl.sh
```

For development, this is expected. You can:
1. Proceed anyway (click Advanced in browser)
2. Add exception in browser settings
3. Import certificate as trusted (for development only)

### Error: Certificate domain mismatch

**Symptoms:**
- Browser shows "NET::ERR_CERT_COMMON_NAME_INVALID"
- Certificate is for different domain

**Solution:**
Regenerate certificate with correct domain:
```bash
DOMAIN=www.spiralcoin.net sudo bash scripts/setup-ssl.sh
```

### Error: Permission denied

**Symptoms:**
```
nginx: [emerg] BIO_new_file("/etc/nginx/ssl/privkey.pem") failed
```

**Solution:**
```bash
cd /home/runner/work/spiralcoin/spiralcoin
sudo chmod 644 ssl/fullchain.pem
sudo chmod 600 ssl/privkey.pem
sudo chown root:root ssl/*.pem
```

---

## Manual Certificate Setup

If automated scripts don't work, you can manually set up certificates:

### Step 1: Install Certbot

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install -y certbot python3-certbot-nginx

# Using snap (universal)
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

### Step 2: Obtain Certificate

**Option A: Using nginx plugin (automatic)**
```bash
sudo certbot --nginx -d spiralcoin.net -d www.spiralcoin.net
```

**Option B: Using standalone (manual)**
```bash
# Stop nginx temporarily
sudo systemctl stop nginx

# Obtain certificate
sudo certbot certonly --standalone \
  -d spiralcoin.net -d www.spiralcoin.net \
  --non-interactive --agree-tos \
  --email admin@spiralcoin.net

# Start nginx
sudo systemctl start nginx
```

### Step 3: Copy Certificates

```bash
sudo mkdir -p /home/runner/work/spiralcoin/spiralcoin/ssl
sudo cp /etc/letsencrypt/live/spiralcoin.net/fullchain.pem \
  /home/runner/work/spiralcoin/spiralcoin/ssl/
sudo cp /etc/letsencrypt/live/spiralcoin.net/privkey.pem \
  /home/runner/work/spiralcoin/spiralcoin/ssl/
sudo chmod 644 /home/runner/work/spiralcoin/spiralcoin/ssl/fullchain.pem
sudo chmod 600 /home/runner/work/spiralcoin/spiralcoin/ssl/privkey.pem
```

### Step 4: Restart Services

```bash
# If using Docker
docker compose restart nginx

# If using system nginx
sudo systemctl restart nginx
```

---

## Certificate Auto-Renewal

Let's Encrypt certificates expire every 90 days. Set up automatic renewal:

### Check if renewal is configured:

```bash
sudo systemctl status certbot.timer
# OR
sudo systemctl status snap.certbot.renew.timer
```

### Test renewal (dry run):

```bash
sudo certbot renew --dry-run
```

### Manual renewal:

```bash
sudo certbot renew

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/spiralcoin.net/fullchain.pem \
  /home/runner/work/spiralcoin/spiralcoin/ssl/
sudo cp /etc/letsencrypt/live/spiralcoin.net/privkey.pem \
  /home/runner/work/spiralcoin/spiralcoin/ssl/

# Restart nginx
docker compose restart nginx
```

---

## Common Issues and Solutions

### Issue: "DNS resolution failed"

**Cause:** Domain DNS is not pointing to server

**Solution:**
1. Check DNS configuration:
   ```bash
   dig spiralcoin.net
   nslookup spiralcoin.net
   ```
2. Ensure A record points to your server IP
3. Wait for DNS propagation (up to 48 hours)
4. Use self-signed certificates for testing meanwhile

### Issue: "Port 80 is already in use"

**Cause:** Another service is using port 80

**Solution:**
```bash
# Find what's using port 80
sudo lsof -i :80
sudo netstat -tlnp | grep :80

# Stop the service temporarily
sudo systemctl stop nginx
# OR
docker compose down

# Then run setup-ssl.sh
```

### Issue: "Nginx is not installed"

**Solution:**
```bash
# Install nginx
sudo apt-get update
sudo apt-get install -y nginx

# OR use Docker nginx (already configured)
docker compose up -d nginx
```

### Issue: "Certificate verification failed"

**Cause:** Firewall blocking port 80/443

**Solution:**
```bash
# Check firewall
sudo ufw status

# Allow ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Or disable firewall temporarily
sudo ufw disable
```

---

## Testing Your SSL Configuration

### Test from command line:

```bash
# Test certificate
openssl s_client -connect www.spiralcoin.net:443 -servername www.spiralcoin.net

# Test HTTP to HTTPS redirect
curl -I http://www.spiralcoin.net

# Test HTTPS response
curl -I https://www.spiralcoin.net

# Check certificate details
echo | openssl s_client -servername www.spiralcoin.net \
  -connect www.spiralcoin.net:443 2>/dev/null | \
  openssl x509 -noout -text
```

### Test from browser:

1. Open https://www.spiralcoin.net in browser
2. Click the padlock icon
3. Check certificate details:
   - Issuer should be "Let's Encrypt" (or "R3")
   - Valid dates should be current
   - Domain should match www.spiralcoin.net

### Online SSL test:

Visit: https://www.ssllabs.com/ssltest/analyze.html?d=www.spiralcoin.net

Expected rating: A or A+

---

## Docker-Specific Configuration

### Ensure SSL volume is mounted:

Edit `compose.yaml` or `docker-compose.yaml`:

```yaml
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./public:/usr/share/nginx/html:ro
      - ./ssl:/etc/nginx/ssl:ro  # ← Ensure this line exists
    ports:
      - "80:80"
      - "443:443"
```

### Restart with fresh configuration:

```bash
docker compose down
docker compose up -d --force-recreate nginx
```

---

## Getting Help

If you're still experiencing issues:

1. **Check logs:**
   ```bash
   # Docker nginx logs
   docker compose logs nginx
   
   # System nginx logs
   sudo tail -f /var/log/nginx/error.log
   sudo tail -f /var/log/nginx/access.log
   
   # Certbot logs
   sudo tail -f /var/log/letsencrypt/letsencrypt.log
   ```

2. **Run verification:**
   ```bash
   bash scripts/verify-ssl.sh
   ```

3. **Check nginx configuration:**
   ```bash
   sudo nginx -t
   # OR
   docker compose exec nginx nginx -t
   ```

4. **Verify DNS:**
   ```bash
   dig spiralcoin.net
   dig www.spiralcoin.net
   ```

5. **Check firewall:**
   ```bash
   sudo ufw status
   sudo iptables -L -n | grep -E '80|443'
   ```

---

## Summary

**For Production (with domain DNS configured):**
```bash
sudo bash scripts/setup-ssl.sh
docker compose restart nginx
```

**For Development/Testing (without DNS):**
```bash
bash scripts/generate-self-signed-cert.sh
docker compose restart nginx
```

**To Verify:**
```bash
bash scripts/verify-ssl.sh
```

---

## Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [SSL Labs Testing Tool](https://www.ssllabs.com/ssltest/)

---

Last Updated: February 2, 2026
