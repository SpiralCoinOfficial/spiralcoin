# SpiralCoin Local Stack Quick Start

This guide helps you run and verify the local backend and (optionally) the daemon.

## Steps

1. Copy environment:
   - Copy `.env.example` to `.env`
   - Adjust `RPC_URL` if your daemon runs elsewhere

2. Start services (one-click):
   - VS Code → Terminal → Run Task → `Start Local Stack (Backend + Daemon)`
   - Or PowerShell:
     ```powershell
     ./START_LOCAL_STACK.ps1
     ```

3. Verify endpoints:
   - Backend health:
     ```powershell
     Invoke-RestMethod http://127.0.0.1:5000/health | ConvertTo-Json -Depth 4
     ```
   - Aggregated status:
     ```powershell
     Invoke-RestMethod http://127.0.0.1:5000/api/status | ConvertTo-Json -Depth 6
     ```
   - RPC (if daemon is running):
     ```powershell
     $body = '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
     Invoke-RestMethod -Uri http://127.0.0.1:8545/rpc -Method Post -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 4
     ```

## Notes

- The backend defaults to `PORT=5000` and `RPC_URL=http://127.0.0.1:8545`.
- If your RPC URL does not include a path, the backend will call `/rpc` by default.
- To build the daemon locally, install MSVC Build Tools or MSYS2/MinGW and re-run `Start Local Stack`.
