# SpiralCoin - Developer Quick Reference
**Last Updated: December 16, 2025**

---

## 🚀 Quick Start

### Clone & Setup
```bash
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin
npm install
```

### Run Locally
```bash
# Development
npm start

# With Docker
docker-compose up -d

# Production
docker-compose -f docker-compose.prod.yaml up -d
```

---

## 🧪 Testing

```bash
# Run all tests
npm test                    # Compose validation
node e2e-test.js           # Full E2E suite (43 tests)
node validate-deployment.js # Deployment validation (39 checks)

# Expected: 82/82 tests pass (100%)
```

---

## 📊 API Endpoints

### Blockchain
```bash
GET  /api/blockchain/stats
POST /api/blockchain/send
GET  /api/blockchain/block/:id
```

### Wallet
```bash
POST /api/wallet/create
GET  /api/wallet/:address
GET  /api/wallet/:address/balance
```

### Market
```bash
GET  /api/market/data
GET  /api/market/price
GET  /api/market/history
```

### Mining
```bash
GET  /api/mining/status
POST /api/mining/start
POST /api/mining/stop
```

---

## 🔧 Docker Commands

```bash
# View logs
docker-compose logs -f backend
docker-compose logs -f daemon

# Restart services
docker-compose restart backend
docker-compose down && docker-compose up -d

# Scale services
docker-compose up -d --scale backend=3

# Clean up
docker-compose down -v  # WARNING: removes data
```

---

## 📁 Project Structure

```
spiralcoin/
├── src/                    # C++ source code
├── routes/                 # API routes
├── public/                 # Frontend files
├── data/                   # Blockchain & wallet data
├── Dockerfile*             # Container configs
├── docker-compose.yaml     # Development compose
├── docker-compose.prod.yaml # Production compose
├── CMakeLists.txt          # Build config
├── server.js               # Express server
└── package.json            # Dependencies
```

---

## 🔍 Ports & Services

| Service | Port | Status Check |
|---------|------|--------------|
| Frontend | 3000 | `curl http://localhost:3000` |
| Backend API | 5000 | `curl http://localhost:5000/health` |
| RPC Daemon | 8545 | `curl -X POST http://localhost:8545` |
| Market Feed | 4000 | `wscat -c ws://localhost:4000` |

---

## 📝 Common Tasks

### Build C++ Daemon
```bash
cd build
cmake --build .
./spiralcoind
```

### Update Dependencies
```bash
npm install
npm audit fix
```

### View Blockchain
```bash
cat data/blockchain.json | jq '.'
```

### Check Health
```bash
curl -s http://localhost:5000/health | jq '.'
```

---

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find process
lsof -i :5000

# Kill process
kill -9 <PID>
```

### Docker Issues
```bash
# Rebuild containers
docker-compose build --no-cache

# Reset volume
docker-compose down -v
docker-compose up -d
```

### Git Issues
```bash
# Check status
git status

# View logs
git log --oneline -10

# Stash changes
git stash
```

---

## 📚 Documentation Map

| Document | Purpose |
|----------|---------|
| `START_HERE.md` | Quick start |
| `README.md` | Project overview |
| `DEPLOYMENT_EXECUTION_GUIDE.md` | How to deploy |
| `FINAL_TEST_REPORT.md` | Test results |
| `SECURITY.md` | Security guide |
| `RECOVERY_PLAN.md` | Disaster recovery |
| `PRODUCTION_QUICK_REFERENCE.md` | Prod commands |

---

## ✅ Pre-Deployment Checklist

- [ ] Run tests: `node e2e-test.js`
- [ ] Validate config: `node validate-deployment.js`
- [ ] Check git: `git status` (should be clean)
- [ ] Review `.env` file
- [ ] Check disk space
- [ ] Verify Docker installed
- [ ] Test ports available

---

## 🎯 Key Commands

```bash
# Clone
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git

# Setup
cd spiralcoin && npm install

# Test
npm test && node e2e-test.js

# Deploy
docker-compose -f docker-compose.prod.yaml up -d

# Monitor
docker-compose logs -f

# Stop
docker-compose down
```

---

## 📞 Support

- **Issues**: GitHub Issues
- **Docs**: See documentation map above
- **Emergency**: See RECOVERY_PLAN.md

---

## 🎓 Learning Resources

- Express.js: https://expressjs.com
- Docker: https://docs.docker.com
- CMake: https://cmake.org/cmake/help/v3.22/
- Node.js: https://nodejs.org

---

**Status**: ✅ Production Ready
**Last Test**: 82/82 Passed (100%)
**Last Commit**: Main branch up to date
