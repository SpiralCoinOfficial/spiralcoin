# 🌐 External Monitoring & UptimeRobot Setup

## Overview

Set up automated external monitoring so you get **alerts if your platform goes down**.

---

## 🎯 Why External Monitoring?

- **Early Warning**: Get alerts before users notice
- **Uptime Tracking**: 24/7 monitoring from multiple locations
- **Performance Data**: Track response times, availability
- **Peace of Mind**: Know your platform is healthy

---

## 🚀 UptimeRobot Setup (Free - 50 monitors)

### Step 1: Create Account
```
1. Go to https://uptimerobot.com
2. Click "Sign Up"
3. Enter email: your-email@example.com
4. Set password
5. Click verify email
```

### Step 2: Add First Monitor
```
1. Click "Add Monitor"
2. Type: HTTP(s)
3. Friendly Name: SpiralCoin Main
4. URL: https://174.138.37.6
   (or https://spiralcoin.net after DNS)
5. Check interval: 5 minutes
6. Click "Create Monitor"
```

### Step 3: Add Service Monitors
Create separate monitors for each service:

**Monitor 2: Web UI**
```
Name: SpiralCoin Web UI
URL: https://174.138.37.6:3000
Interval: 5 minutes
```

**Monitor 3: Backend API**
```
Name: SpiralCoin Backend API
URL: https://174.138.37.6:5000/health
Interval: 5 minutes
```

**Monitor 4: RPC Daemon**
```
Name: SpiralCoin RPC Daemon
URL: https://174.138.37.6:8545
Interval: 5 minutes
```

**Monitor 5: MarketFeed**
```
Name: SpiralCoin MarketFeed
URL: https://174.138.37.6:4000/health
Interval: 5 minutes
```

### Step 4: Set Up Alerts
```
1. For each monitor, click "Edit"
2. Go to "Alert Contacts"
3. Click "Add Alert"
4. Select notification method:
   - Email (free)
   - SMS (paid)
   - Discord (free)
   - Slack (free)
   - Telegram (free)
5. Add contact details
6. Save
```

### Step 5: Email Alerts
```
1. Click "Edit Monitor"
2. In "Alert contacts", select "Email"
3. Enter: your-email@example.com
4. Notifications:
   - ✓ When monitor goes down
   - ✓ When monitor goes back up
5. Save
```

### Step 6: Discord Alerts (Optional)
```
1. Create Discord server or use existing
2. Create #alerts channel
3. Get Discord webhook URL
4. UptimeRobot settings:
   - Alert Contacts
   - Add new contact
   - Type: Discord
   - Paste webhook URL
5. Test with button
```

---

## 📊 Monitor Dashboard

UptimeRobot provides:

```
Main Dashboard:
✓ SpiralCoin Main        99.9% uptime (5 monitors)
  ✓ Web UI               99.9% uptime
  ✓ Backend API          99.9% uptime
  ✓ RPC Daemon           99.9% uptime
  ✓ MarketFeed           99.9% uptime

Real-time Status:
🟢 All services online
📊 Response time: 145ms average
```

View detailed uptime graphs:
```
1. Dashboard → Monitor name
2. See uptime % for selected period
3. View incident history
4. Export uptime report (CSV)
```

---

## 📈 Uptime Reporting

### Get Uptime Stats
```
1. Dashboard → Select monitor
2. View "Last 24 hours", "Last 7 days", "Last 30 days"
3. Export to CSV/PDF (premium)
```

### Create Uptime Badge
```
1. Monitor → Settings
2. Scroll to "Badge"
3. Copy badge code for README:
   ![Uptime Robot ratio (7d)](https://img.shields.io/uptimerobot/ratio/7/m[YOUR-MONITOR-ID].svg)
```

### Share Status Page
```
1. Click "Share Status Page"
2. Get public URL for monitoring
3. Share with team/investors
4. Shows: Current status, last 90 days uptime
```

---

## 🔔 Alert Management

### Configure Alert Frequency
```
Edit Monitor → Alert settings:
- Alert me when: Down
- Don't re-alert for: 5 minutes
- After down for: 0 minutes (immediate)
```

### Manage Alert Contacts
```
Settings → Alert Contacts:
- Email: your-email@example.com (active)
- Discord: #alerts channel (active)
- SMS: +1-555-0100 (inactive)
```

### View Alert History
```
Dashboard → Monitor:
1. Click "Incidents"
2. See all down events
3. View response times
4. Export incident report
```

---

## 🔗 Public Status Page

Share with users/investors:

```
1. Monitors → Settings (gear icon)
2. Public Status Page
3. Copy URL: https://stats.uptimerobot.com/XXXXX
4. Customize:
   - Company name
   - Website
   - Color theme
   - Logo

Share URL with:
- Team members
- Investors
- API users
- Community
```

Example status page shows:
```
SpiralCoin Trading Platform

🟢 ALL SYSTEMS OPERATIONAL

Last 90 days: 99.9% uptime

Service Status:
🟢 Web UI       Online
🟢 Backend API  Online
🟢 RPC Daemon   Online
🟢 MarketFeed   Online

Maintenance: None scheduled
```

