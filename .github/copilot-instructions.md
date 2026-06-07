# SpiralCoin — Copilot Repository Instructions

A multi-language cryptocurrency platform. Read these conventions before generating code or
opening PRs.

## Stack overview

| Component        | Language / Runtime | Location                          | Default port |
| ---------------- | ------------------ | --------------------------------- | ------------ |
| Blockchain node  | C++ (CMake + EVMC) | `src/`, `include/`, `CMakeLists.txt` | RPC `8545`  |
| API server       | Node.js ESM        | `server.js`, `routes/`            | `5000`       |
| Market feed      | Node.js (WebSocket)| `marketfeed/`                     | `4000`       |
| Web dashboard    | Static HTML/JS     | `public/`, `web/`                 | `3000`       |
| Smart contracts  | Solidity + Hardhat 3 | `contracts/`                    | —            |
| DB scaffold      | MariaDB + Postgres | `db/`                             | `3306`, `5432` |
| Container builds | Docker / Compose   | `Dockerfile*`, `compose.yaml`     | —            |

Node version: 20+ (matches CI). All Node packages use ESM (`"type": "module"`).

## Conventions

- **Indentation**: 4 spaces for JS/TS/JSON/YAML; tabs not used.
- **Quotes**: double quotes in JS string literals (existing style); single quotes acceptable
  inside JSX/HTML-adjacent code.
- **Imports**: ES module syntax only in Node code (`import x from "y"`); never CommonJS
  in new files.
- **No `console.log` for secrets**: never log env vars, JWT contents, private keys,
  RPC credentials, or wallet seeds.
- **HTTP self-fetches are forbidden**: do not call the API's own routes via `fetch` using
  `req.protocol` / `req.get('host')` — extract a helper function instead. (Host header
  is attacker-controlled; this is SSRF.) See `getStatusData()` in `server.js` as the
  canonical pattern.
- **RPC URLs**: always sanitize/normalize external RPC URLs before use (see
  `sanitizeRpcUrl` + `normalizeRpcUrl` in `marketfeed/server.js`).
- **Commit messages**: Conventional Commits (`feat:`, `fix:`, `ci:`, `docs:`, `chore:`).
  Type scope is encouraged: `fix(server): ...`, `ci(super-linter): ...`.

## Build & test

```powershell
# Node API server (root)
npm install
npm start                  # http://localhost:5000

# Market feed
cd marketfeed
npm install
npm start

# Smart contracts
cd contracts
npm install
npx hardhat compile
npx hardhat test

# C++ daemon (Windows / Ninja)
scripts/fix-cmake-system.ps1            # one-time CMake fix
scripts/configure-and-build-ninja.ps1   # configure + build (-O1, -j1)
build-ninja/spiralcoind.exe --help
```

## CI workflows (`.github/workflows/`)

All workflows must stay green on `main`. Key files:

- `build.yml` — runs `markdownlint-cli2` (config: `.markdownlint-cli2.jsonc`),
  Node tests, Docker build sanity.
- `super-linter.yml` — `super-linter/super-linter@v8`. Many noisy validators
  (`BIOME_*`, `*_PRETTIER`, `CHECKOV`, `TRIVY`, `ZIZMOR`) are intentionally
  disabled because they duplicate dedicated workflows (`Container Scan`, `Bearer`,
  `CodeQL Advanced`, `SBOM`) or enforce styles not adopted here. Do not re-enable
  without project-wide cleanup first.
- `codeql.yml` — CodeQL Advanced (JS, Python, C/C++, Actions). `c-cpp` uses
  `build-mode: none` (autobuild fails on this codebase).
- `dependabot.yml` — present; let Dependabot PRs land via standard merge flow.

## Security

- Open `Dependabot` alerts must be fixed promptly. For transitive deps pinned by a
  parent (e.g. ethers pinning `ws@8.17.1`), add an npm `overrides` block to the
  closest `package.json`.
- Never commit `.env` files. `.env.example` is the template.
- All new HTTP routes that take user input must validate inputs at the boundary
  (status code, type, length) before passing to RPC / DB.

## Do NOT

- Modify shared workflow files (`scan-container.yml`, `sbom.yml`, `bearer.yml`,
  `codeql.yml`) without explicit reason; many are security-audit-tracked.
- Rewrite the C++ daemon source for style. Functional fixes only unless an issue
  explicitly requests refactoring.
- Add new top-level `*.md` status/report files. Use existing `docs/` or update
  `README.md`.
- Auto-format files you did not touch. Keep diffs minimal.

## Active areas of caution

- `marketfeed/server.js` — recent SSRF hardening (PR #13). Preserve the
  `EFFECTIVE_RPC_URL = normalizeRpcUrl(sanitizeRpcUrl(RPC_URL))` pattern.
- `server.js` — recent SSRF hardening for `/api/info`, `/api/exchange/info`,
  `/api/status` (use shared `getStatusData()`; never `fetch(${req.get('host')}...)`).
- `contracts/package.json` — `overrides.ws ^8.21.0` is intentional; do not remove.
