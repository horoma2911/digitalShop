# Production Files Generated - Quick Reference

## 🎯 All Files Created for Production Deployment

### Docker & Orchestration

#### `docker-compose.prod.yml` (🆕 NEW)
**Purpose**: Production-ready Docker Compose configuration
- PostgreSQL database with persistent volume `db-data`
- Node.js API service with health check
- Nginx reverse proxy with SSL support
- Environment variables injected from `.env`
- Services wait for database to be healthy before starting

**Usage**:
```bash
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs api
```

---

### Nginx Configuration

#### `nginx/conf.d/default.conf` (🆕 NEW)
**Purpose**: Nginx reverse proxy configuration
- HTTP → HTTPS redirect (port 80 → 443)
- SSL certificate paths for Let's Encrypt
- Upstream proxy to API container (api:3000)
- Security headers (X-Real-IP, X-Forwarded-For, etc.)
- Certbot ACME challenge endpoint
- TLS 1.2+ with strong ciphers

**Customize**: Replace `your.domain.com` with actual domain

**Usage**:
```bash
# Test nginx config
docker-compose -f docker-compose.prod.yml exec nginx nginx -t

# Reload nginx
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

---

### Systemd Service

#### `gouanzouh.service` (🆕 NEW)
**Purpose**: Systemd unit file for auto-start on VPS reboot
- Starts `docker-compose -f docker-compose.prod.yml up`
- Auto-restarts on failure
- Runs as root (adjust User= if needed)
- Sets working directory to `/opt/gouanzouh/backend`
- Logs captured by journalctl

**Installation**:
```bash
sudo cp gouanzouh.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gouanzouh.service
sudo systemctl start gouanzouh.service
```

**Monitoring**:
```bash
sudo systemctl status gouanzouh.service
journalctl -u gouanzouh.service -f
```

---

### TLS/SSL Certificate

#### `certbot-init.sh` (🆕 NEW)
**Purpose**: Automated Let's Encrypt certificate obtention & renewal
- Creates certificate directories
- Uses Certbot Docker image (no local Certbot needed)
- Handles ACME challenges via HTTP
- Creates renewal hook script
- Auto-restarts Nginx after renewal

**Usage**:
```bash
chmod +x certbot-init.sh
./certbot-init.sh your.domain.com admin@your.domain.com
```

**Auto-Renewal Setup**:
- Add to crontab: `0 3 * * * cd /opt/gouanzouh/backend && ./certbot-init.sh your.domain.com admin@your.domain.com`
- Or use systemd timer: `sudo systemctl enable certbot.timer`

**Certificate Storage**:
```
nginx/certs/live/your.domain.com/
  ├── fullchain.pem (used in Nginx)
  ├── privkey.pem (used in Nginx)
  ├── cert.pem
  └── chain.pem
```

---

### Database Migrations

#### `src/migrations/1700000000000-InitialSchema.ts` (🆕 NEW)
**Purpose**: TypeORM migration for database schema creation
- Creates all tables: user, shop, product, sale, expense
- Defines relationships and foreign keys
- Creates indexes for performance
- Includes up() and down() for rollback support

**Tables Created**:
- `user` - User accounts with roles
- `shop` - Shop/store management (belongs to user)
- `product` - Products in inventory (belongs to shop)
- `sale` - Sale transactions (belongs to product)
- `expense` - Business expenses (belongs to shop)

**Usage**:
```bash
# Run migrations (auto-runs on startup if migrationsRun: true)
npm run migration:run

# Check status
npm run migration:show

