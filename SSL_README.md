# SSL Certificate Quick Reference

## Common SSL Errors and Fixes

### ERR_CERT_AUTHORITY_INVALID

**Error Message:**
```
Your connection isn't private
Attackers might be trying to steal your information
net::ERR_CERT_AUTHORITY_INVALID
```

**Quick Fix:**

```bash
# One-line fix for production:
sudo bash scripts/setup-ssl.sh && docker compose restart nginx

# One-line fix for development:
bash scripts/generate-self-signed-cert.sh && docker compose restart nginx
```

**Interactive Fix:**
```bash
bash fix-ssl.sh
```

---

## SSL Setup Options

### 🏆 Production (Recommended)

Use Let's Encrypt for trusted SSL certificates:

```bash
sudo bash scripts/setup-ssl.sh
```

**Requirements:**
- Domain DNS pointing to server
- Ports 80 and 443 open
- Root/sudo access

**Benefits:**
- ✅ Trusted by all browsers
- ✅ Free forever
- ✅ Automatic renewal
- ✅ No browser warnings

---

### 🔧 Development/Testing

Use self-signed certificates for local development:

```bash
bash scripts/generate-self-signed-cert.sh
```

**Benefits:**
- ✅ Works without DNS
- ✅ Quick to generate
- ✅ Good for testing

**Note:** Will show browser security warnings (expected)

---

## Verification

Check your SSL setup:

```bash
bash scripts/verify-ssl.sh
```

This checks:
- Certificate files exist
- Certificates are valid
- Not expired
- Correct permissions
- HTTPS responding

---

## Troubleshooting

### Certificate not found
```bash
# Generate self-signed for immediate use
bash scripts/generate-self-signed-cert.sh
docker compose restart nginx
```

### Certificate expired
```bash
# Renew Let's Encrypt certificate
sudo certbot renew
sudo cp /etc/letsencrypt/live/spiralcoin.net/*.pem ./ssl/
docker compose restart nginx
```

### Browser still shows error
1. Clear browser cache
2. Try incognito mode
3. Check certificate dates
4. Verify DNS configuration

---

## Files

- **fix-ssl.sh** - Interactive SSL fix tool
- **scripts/setup-ssl.sh** - Production SSL setup
- **scripts/generate-self-signed-cert.sh** - Development SSL
- **scripts/verify-ssl.sh** - SSL verification
- **SSL_FIX_GUIDE.md** - Complete troubleshooting guide

---

## Quick Commands

```bash
# Interactive fix menu
bash fix-ssl.sh

# Production setup
sudo bash scripts/setup-ssl.sh

# Development setup
bash scripts/generate-self-signed-cert.sh

# Verify SSL
bash scripts/verify-ssl.sh

# Restart nginx
docker compose restart nginx

# Test HTTPS
curl -I https://www.spiralcoin.net

# View certificate
openssl x509 -in ssl/fullchain.pem -text -noout
```

---

## Help

For detailed instructions, see: [SSL_FIX_GUIDE.md](SSL_FIX_GUIDE.md)
