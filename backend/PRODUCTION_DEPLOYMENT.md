# Gouanzouh Production Deployment Guide for Contabo VPS

## 📋 Overview
This guide covers complete deployment of the Gouanzouh sales & stock management system on a Contabo VPS with:
- PostgreSQL database
- Node.js + Express + TypeORM API
- Docker containerization
- Nginx reverse proxy
- Let's Encrypt TLS/SSL
- Systemd service automation

---

## 🚀 Pre-Deployment Checklist

- [ ] Domain registered and pointing to VPS IP
- [ ] VPS OS: Ubuntu 22.04 LTS (or similar)
- [ ] SSH access with key-based auth
- [ ] Contabo VPS has at least 2GB RAM, 30GB disk
- [ ] Git repository ready with latest code
- [ ] .env file prepared with production values
- [ ] JWT_SECRET generated (min 32 characters): `openssl rand -base64 32`

---

## 🔧 Phase 1: VPS Setup (One-Time)

### 1.1 Update system packages
```bash
ssh root@your.vps.ip
apt update && apt upgrade -y
```

### 1.2 Install Docker and Docker Compose
```bash
apt install -y docker.io docker-compose git curl

# Add user to docker group
usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker-compose --version
```

### 1.3 Configure firewall
```bash
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP (Nginx)
ufw allow 443/tcp     # HTTPS (Nginx)
```

### 1.4 Create application directory
```bash
mkdir -p /opt/gouanzouh
cd /opt/gouanzouh
git clone https://github.com/YOUR-USERNAME/gouanzouh.git backend
cd backend
```

---

## 📝 Phase 2: Configuration

### 2.1 Create production .env file
```bash
cat > /opt/gouanzouh/backend/.env << 'EOF'
NODE_ENV=production

# Database
DB_HOST=db
DB_PORT=5432
DB_USER=gouanzouh_user
DB_PASS=$(openssl rand -base64 32)  # Generate secure password
DB_NAME=gouanzouh

# JWT
JWT_SECRET=$(openssl rand -base64 32)  # Generate secure key
JWT_EXPIRATION=30d

# API
PORT=3000
API_URL=https://your.domain.com

# Logging
LOG_LEVEL=info

USE_SQLITE=false
EOF

chmod 600 /opt/gouanzouh/backend/.env
```

### 2.2 Update Nginx configuration
Edit `backend/nginx/conf.d/default.conf`:
- Replace `your.domain.com` with actual domain
- Verify upstream points to `api:3000`

### 2.3 Create certificate directories
```bash
mkdir -p /opt/gouanzouh/backend/nginx/certs
mkdir -p /opt/gouanzouh/backend/nginx/www
chmod 755 /opt/gouanzouh/backend/nginx/www
```

---

## 🐳 Phase 3: Docker Compose Deployment

### 3.1 Build and start services
```bash
cd /opt/gouanzouh/backend

# Build API image
docker-compose -f docker-compose.prod.yml build

# Start services (database, API, Nginx)
docker-compose -f docker-compose.prod.yml up -d

# Verify services
docker-compose -f docker-compose.prod.yml ps
```

### 3.2 Wait for database readiness
```bash
# Check database health
docker-compose -f docker-compose.prod.yml logs db

# Should see: "database system is ready to accept connections"
```

### 3.3 Run database migrations
```bash
# Run TypeORM migrations to create schema
docker-compose -f docker-compose.prod.yml exec api npm run migration:run

# Verify migrations completed
docker-compose -f docker-compose.prod.yml exec api npm run migration:show
```

---

## 🔐 Phase 4: SSL/TLS Certificate

### 4.1 Obtain Let's Encrypt certificate
```bash
cd /opt/gouanzouh/backend

# Make certbot script executable
chmod +x certbot-init.sh

# Run certificate initialization
./certbot-init.sh your.domain.com admin@your.domain.com
```

### 4.2 Verify certificate
```bash
# Check certificate details
ls -lah ./nginx/certs/live/your.domain.com/

# Should show: fullchain.pem and privkey.pem
```

### 4.3 Test HTTPS
```bash
curl -I https://your.domain.com
# Should return: HTTP/2 200 OK
```

---

## 🛠️ Phase 5: Systemd Service Automation

### 5.1 Install systemd unit file
```bash
# Copy service file
sudo cp /opt/gouanzouh/backend/gouanzouh.service /etc/systemd/system/

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable auto-start on reboot
sudo systemctl enable gouanzouh.service

# Start service
sudo systemctl start gouanzouh.service

# Check status
sudo systemctl status gouanzouh.service
```

### 5.2 View logs
```bash
# Real-time logs
journalctl -u gouanzouh.service -f

# Last 50 lines
journalctl -u gouanzouh.service -n 50

# Errors only
journalctl -u gouanzouh.service -p err
```

---

## ✅ Phase 6: Verification

