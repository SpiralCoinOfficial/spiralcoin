# SpiralCoin Database Strategy

Three tiers — pick the one that matches the environment you are running in.

## 1. Dev (default) — SQLite

File-based, zero server, zero Docker, no credentials. Default for local
development.

```
DATABASE_URL=sqlite:///./data/sqlite/spiralcoin.db
```

- Data file location: `data/sqlite/spiralcoin.db` (created on first connect).
- The `data/sqlite/` directory is gitignored (see repo `.gitignore`).
- No setup required — just import a SQLite driver in app code and connect.

## 2. Local prod-parity stack (installed) — native Windows services

MariaDB and PostgreSQL are installed natively on this machine as Windows
services, both bound to `127.0.0.1` only. Credentials live in `db/.env`
(gitignored; see `.env.example` for the template).

### Installed engines

| Engine     | Version | Service name    | Port | Data dir                                |
| ---------- | ------- | --------------- | ---- | --------------------------------------- |
| MariaDB    | 12.3.2  | `MariaDB`       | 3306 | `C:\Program Files\MariaDB 12.3\data\`   |
| PostgreSQL | 16.6    | `postgresql-16` | 5432 | `C:\ProgramData\PostgreSQL\16\data\`    |

Each engine has a `spiralcoin` database owned by an unprivileged `spc_app`
user. The corresponding connection URLs are in `db/.env`:

```
MARIADB_URL=mysql://spc_app:****@127.0.0.1:3306/spiralcoin
POSTGRES_URL=postgresql://spc_app:****@127.0.0.1:5432/spiralcoin
```

### Service control

```powershell
# status
Get-Service MariaDB, postgresql-16

# start / stop (requires elevated PowerShell)
Start-Service MariaDB
Start-Service postgresql-16
Stop-Service  MariaDB
Stop-Service  postgresql-16
```

Both services are `StartType = Automatic`, so they come back after reboot.

### Smoke test

```powershell
# MariaDB
& 'C:\Program Files\MariaDB 12.3\bin\mysql.exe' -h 127.0.0.1 -u spc_app -p spiralcoin -e 'SELECT VERSION();'

# PostgreSQL  (set $env:PGPASSWORD first to avoid the prompt)
& 'C:\Program Files\PostgreSQL\16\bin\psql.exe' -h 127.0.0.1 -p 5432 -U spc_app -d spiralcoin -c 'SELECT version();'
```

### Engines NOT installed locally

`docker-compose.dbs.yml` still lists MySQL 8.4, Redis 7, and MongoDB 7. Those
are **not** installed natively — the `C:` drive does not have headroom for
Docker Desktop plus their volumes. If the app needs Redis, install
[Memurai](https://www.memurai.com/) (free Redis-compatible Windows service)
or use the managed Redis offering in tier 3.

## 3. Production — DigitalOcean managed databases

DigitalOcean deployment scripts already exist in this repo
(`digitalocean-deploy.ps1`, `DIGITALOCEAN_DEPLOYMENT_READY.md`). For
exchange-listing readiness, prefer DO Managed Databases over self-hosted:

- Daily automated backups, point-in-time recovery.
- Patched by DO (no manual security updates).
- TLS required by default.
- Connection pooling built in for Postgres.

Provision in the DO control panel, copy the connection URL DO gives you into
`db/.env` as `DATABASE_URL` (overwrites the SQLite default), and the app
picks it up.

---

### File map

```
db/
├── README.md                  (this file)
├── .env.example               (template; copy to .env, never commit .env)
├── .env                       (gitignored; real credentials for local engines)
├── docker-compose.dbs.yml     (legacy multi-engine stack; superseded for MariaDB+Postgres)
└── sqlite/                    (placeholder; runtime data lives in data/sqlite/)
```
