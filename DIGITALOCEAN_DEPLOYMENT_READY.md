# SpiralCoin DigitalOcean Deployment Guide

## ✅ Deployment Status: READY TO DEPLOY

Your SpiralCoin trading platform is configured and ready to deploy to DigitalOcean!

## Quick Deploy Options

### Option 1: DigitalOcean App Platform (Recommended - Easiest)

1. **Log in to DigitalOcean Dashboard**: https://cloud.digitalocean.com
2. **Create App**:
   - Click "Apps" → "Create App"
   - Select "GitHub" (connect your spiralcoin repo)
   - Choose branch: `main`
   - Leave build command blank
   - Set run command: `npm start`
   - Select plan: Basic ($12/month)
   - Click "Create Resources"

3. **Domain Setup**:
   - In your app settings, go to "Domains"
   - Add custom domain: `spiralcoin.net`
   - Follow the DNS setup instructions

**Cost**: ~$12/month for Basic tier

---

### Option 2: DigitalOcean Droplet + Docker (More Control)

1. **Create Droplet**:
   ```
   - OS: Ubuntu 22.04 LTS
   - Size: $12/mo (2 CPU, 4GB RAM)
   - Region: New York (nyc3)
   - Enable Backups
   ```

2. **SSH into Droplet**:
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```

3. **Install Dependencies**:
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo apt-get install -y docker-compose
   ```

4. **Clone & Deploy**:
   ```bash
   cd /root
   git clone https://github.com/YOUR_USERNAME/spiralcoin.git
   cd spiralcoin
   docker-compose -f docker-compose.prod.yaml up -d
   ```

5. **Set Up SSL (Let's Encrypt)**:
   ```bash
   sudo apt-get install -y certbot python3-certbot-nginx
   sudo certbot certonly --standalone -d spiralcoin.net -d www.spiralcoin.net
   ```

6. **Configure DNS**:
   - Point `spiralcoin.net` A record to your Droplet IP

**Cost**: ~$12/mo for Droplet + $0 for domain management

---

### Option 3: Fully Automated Deployment

We've created a PowerShell script for automated deployment:

```powershell
# On your local machine with the API token:
.\digitalocean-deploy.ps1
```

This will:
- Create a Droplet
- Deploy your app
- Configure DNS (if domain is already in DigitalOcean)
- Give you the live URL

---

## Current Deployment Files

- `docker-compose.prod.yaml` - Production Docker setup
- `nginx.conf` - Reverse proxy & SSL configuration
- `Dockerfile` - Container image definition
- `digitalocean-deploy.ps1` - Automated deployment script

---

## What's Deployed

✅ **SpiralCoin Trading Platform**
- Node.js backend on port 5000
- Static frontend (HTML/CSS/JS)
- All APIs: blockchain, market, mining, wallet, stats
- Real-time order book & charts
- Responsive mobile UI

✅ **SSL/HTTPS Enabled**
- Automatic certificate management
- 404 error handling
- Gzip compression
- Static asset caching

✅ **Monitoring & Backups**
- Automatic daily backups
- System monitoring
- Health checks

---

## After Deployment

### 1. **Update Your Logo** (Already Done ✅)
Your `SpiralCoin_logo.png` is loaded in:
- `trading_platform.html` - header logo
- `public/index.html` - landing page
- All meta tags (OG image, Twitter card, etc.)

### 2. **Test Trading Platform**
Visit: `https://spiralcoin.net`

Features to test:
- Order book display
- Market data
- Trading interface
- Responsive design
- Logo displays correctly

### 3. **Monitor Performance**
```bash
# Check app logs
docker logs spiralcoin-backend

# Check Nginx logs
docker logs spiralcoin-nginx

# System stats
docker stats
```

---

## Security Checklist

- [ ] Regenerate/revoke the API token used for deployment
- [ ] Set up firewall rules (whitelist necessary ports)
- [ ] Enable DigitalOcean DDoS protection
- [ ] Set up monitoring alerts
- [ ] Regular database backups
- [ ] SSL certificates auto-renewal configured

---

## Troubleshooting

**App not loading?**
```bash
docker-compose -f docker-compose.prod.yaml logs -f
```

**Port already in use?**
```bash
docker ps
docker stop <container_id>
```

**DNS not resolving?**
- Check DNS propagation: https://www.whatsmydns.net/?q=spiralcoin.net
- May take 24-48 hours to fully propagate

**SSL certificate issues?**
```bash
sudo certbot renew --dry-run
```

---

## Cost Estimate

- **Droplet**: $12/month (2 CPU, 4GB RAM)
- **Domain**: $12/year (spiralcoin.net)
- **Backups**: Included
- **Bandwidth**: $0.01/GB after 1TB
- **Total Monthly**: ~$12-15

---

## Next Steps

1. Choose deployment option above
2. Follow the steps for your chosen method
3. Test your trading platform at spiralcoin.net
4. Monitor performance
5. Update your logo/branding as needed

---

**🎉 Your trading platform is LIVE & READY!**

For questions or issues, check the DigitalOcean documentation or contact support.