---

## 📱 Mobile Alerts

### Set Up Mobile Push (Premium)

OR use free alternatives:

**Telegram Alerts**
```
1. Search for @uptimerobot on Telegram
2. Click "Start"
3. Follow link to connect
4. Get instant mobile alerts
```

**Discord Alerts**
```
1. Install Discord app
2. Get notifications in phone
3. See all alerts instantly
```

**Slack Alerts**
```
1. Go to UptimeRobot Slack app
2. Click "Add to Workspace"
3. Select #alerts channel
4. Get Slack notifications
```

---

## 🎯 Monitoring Checklist

Set up:
- [ ] UptimeRobot account created
- [ ] Main monitor added (https://spiralcoin.net)
- [ ] 4 service monitors added (Web, API, RPC, Feed)
- [ ] Email alerts configured
- [ ] Discord/Slack alerts configured (optional)
- [ ] Status page shared
- [ ] Incident history reviewed
- [ ] Team members added

---

## 🔧 Local Monitoring Integration

### Connect with Local Health Checks

Your local health monitoring script (`/root/spiralcoin-monitor.sh`) provides:
- ✅ 5-minute health checks
- ✅ Service auto-restart
- ✅ Local logging

UptimeRobot provides:
- ✅ External verification
- ✅ 24/7 monitoring
- ✅ Alert notifications

**Best Practice**: Use both!
- Local: Fast detection & auto-recovery
- External: Verify from user perspective

---

## 🚨 Emergency Response

When UptimeRobot alerts you:

```bash
# 1. SSH to server
ssh root@174.138.37.6

# 2. Check status
/root/status.sh

# 3. Check logs
tail -20 /var/log/spiralcoin-monitor.log

# 4. Restart if needed
cd /root/spiralcoin
docker compose restart

# 5. Monitor recovery
/root/status.sh        # Repeat every 10 seconds
docker compose logs -f # View real-time logs
```

---

## 📊 Metrics to Track

UptimeRobot tracks:

| Metric | Normal | Warning | Critical |
|--------|--------|---------|----------|
| Uptime | 99.9%+ | 99%+ | <99% |
| Response Time | <200ms | 200-500ms | >500ms |
| Incident Count | 0 | 1-2/month | >2/month |
| Recovery Time | <5min | 5-30min | >30min |

---

## 🆘 Troubleshooting Alerts

### False Positive: Service Shows Down but Running Locally

```bash
# 1. Check actual service status
curl -v https://174.138.37.6:3000

# 2. Check firewall
sudo ufw status

# 3. Check DNS resolution
nslookup spiralcoin.net

# 4. Check SSL certificate
curl -v https://spiralcoin.net

# 5. Restart if needed
docker compose restart
```

### UptimeRobot Not Connecting

```
Possible causes:
1. Firewall blocking external connections
   → Check UFW rules allow incoming
2. Service not running
   → Run: docker compose ps
3. Port not exposed
   → Check docker-compose.yml ports
4. SSL certificate expired
   → Run: certbot renew
5. Service slow/timing out
   → Check system resources: top, df -h
```

### Stop False Alerts

```
1. Increase "Alert me after X minutes"
   - Prevents alerts for brief blips
2. Disable alerts during maintenance
   - Pause monitor, do maintenance, resume
3. Adjust timeout settings
   - Current: 30 seconds (standard)
   - Can increase to 60 seconds if slow
```

---

## 📋 Operations Workflow

**Daily**:
- 🌅 Check UptimeRobot status page
- 📊 Review any incidents
- 🔍 Check local status: `/root/status.sh`

**Weekly**:
- 📈 Review 7-day uptime report
- 📝 Document any issues
- ✅ Verify all alerts working

**Monthly**:
- 📊 Export uptime report
- 🔐 Review security logs
- 📋 Plan improvements

---

## 🎓 Best Practices

✅ **DO**:
- Set up multiple alert methods (email + Discord)
- Share status page with stakeholders
- Review incidents weekly
- Test alert system monthly
- Maintain backups

❌ **DON'T**:
- Ignore down alerts
- Disable alerts during production hours
- Let SSL certificates expire
- Ignore repeated incidents without investigating
- Run single monitoring source

---

## 🏆 Monitoring Stack Summary

| Layer | Tool | Purpose |
|-------|------|---------|
| **Local** | `monitor-health.sh` | 5-min checks, auto-restart |
| **External** | UptimeRobot | 24/7 monitoring, alerts |
| **Backups** | `backup-daily.sh` | Daily snapshots |
| **Logs** | Local files | Historical data |

---

## 📞 Support & Resources

- **UptimeRobot Help**: https://uptimerobot.com/contact
- **Discord Documentation**: https://discord.com/developers
- **Slack API**: https://api.slack.com

---

**Status**: Ready for external monitoring
**Time to Setup**: 10 minutes
**Cost**: Free (with paid options)
**Value**: Peace of mind + data-driven reliability