### 6.1 Test API endpoints
```bash
# Health check (public endpoint)
curl https://your.domain.com/api/health

# Should return: {"status":"ok"}
```

### 6.2 Test authentication
```bash
# Register new user
curl -X POST https://your.domain.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123!",
    "firstName": "Test",
    "lastName": "User"
  }'

# Response should include JWT token
```

### 6.3 Monitor database
```bash
# Connect to database
docker-compose -f docker-compose.prod.yml exec db psql -U gouanzouh_user -d gouanzouh

# List tables
\dt

# Check users table
SELECT COUNT(*) FROM "user";

# Exit
\q
```

---

## 🔄 Phase 7: Automatic Certificate Renewal

### 7.1 Setup renewal cron job
```bash
# Add to crontab (runs daily at 3 AM)
0 3 * * * cd /opt/gouanzouh/backend && ./certbot-init.sh your.domain.com admin@your.domain.com

# Edit crontab
crontab -e
```

### 7.2 Alternative: Systemd timer
```bash
# Certbot auto-renewal (built-in)
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Check renewal status
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

---

## 📊 Ongoing Operations

### Database Backups
```bash
# Manual backup
docker-compose -f docker-compose.prod.yml exec db pg_dump \
  -U gouanzouh_user gouanzouh > backup-$(date +%Y%m%d).sql

# Restore backup
docker-compose -f docker-compose.prod.yml exec db psql \
  -U gouanzouh_user gouanzouh < backup-20231215.sql
```

### Update Application
```bash
# Pull latest code
cd /opt/gouanzouh/backend
git pull origin main

# Rebuild and redeploy
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Run any new migrations
docker-compose -f docker-compose.prod.yml exec api npm run migration:run
```

### View Real-Time Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Only API
docker-compose -f docker-compose.prod.yml logs -f api

# Only database
docker-compose -f docker-compose.prod.yml logs -f db
```

### Rotate JWT_SECRET (requires client re-login)
```bash
# 1. Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# 2. Update .env
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$NEW_SECRET/" /opt/gouanzouh/backend/.env

# 3. Restart API
docker-compose -f docker-compose.prod.yml restart api

# 4. All users must re-login to get new tokens
```

---

## 🚨 Troubleshooting

### Issue: Port 3000 already in use
```bash
# Find process on port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

### Issue: Database won't start
```bash
# Check database logs
docker-compose -f docker-compose.prod.yml logs db

# Restart database
docker-compose -f docker-compose.prod.yml restart db

# If data corrupted, reset (WARNING: deletes data)
docker-compose -f docker-compose.prod.yml down -v
docker volume rm gouanzouh_backend_db-data
```

### Issue: Certificate renewal failed
```bash
# Check renewal logs
sudo certbot renew --verbose

# Force renewal
sudo certbot renew --force-renewal

# Test renewal process
sudo certbot renew --dry-run
```

### Issue: High memory usage
```bash
# Check container resource usage
docker stats

# Restart all services
docker-compose -f docker-compose.prod.yml restart

# Increase memory limit in docker-compose.prod.yml
# Add: mem_limit: 2g
```

---

## 📈 Performance Optimization

### Database Connection Pooling
The PG driver automatically pools connections (default 10). Monitor in production:
```bash
# Check active connections
docker-compose -f docker-compose.prod.yml exec db psql -U gouanzouh_user -c \
  "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

### Nginx Caching (optional)
Add to `nginx/conf.d/default.conf` for static responses:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
proxy_cache_valid 200 10m;
add_header X-Cache-Status $upstream_cache_status;
```

### API Response Compression
Add to backend `src/index.ts`:
```typescript
import compression from 'compression';
app.use(compression());
```

---

## 🔐 Security Best Practices

1. **Firewall**: Only expose 22, 80, 443
2. **SSH**: Use key-based auth, disable password login
3. **Secrets**: Use `.env` file, never commit secrets
4. **CORS**: Update in backend if frontend on different domain
5. **Rate Limiting**: Add `express-rate-limit` for auth endpoints
6. **DB Password**: Use strong password in .env
7. **Backups**: Store backups off-server (S3, etc.)
8. **Monitoring**: Setup alerts for CPU, disk, memory

---

## 📞 Support Commands Quick Reference

```bash
# Status
systemctl status gouanzouh.service

# Start/Stop/Restart
systemctl start gouanzouh.service
systemctl stop gouanzouh.service
systemctl restart gouanzouh.service

# Logs
journalctl -u gouanzouh.service -f

# Docker status
docker-compose -f /opt/gouanzouh/backend/docker-compose.prod.yml ps

# Rebuild and redeploy
cd /opt/gouanzouh/backend
git pull origin main
docker-compose -f docker-compose.prod.yml up -d --build
docker-compose -f docker-compose.prod.yml exec api npm run migration:run
```

---

**Deployment complete! Your API is now live at https://your.domain.com**
