# PowerShell Deployment Guide for Windows

## The Problem

You encountered errors because the deployment guide used **Bash syntax** that doesn't work in **PowerShell**:

- ❌ `&&` - Not valid in PowerShell (use `;` instead)
- ❌ `bash <(...)` - Process substitution not supported in PowerShell
- ❌ `/root/status.sh` - Linux path doesn't work on Windows

## The Solution

### Quick Start (3 Steps)

#### Step 1: Run Diagnostics

```powershell
.\scripts\deploy-fix.ps1
```

This will:
- ✅ Check if server is online
- ✅ Test SSH connectivity
- ✅ Show you the correct commands

#### Step 2: Connect to Server

```powershell
ssh root@174.138.37.6
```

When prompted, enter password: `HarLand2025!`

#### Step 3: Run Commands in SSH Session

Once connected, copy-paste these **ONE AT A TIME**:

```bash
# Command 1: Restart services
cd /root/spiralcoin && docker compose restart && docker compose ps

# Command 2: Deploy automation
bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)

# Command 3: Verify
/root/status.sh
```

---

## Troubleshooting

### Error: "Connection timed out"

**Cause**: Server is unreachable (port 22 not responding)

**Fix**:

1. **Check DigitalOcean Dashboard**:
   - Go to https://cloud.digitalocean.com
   - Verify droplet is **powered on** and **running**
   - Check if IP is still `174.138.37.6`

2. **Check Firewall**:
   - Droplet → Networking → Firewalls
   - Ensure SSH (port 22) is allowed

3. **Use Droplet Console**:
   - Click your droplet → "Console" button
   - Access server directly through browser
   - Run commands there if SSH fails

4. **Restart Droplet**:
   - Power → Reboot
   - Wait 2 minutes and try again

### Error: "Permission denied"

**Cause**: Wrong password or too many failed attempts

**Fix**:

```powershell
# Wait 2 minutes, then try again
ssh root@174.138.37.6
# Password: HarLand2025!
```

### Error: "&&" is not a valid statement separator

**Cause**: Using Bash syntax in PowerShell

**Fix**: DON'T run bash commands directly in PowerShell. Instead:

```powershell
# WRONG (in PowerShell terminal):
cd /root/spiralcoin && docker compose restart  # ❌ Error!

# RIGHT (connect to SSH first):
ssh root@174.138.37.6                          # ✅ Works!
# Then run commands in SSH session
```

### Error: "The '<' operator is reserved for future use"

**Cause**: Bash process substitution `<(...)` not supported in PowerShell

**Fix**: Run the command **inside an SSH session**, not in PowerShell directly:

```powershell
# WRONG (in PowerShell):
bash <(curl ...)  # ❌ Error!

# RIGHT:
ssh root@174.138.37.6
bash <(curl ...)  # ✅ Works inside SSH!
```

---

## Alternative: Use PuTTY (Windows-Native SSH)

If Windows SSH keeps failing, use PuTTY:

### Step 1: Install PuTTY

Download from: https://www.putty.org/

### Step 2: Connect

1. Open PuTTY
2. Enter:
   - **Host Name**: `174.138.37.6`
   - **Port**: `22`
   - **Connection Type**: SSH
3. Click **Open**
4. Login:
   - **Username**: `root`
   - **Password**: `HarLand2025!`

### Step 3: Run Commands

Same 3 commands from Quick Start Step 3 above.

---

## PowerShell-Compatible Commands

If you want to run commands from PowerShell without SSH session:

### Command 1: Restart Services

```powershell
ssh root@174.138.37.6 "cd /root/spiralcoin && docker compose restart && docker compose ps"
```

### Command 2: Deploy Automation

```powershell
ssh root@174.138.37.6 "curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh | bash"
```

### Command 3: Verify

```powershell
ssh root@174.138.37.6 "/root/status.sh"
```

**Note**: You'll be prompted for password for EACH command. This is why interactive SSH session is easier.

---

## Why This Happens

| Issue | Reason | Solution |
|-------|--------|----------|
| `&&` errors | PowerShell uses `;` not `&&` | Use SSH session for bash commands |
| `<()` errors | PowerShell doesn't support process substitution | Run inside SSH, not in PowerShell |
| Connection timeout | Server offline or firewall blocking | Check DigitalOcean dashboard |
| Permission denied | Password wrong or SSH locked | Wait 2 min, verify password |

---

## Current Server Status

Run this to check server health:

```powershell
.\scripts\quick-status.ps1
```

Expected output:
- ✅ SSH accessible
- ✅ 2-4 services running
- ❌ If all fail → server is down

---

## Complete Deployment Checklist

- [ ] Server powered on in DigitalOcean
- [ ] SSH port 22 accessible (test with `deploy-fix.ps1`)
- [ ] Connected via SSH successfully
- [ ] Ran Command 1: Services restarted
- [ ] Ran Command 2: Automation deployed
- [ ] Ran Command 3: Status verified
- [ ] All 4 containers show "Up"
- [ ] Cron jobs installed (`crontab -l`)

---

## Quick Reference Card

**Connect**:
```powershell
ssh root@174.138.37.6
# Password: HarLand2025!
```

**Restart**:
```bash
cd /root/spiralcoin && docker compose restart && docker compose ps
```

**Deploy**:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)
```

**Verify**:
```bash
/root/status.sh
```

**Check Cron**:
```bash
crontab -l
```

**Disconnect**:
```bash
exit
```

---

## Need Help?

1. **Run diagnostics**: `.\scripts\deploy-fix.ps1`
2. **Check server**: https://cloud.digitalocean.com
3. **Use Droplet Console**: Direct browser access if SSH fails
4. **Verify services**: `.\scripts\quick-status.ps1`

---

✅ **Server working?** → Use SSH session to run commands
⚠️ **Connection timeout?** → Check DigitalOcean dashboard
❌ **Nothing works?** → Use Droplet Console or restart droplet
