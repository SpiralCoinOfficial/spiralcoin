# SpiralCoin DNS Configuration Guide

## ✅ Quick Verification Checklist

Before configuring DNS, verify your services are running:

```bash
# SSH into your server
ssh root@174.138.37.6

# Check all services
docker compose ps

# Test each service
curl http://localhost:3000          # Web UI
curl http://localhost:5000/health   # Backend API
curl http://localhost:8545          # RPC (test with curl -X POST if needed)
curl http://localhost:4000          # MarketFeed
```

---

## Step-by-Step DNS Configuration

### Step 1: Find Your Domain Registrar

Where did you purchase **spiralcoin.net**? Common options:
- **GoDaddy** → godaddy.com
- **Namecheap** → namecheap.com
- **Google Domains** → domains.google.com
- **AWS Route 53** → console.aws.amazon.com
- **Cloudflare** → cloudflare.com
- **Network Solutions** → networksolutions.com
- **Bluehost** → bluehost.com
- **Other** → Check your domain email receipt

### Step 2: Log Into Your Registrar

1. Go to your registrar's website
2. Sign in with your account
3. Find "Manage Domains" or "DNS Settings"

### Step 3: Update DNS Records

You need to create/update **2 records**:

#### Record 1: A Record (Primary Domain)
```
Type:               A
Name:               spiralcoin.net (or @ symbol)
Value (IPv4):       174.138.37.6
TTL:                3600 (or "Automatic")
Priority/Weight:    (leave blank)
Port:               (leave blank)
```

#### Record 2: CNAME Record (WWW Subdomain)
```
Type:               CNAME
Name:               www
Value (Target):     spiralcoin.net
TTL:                3600 (or "Automatic")
Priority/Weight:    (leave blank)
Port:               (leave blank)
```

### Step 4: Save and Verify

After saving:
1. **Wait 5-30 minutes** for changes to save
2. **Wait 24-48 hours** for full DNS propagation globally

### Step 5: Test DNS Resolution

Check if DNS is working:

```bash
# From your local machine (Windows PowerShell)
nslookup spiralcoin.net
nslookup www.spiralcoin.net

# Should show: 174.138.37.6

# Or use online tool: https://www.whatsmydns.net/?q=spiralcoin.net
```

---

## DNS Configuration by Registrar

### **GoDaddy**

1. Log in to godaddy.com
2. Click **Products** → **Domains**
3. Click your domain **spiralcoin.net**
4. Scroll to **DNS** section
5. Click **Manage DNS**
6. Look for existing **@ (A record)**
   - **If exists**: Click edit, change value to `174.138.37.6`
   - **If not**: Click **Add** → Type: A, Name: @, Value: 174.138.37.6
7. Look for **www (CNAME record)**
   - **If exists**: Click edit, change value to `spiralcoin.net`
   - **If not**: Click **Add** → Type: CNAME, Name: www, Value: spiralcoin.net
8. Click **Save**

### **Namecheap**

1. Log in to namecheap.com
2. Click **Domain List**
3. Click **Manage** next to spiralcoin.net
4. Click **Advanced DNS** tab
5. Find **Host Records** section
6. Edit or add these records:
   - Type: A, Host: @, Value: 174.138.37.6, TTL: 3600
   - Type: CNAME, Host: www, Value: spiralcoin.net, TTL: 3600
7. Click **Save all changes**

### **Google Domains**

1. Log in to domains.google.com
2. Click **spiralcoin.net** in your domains list
3. Click **DNS** in the left menu
4. Scroll to **Custom records**
5. Click **Create new record**
   - Type: A, Name: spiralcoin.net, TTL: 3600, Data: 174.138.37.6
   - Type: CNAME, Name: www.spiralcoin.net, TTL: 3600, Data: spiralcoin.net
6. Records save automatically

### **AWS Route 53**

1. Log in to AWS console
2. Go to **Route 53** → **Hosted zones**
3. Click your hosted zone for **spiralcoin.net**
4. Click **Create record**
   - Routing policy: Simple routing
   - Record name: spiralcoin.net (leave blank for root)
   - Record type: A
   - Value: 174.138.37.6
   - TTL: 3600
   - Click **Create record**
5. Repeat for www:
   - Record name: www
   - Record type: CNAME
   - Value: spiralcoin.net
   - TTL: 3600

### **Cloudflare**

1. Log in to cloudflare.com
2. Click your domain **spiralcoin.net**
3. Go to **DNS** tab
4. Click **Add record**
   - Type: A, Name: spiralcoin.net, IPv4: 174.138.37.6
   - Type: CNAME, Name: www, Target: spiralcoin.net
5. Keep **Proxy status** as "DNS only" (orange cloud icon)

---

## Verification After DNS Update

### Check DNS is Live

