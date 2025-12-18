# RPC API

## Endpoint

- HTTP: `http://localhost:8545/rpc`

## Methods

- `getblockcount`: Returns current block height.
  - Request: `{ "jsonrpc":"2.0", "id":1, "method":"getblockcount", "params":[] }`
  - Response: `{ "result": <number> }`

- `getwalletinfo`: Returns wallet info.
  - Request: `{ "jsonrpc":"2.0", "id":2, "method":"getwalletinfo", "params":[] }`

- `getbalance`: Returns balance for address.
  - Request: `{ "jsonrpc":"2.0", "id":3, "method":"getbalance", "params":["<address>"] }`

Additional methods should follow JSON-RPC 2.0 conventions. Include parameters, types, and error codes.
