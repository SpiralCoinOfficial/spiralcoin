# SpiralCoin

A complete cryptocurrency implementation featuring a C++ blockchain daemon with EVM integration, Node.js API server, real-time market data feeds, and a web dashboard.

## Features

- **Full Blockchain Node**: C++ daemon with EVM compatibility
- **REST API**: Complete RPC interface for blockchain operations
- **Mining Engine**: Built-in block mining with reward system
- **Wallet Management**: Secure address and balance management
- **Web Dashboard**: Real-time blockchain monitoring interface
- **Market Data Feed**: WebSocket-based price feeds and external data integration
- **Docker Support**: Containerized deployment ready

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Dashboard │    │   API Server    │    │  Market Feed    │
│     (HTML/JS)   │◄──►│   (Node.js)     │◄──►│   (WebSocket)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │ Blockchain Node │
                    │    (C++)        │
                    └─────────────────┘
```

## Quick Start

### Using Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin

# Build and run with Docker Compose
docker-compose up --build
```

The services will be available at:
- Web Dashboard: http://localhost:3000
- API Server: http://localhost:5000
- Market Feed: http://localhost:4000

### Manual Installation

#### Prerequisites
- Node.js 18+
- CMake 3.10+
- C++17 compatible compiler
- Boost libraries
- OpenSSL

#### Windows (MSYS2 MinGW) Quick Start

1. Install MSYS2: https://www.msys2.org/
2. In the MSYS2 terminal (MINGW64):
  ```bash
  pacman -Syu
  pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-nlohmann-json
  ```
3. In VS Code, select the `Win32-MinGW` C/C++ configuration (status bar) and run the default build task "Build SpiralCoin (MinGW g++)".
4. Or run the helper script in PowerShell:
  ```powershell
  ./scripts/build_windows_mingw.ps1
  ```
5. Run the daemon: `build/spiralcoind.exe`

#### Build Steps

1. **Build C++ Daemon**
```bash
# Install system dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y build-essential libssl-dev libboost-all-dev nlohmann-json3-dev

# Build the daemon
cd build
cmake ..
make

# Run the daemon
./spiralcoind
```

2. **Setup Node.js Services**
```bash
# Install dependencies
npm install

# Create environment file
cp .env.example .env
# Edit .env with your configuration

# Start the API server
npm start

# In another terminal, start market feed
cd marketfeed
npm install
npm start
```

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# API Server
PORT=5000
NODE_ENV=production

# Market Feed
RPC_URL=http://127.0.0.1:8545
EXT_FEED=https://api.example.com/feed
NODE_PORT=4000
```

### Wallet Setup

The daemon automatically creates a primary wallet address. To customize:

1. Edit `start_spiralcoin.sh` and set your `WALLET_ADDRESS`
2. The daemon will mine blocks and credit rewards to this address

## API Endpoints

### Blockchain Operations
- `GET /api/blockchain` - Get blockchain data
- `POST /api/mining` - Mine a new block
- `POST /api/mining/transaction` - Add transaction to pending pool

### Wallet Operations
- `GET /api/wallet/balance/:address` - Get address balance

### Statistics
- `GET /api/stats` - Get network statistics

### Market Data
- `GET /api/market/feed` - Get current market data
- WebSocket connection for real-time updates

## RPC Interface

The daemon provides a JSON-RPC interface on port 8545:

```bash
# Get block count
curl -X POST http://localhost:8545/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'

# Send transaction
curl -X POST http://localhost:8545/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"sendtoaddress","params":["recipient_address", 100]}'
```

## Security

- SSH access is configured with dual ports (22 primary, 2222 fallback) and secure password
- Sensitive data is excluded from version control
- Rate limiting enabled on API endpoints
- CORS configured for web dashboard access

## Deployment

### Production Server Setup

1. **Enable SSH Access**
```bash
# On your server, run the provided script
chmod +x enable_root_ssh.sh
sudo ./enable_root_ssh.sh
```

2. **Deploy with Docker**
```bash
# On your server
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin
docker-compose -f compose.yaml up -d
```

3. **Systemd Service (Alternative)**
```bash
# Install systemd service
sudo cp spiralcoind.service /etc/systemd/system/
sudo systemctl enable spiralcoind
sudo systemctl start spiralcoind
```

## Development

### Project Structure
```
spiralcoin/
├── src/                 # C++ source files
├── include/            # C++ headers
├── routes/             # Node.js API routes
├── marketfeed/         # Market data service
├── public/             # Web dashboard assets
├── data/               # Blockchain data (gitignored)
├── build/              # Build artifacts
├── Dockerfile          # Container definition
├── docker-compose.yml  # Service orchestration
└── package.json        # Node.js dependencies
```

### Adding New Features

1. **C++ Extensions**: Add to `src/` and `include/`
2. **API Endpoints**: Add routes in `routes/` directory
3. **Frontend**: Modify files in `public/`
4. **Market Data**: Extend `marketfeed/server.js`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the documentation
- Review the API endpoints
3. **Post-deploy health check**
```bash
# From your workstation (PowerShell)
pwsh -File scripts/prod_health_check.ps1 -Server 174.138.37.6

# Or on the server (bash)
cd /root/spiralcoin
bash scripts/prod_health_check.sh
```