# Rollback last migration
npm run migration:revert
```

---

### Configuration Files

#### `ormconfig.ts` (✏️ MODIFIED)
**Changes**:
- Added `migrations: ['dist/migrations/**/*.js']`
- Added `migrationsRun: true` to auto-run on startup
- Changed `synchronize` to check `NODE_ENV !== 'production'`
- Added logging based on NODE_ENV

**Purpose**: Configures TypeORM for both development and production
- Dev: Uses SQLite or Postgres with synchronize=true
- Prod: Uses Postgres with migrations and synchronize=false

---

#### `package.json` (✏️ MODIFIED)
**New Scripts**:
```json
"typeorm": "typeorm-ts-node-esm",
"migration:generate": "npm run build && typeorm migration:generate",
"migration:create": "typeorm migration:create",
"migration:run": "npm run build && typeorm migration:run",
"migration:revert": "npm run build && typeorm migration:revert",
"migration:show": "typeorm migration:show"
```

**Usage**:
```bash
npm run migration:generate -- -n AddUserEmail
npm run migration:run
npm run migration:show
```

---

#### `.env.example` (✏️ MODIFIED)
**Purpose**: Template for environment variables
Contains all required env vars with default values

**Production Use**:
```bash
cp .env.example .env
# Edit .env with production values
chmod 600 .env
```

---

### Documentation

#### `MIGRATION_GUIDE.sh` (🆕 NEW)
**Purpose**: Interactive guide for database migrations
- Shows all migration commands
- Explains production workflow
- Provides Docker-based migration commands
- Includes troubleshooting tips

**Usage**:
```bash
bash MIGRATION_GUIDE.sh
```

---

#### `PRODUCTION_DEPLOYMENT.md` (🆕 NEW)
**Purpose**: Complete step-by-step deployment guide
- 7 phases: VPS setup, configuration, Docker, SSL, systemd, verification, operations
- Pre-deployment checklist
- Troubleshooting section
- Ongoing operations (backups, updates, monitoring)
- Security best practices
- Quick reference commands

**Phases**:
1. VPS Setup (Docker, firewall, git)
2. Configuration (.env, Nginx, SSL dirs)
3. Docker Compose (build & start services)
4. SSL/TLS (Let's Encrypt certificates)
5. Systemd (auto-start on reboot)
6. Verification (test endpoints)
7. Operations (backups, updates, logs)

---

## 📊 File Summary Table

| File | Type | Status | Purpose |
|------|------|--------|---------|
| `docker-compose.prod.yml` | Config | 🆕 NEW | Container orchestration |
| `nginx/conf.d/default.conf` | Config | 🆕 NEW | Web server & reverse proxy |
| `gouanzouh.service` | Systemd | 🆕 NEW | Auto-start on reboot |
| `certbot-init.sh` | Script | 🆕 NEW | SSL certificate management |
| `src/migrations/...InitialSchema.ts` | TypeORM | 🆕 NEW | Database schema creation |
| `ormconfig.ts` | Code | ✏️ MODIFIED | TypeORM configuration |
| `package.json` | Config | ✏️ MODIFIED | Migration scripts |
| `.env.example` | Config | ✏️ MODIFIED | Env variable template |
| `MIGRATION_GUIDE.sh` | Docs | 🆕 NEW | Migration reference |
| `PRODUCTION_DEPLOYMENT.md` | Docs | 🆕 NEW | Full deployment guide |

---

## 🚀 Quick Deployment Command Sequence

```bash
# 1. SSH to VPS
ssh root@your.vps.ip

# 2. Setup directories and clone repo
mkdir -p /opt/gouanzouh
cd /opt/gouanzouh
git clone https://github.com/YOUR-USERNAME/gouanzouh.git backend
cd backend

# 3. Create .env from template
cp .env.example .env
nano .env  # Edit with your values

# 4. Build and start
docker-compose -f docker-compose.prod.yml up -d

# 5. Wait for DB to be healthy (30 seconds)
docker-compose -f docker-compose.prod.yml logs db

# 6. Run migrations
docker-compose -f docker-compose.prod.yml exec api npm run migration:run

# 7. Setup SSL certificate
chmod +x certbot-init.sh
./certbot-init.sh your.domain.com admin@example.com

# 8. Install systemd service
sudo cp gouanzouh.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gouanzouh.service
sudo systemctl start gouanzouh.service

# 9. Verify
curl https://your.domain.com/api/health
```

---

## ⚠️ Important Reminders

- **Never commit `.env`** file to git (add to .gitignore)
- **Change default values**: JWT_SECRET, DB_PASS, domain name
- **Backup database regularly** before updates
- **Test migrations** in staging before production
- **Monitor logs** after deployment: `journalctl -u gouanzouh.service -f`
- **Keep certificates** current (auto-renewal runs daily)

---

**All files are production-ready. Follow PRODUCTION_DEPLOYMENT.md for step-by-step setup.**