```bash
# From your local machine
nslookup spiralcoin.net
# Should show: 174.138.37.6

nslookup www.spiralcoin.net
# Should show: spiralcoin.net pointing to 174.138.37.6
```

### Test HTTPS Access

Once DNS propagates (24-48 hours):

```bash
# Test HTTPS (should work with valid SSL cert)
curl https://spiralcoin.net

# Test redirects
curl -L https://spiralcoin.net

# Test www subdomain
curl https://www.spiralcoin.net
```

### Browser Test

1. Open browser
2. Go to: `https://spiralcoin.net`
3. Should show:
   - **Green lock icon** (SSL secure)
   - Your trading platform UI
   - No certificate warnings

---

## Troubleshooting DNS Issues

### DNS Not Resolving

```bash
# Check if DNS is globally updated
# Go to: https://www.whatsmydns.net/?q=spiralcoin.net
# Shows DNS status across multiple servers worldwide

# If still showing old records:
# - Wait more time (up to 48 hours)
# - Clear your local DNS cache:
ipconfig /flushdns  # Windows
sudo dscacheutil -flushcache  # Mac
sudo systemctl restart systemd-resolved  # Linux
```

### CNAME Issues

If www subdomain doesn't work:
- Verify CNAME record target is exactly: `spiralcoin.net` (no www prefix)
- Ensure no other records conflict (no A record on www, only CNAME)

### SSL Certificate Not Recognized

If browser shows certificate warning:
- Let's Encrypt certificate is valid for: spiralcoin.net + www.spiralcoin.net
- Clear browser cache and try again
- Try different browser
- Check certificate with: `certbot certificates` (on server)

### Port Issues

If pages won't load after DNS works:
```bash
# SSH into server
ssh root@174.138.37.6

# Check if Nginx is running
systemctl status nginx

# Check if ports are listening
ss -tlnp | grep -E '80|443'

# Check Nginx logs
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

---

## Testing Timeline

| Time | What to Test | Expected Result |
|------|--------------|-----------------|
| **Now** | SSH to server, docker ps | Services running |
| **5 min** | nslookup from local machine | May still show old IP |
| **30 min** | nslookup again | Might show new IP |
| **1-4 hours** | Browser to https://spiralcoin.net | May work, may show "waiting" |
| **4-24 hours** | Global DNS checks | Most regions updated |
| **24-48 hours** | Full propagation | All regions updated |

---

## Live Verification Commands

Once DNS is live, run these from your server to confirm everything:

```bash
ssh root@174.138.37.6

# Check DNS points to this server
nslookup spiralcoin.net

# Test local services
curl -L https://localhost/api/health
curl http://localhost:3000

# Check Nginx
nginx -t
systemctl status nginx

# Check SSL certificate
certbot certificates
curl -I https://spiralcoin.net

# Check all Docker services
docker compose ps
docker compose logs -f
```

---

## Common Mistakes to Avoid

❌ **WRONG**:
- A record value: "www.spiralcoin.net" ← Should be IP address
- CNAME target: "spiralcoin.net." ← Don't add trailing dot (usually)
- Adding A record AND CNAME for www ← Use only CNAME for www
- Forgetting TTL ← Set to 3600
- Not waiting for propagation ← Can take 24-48 hours

✅ **RIGHT**:
- A record: spiralcoin.net → 174.138.37.6
- CNAME record: www → spiralcoin.net
- Set both to TTL 3600
- Wait for propagation
- Test with nslookup and browser

---

## Quick Command Reference

```bash
# After updating DNS, test with:
nslookup spiralcoin.net
dig spiralcoin.net
curl -I https://spiralcoin.net

# Monitor DNS propagation:
# https://www.whatsmydns.net/?q=spiralcoin.net

# Server status:
ssh root@174.138.37.6
docker compose ps
docker compose logs -f

# Certificate check:
certbot certificates
curl -v https://spiralcoin.net
```

---

## Next Steps

1. **Update DNS records** in your registrar (see sections above)
2. **Wait 24-48 hours** for full propagation
3. **Test with browser**: https://spiralcoin.net
4. **Monitor services**: `docker compose logs -f`
5. **Once live**: Monitor uptime, backups, security

---

## Support

If DNS configuration fails:
1. Check you're in the right registrar account
2. Verify you own the domain
3. Try clearing browser cache
4. Wait longer (DNS can take 48+ hours in some cases)
5. Contact your registrar's support

**Registrar Support Contacts**:
- GoDaddy: support.godaddy.com
- Namecheap: support.namecheap.com
- Google Domains: support.google.com/domains
- Cloudflare: support.cloudflare.com

---

## ✅ READY TO GO LIVE

Once DNS is configured and live, your SpiralCoin trading platform will be accessible at:

### **https://spiralcoin.net** 🚀

All services are running, SSL is configured, and everything is ready for traffic!
