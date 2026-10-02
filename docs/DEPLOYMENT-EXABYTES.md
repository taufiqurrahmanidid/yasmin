# Deployment ke Exabytes EBiz Gold PRO v7 Shared Hosting

## Struktur Directory Exabytes

```
/home/username/
├── public_html/                 # Default domain (rsyasmin.id)
│   ├── index.html               # Frontend static build
│   ├── dist/
│   └── ...
├── subdomain_domain/            # Subdomain/domain lain
│   ├── public_html/
│   └── index.html
├── Node-Apps/                   # Node.js apps (managed by cPanel)
│   └── yasmin-api/              # Backend app directory
│       ├── app.js
│       ├── package.json
│       ├── ecosystem.config.js
│       └── ...
└── databases/                   # MySQL databases (via cPanel)
    └── yasmin_prod
```

---

## Pre-Deployment Requirements

### 1. Exabytes cPanel Access
- Login ke cPanel: https://cpanel.exabytes.co.id:2083
- Username: [dari Exabytes email]
- Password: [dari Exabytes email]

### 2. Domain Mapping
```
Primary Domain: rsyasmin.id → /home/username/public_html
API Domain:     api.rsyasmin.id → Node.js App (Port yang di-assign)
```

### 3. Prepare Files
```bash
cd /run/media/fiqq/Data/Project_Taufiq/web/yasmin/yasmin

# Backend production build
npm run build --prefix backend 2>&1 | tail -5

# Frontend production build
npm run build --prefix frontend
ls -lh frontend/dist/
```

---

## Step 1: Deploy Frontend (Static)

### 1.1 Build Frontend untuk Production

```bash
cd frontend
npm run build

# Output: dist/ folder dengan index.html, assets/
# Size: ~500KB-1MB
```

### 1.2 Upload ke Exabytes via FTP/cPanel File Manager

**Option A: Via cPanel File Manager**
```
1. Login cPanel → File Manager
2. Navigate ke public_html/
3. Upload folder dist/ contents:
   - index.html
   - assets/
   - vite.svg
   - favicon.ico
4. Klik "Upload"
```

**Option B: Via FTP Client (WinSCP/FileZilla)**
```bash
# Connection settings:
Host: ftp.rsyasmin.id (atau IP dari email Exabytes)
Username: username@rsyasmin.id
Password: FTP password dari cPanel
Port: 21

# Upload:
Local: frontend/dist/*
Remote: /public_html/
```

**Option C: Via Git (Recommended)**
```bash
# Setup git bare repo di cPanel
ssh username@rsyasmin.id
mkdir -p ~/deployments/yasmin.git
cd ~/deployments/yasmin.git
git init --bare
cat > hooks/post-receive << 'EOF'
#!/bin/bash
GIT_WORK_TREE=/home/username/public_html git checkout -f
cd /home/username/public_html
npm ci --prefix frontend --production
npm run build --prefix frontend
cp -r frontend/dist/* .
EOF
chmod +x hooks/post-receive

# Local: setup git remote
git remote add exabytes ssh://username@rsyasmin.id:22/home/username/deployments/yasmin.git
git push exabytes main
```

### 1.3 Verify Frontend

```bash
# Browser: https://rsyasmin.id
# Harus tampil login page RS Yasmin

# Check via curl
curl -I https://rsyasmin.id
# HTTP/2 200 OK
# Content-Type: text/html
```

---

## Step 2: Deploy Backend (Node.js App via cPanel)

### 2.1 Setup Node.js App via cPanel

**Via cPanel Dashboard:**
```
1. Login cPanel
2. Go to: Setup Node.js App (biasanya di Software section)
3. Click "Create Application"
4. Konfigurasi:
   - App Name: yasmin-api
   - Node Version: 20.x (latest stable)
   - Application Root: /home/username/Node-Apps/yasmin-api
   - Application Entry Point: app.js (atau server.js)
   - Application URL: api.rsyasmin.id
   - Port: (auto-assigned, biasanya 3000-4000 range)
   - SSL: HTTPS (auto)
```

**Output cPanel:**
```
App URL: https://api.rsyasmin.id
Port: 3456 (example)
Environment: production
```

### 2.2 Upload Backend ke Node-Apps Directory

**Via SSH (Recommended):**
```bash
# SSH ke Exabytes
ssh username@rsyasmin.id

# Navigate ke Node-Apps
cd ~/Node-Apps
mkdir -p yasmin-api
cd yasmin-api

# Clone atau upload files
git clone git@github.com:taufiqurrahmanidid/yasmin.git temp
cp -r temp/backend/* .
rm -rf temp

# Setup environment
cat > .env << 'EOF'
NODE_ENV=production
JWT_SECRET=[REDACTED - 64 random chars dari crypto.randomBytes(64).toString('hex')]
DATABASE_URL=mysql://prod_user:[REDACTED]@localhost:3306/yasmin_prod
PORT=3456
LOG_LEVEL=info
DATABASE_SSL=false
RATE_LIMIT=50
RATE_LIMIT_WINDOW=15m
VITE_API_URL=https://api.rsyasmin.id
EOF

# Install dependencies
npm ci --production

# Generate Prisma client
npx prisma generate

# Test startup (5 detik)
timeout 5 node server.js || true
```

**Verify di cPanel:**
```
cPanel → Setup Node.js App → yasmin-api
Status: Running ✓
Port: 3456
Uptime: XX seconds
```

### 2.3 Verify Backend

```bash
# Health check
curl -I https://api.rsyasmin.id/health

# Should return:
HTTP/2 200 OK
strict-transport-security: max-age=31536000
x-frame-options: DENY

# Full response
curl https://api.rsyasmin.id/health
# {"status":"OK","timestamp":"2026-10-02T01:32:38.563Z"}

# Check CORS (from frontend)
curl -H "Origin: https://rsyasmin.id" https://api.rsyasmin.id/health
# access-control-allow-origin: https://rsyasmin.id
```

---

## Step 3: Database Setup

### 3.1 Create Database via cPanel

**Via cPanel MySQL Databases:**
```
1. Login cPanel
2. Go to: MySQL Databases (atau MySQL Wizard)
3. Create Database:
   - Database Name: yasmin_prod
   - Full name: username_yasmin_prod
4. Create User:
   - Username: yasmin_prod_user
   - Password: [REDACTED - 16+ chars, mixed case, numbers, symbols]
   - Full name: username_yasmin_prod_user
5. Assign User to Database:
   - Select user + database
   - Privileges: ALL
```

### 3.2 Initialize Database Schema

```bash
# SSH ke Exabytes
ssh username@rsyasmin.id
cd ~/Node-Apps/yasmin-api

# Push schema ke database
DATABASE_URL="mysql://yasmin_prod_user:[REDACTED]@localhost:3306/username_yasmin_prod" \
npx prisma db push

# Verify (optional)
npx prisma studio
# Atau via MySQL command:
mysql -u yasmin_prod_user -p[password] username_yasmin_prod
mysql> SHOW TABLES;
# Harus tampil: User, Doctor, Patient, Appointment, etc.
```

### 3.3 Update Backend .env

```bash
# Update DATABASE_URL di Node.js app
cd ~/Node-Apps/yasmin-api
cat > .env << 'EOF'
NODE_ENV=production
JWT_SECRET=[REDACTED]
DATABASE_URL=mysql://yasmin_prod_user:[REDACTED]@localhost:3306/username_yasmin_prod
PORT=3456
LOG_LEVEL=info
DATABASE_SSL=false
RATE_LIMIT=50
RATE_LIMIT_WINDOW=15m
VITE_API_URL=https://api.rsyasmin.id
EOF

# Restart app via cPanel
cPanel → Setup Node.js App → yasmin-api → Restart
```

---

## Step 4: Domain & DNS Configuration

### 4.1 Exabytes cPanel Add-on Domains

**Primary Domain (rsyasmin.id):**
```
cPanel → Add-on Domains
Domain: rsyasmin.id
Document Root: /home/username/public_html/
```

**API Subdomain (api.rsyasmin.id):**
```
cPanel → Addon Domains atau Subdomains
Subdomain: api
Domain: rsyasmin.id
Document Root: /home/username/public_html/api/

ATAU

cPanel → DNS Zone Editor
Add A Record:
  - Name: api.rsyasmin.id
  - Type: A
  - TTL: 3600
  - Address: [Exabytes server IP]
```

### 4.2 SSL Certificate

```
Exabytes auto-provision Let's Encrypt SSL:
- rsyasmin.id ✓
- www.rsyasmin.id ✓
- api.rsyasmin.id ✓

Verify:
curl -I https://rsyasmin.id
HTTP/2 200 OK
# Certificate valid

OR force renewal:
cPanel → SSL/TLS Status → Manage Auto-Renewal
```

---

## Step 5: Test Deployment

### 5.1 Frontend Tests

```bash
# Test landing page
curl -I https://rsyasmin.id
# HTTP/2 200 OK

# Test SPA routing
curl https://rsyasmin.id/login | grep -o "<!DOCTYPE html>" || echo "SPA loaded"

# Browser test
# https://rsyasmin.id → tampil UI
# https://rsyasmin.id/login → SPA routing OK (no 404)
```

### 5.2 Backend API Tests

```bash
# Health endpoint
curl https://api.rsyasmin.id/health
# {"status":"OK","timestamp":"..."}

# CORS test (from frontend domain)
curl -H "Origin: https://rsyasmin.id" https://api.rsyasmin.id/health
# access-control-allow-origin: https://rsyasmin.id

# Rate limit test
for i in {1..55}; do 
  curl -s https://api.rsyasmin.id/health > /dev/null
done
curl https://api.rsyasmin.id/health
# {"error":"Terlalu banyak request..."}

# Database connection test (check logs)
ssh username@rsyasmin.id
cd ~/Node-Apps/yasmin-api
tail -50 logs/error.log
# Should show: "Connected to database" atau no errors
```

### 5.3 End-to-End Flow

```
1. User buka https://rsyasmin.id
2. Frontend load dari public_html/dist/
3. Click "Login"
4. Frontend call https://api.rsyasmin.id/auth/login
5. Backend query database
6. Return JWT token
7. Frontend save token, redirect ke dashboard
```

---

## Step 6: Backup & Monitoring

### 6.1 Automated Backup (cPanel)

```
cPanel → Backup
- Backup Frequency: Daily
- Backup Location: Download to FTP / Exabytes backup server
- Include:
  - Public HTML
  - Home Directory (/home/username)
  - MySQL Databases

Manual Backup:
cPanel → Full Backup
- Generate backup (1-2 jam)
- Download to local machine
```

### 6.2 Monitor Node.js App

```bash
# SSH ke Exabytes
ssh username@rsyasmin.id

# Check app status
ps aux | grep node
# yasmin-api process harus running

# Check logs
cd ~/Node-Apps/yasmin-api
tail -100 logs/error.log
tail -100 logs/access.log

# Check disk usage
du -sh ~/public_html
du -sh ~/Node-Apps/yasmin-api

# Check MySQL
mysql -u yasmin_prod_user -p[password] username_yasmin_prod -e "SELECT COUNT(*) FROM User;"
```

### 6.3 PM2 Monitoring (Optional)

```bash
# SSH ke Exabytes
ssh username@rsyasmin.id
cd ~/Node-Apps/yasmin-api

# Install PM2 globally
npm install -g pm2

# Start dengan PM2
pm2 start server.js --name yasmin-api --env production

# Monitor
pm2 monit
pm2 logs yasmin-api

# Auto-restart on reboot
pm2 startup
pm2 save
```

---

## Troubleshooting

### Issue: 502 Bad Gateway (API error)

```bash
# Check backend status
ssh username@rsyasmin.id
cPanel → Setup Node.js App → yasmin-api
# Status: Stopped?

# Restart
cPanel → Setup Node.js App → yasmin-api → Restart

# Check logs
tail -100 ~/Node-Apps/yasmin-api/logs/error.log
# Look for: PORT already in use, DATABASE_URL error, etc.

# Fix common issues:
1. PORT conflict: Check .env PORT vs cPanel assigned port
2. Database error: Verify DATABASE_URL credentials
3. Missing dependencies: npm ci --production
4. Prisma client: npx prisma generate
```

### Issue: 404 Not Found (Frontend)

```bash
# Check dist folder
ssh username@rsyasmin.id
ls -la ~/public_html/

# Should contain:
# - index.html
# - assets/
# - *.svg
# - favicon.ico

# If missing, rebuild & re-upload:
cd frontend
npm run build
# Upload dist/* to public_html/
```

### Issue: CORS Blocked

```bash
# Frontend logs:
# Access to XMLHttpRequest at 'https://api.rsyasmin.id' 
# from origin 'https://rsyasmin.id' blocked by CORS

# Check backend config:
ssh username@rsyasmin.id
cd ~/Node-Apps/yasmin-api
cat .env | grep VITE_API_URL
# Should be: VITE_API_URL=https://api.rsyasmin.id

# Check CORS header:
curl -H "Origin: https://rsyasmin.id" -I https://api.rsyasmin.id/health
# Should have: access-control-allow-origin: https://rsyasmin.id
```

### Issue: Database Connection Error

```bash
# Test database manually
ssh username@rsyasmin.id
mysql -u yasmin_prod_user -p[password] username_yasmin_prod
mysql> SELECT 1;
# If error: username/password wrong or database not created

# Fix:
1. Verify credentials di .env
2. cPanel → MySQL Databases → check user + database
3. Grant privileges:
   mysql> GRANT ALL PRIVILEGES ON username_yasmin_prod.* TO 'yasmin_prod_user'@'localhost';
   mysql> FLUSH PRIVILEGES;
```

---

## Directory Structure Summary

```
rsyasmin.id (Primary Domain)
├── /home/username/public_html/
│   ├── index.html (frontend static)
│   ├── assets/
│   └── dist/ (from npm run build)
│
api.rsyasmin.id (Node.js App)
├── /home/username/Node-Apps/yasmin-api/
│   ├── server.js
│   ├── package.json
│   ├── .env (production)
│   ├── prisma/
│   ├── routes/
│   └── logs/
│
Database
├── MySQL via cPanel
├── Database: username_yasmin_prod
├── User: yasmin_prod_user
```

---

## Rollback Plan

```bash
# If deployment fails:

# 1. Rollback frontend
ssh username@rsyasmin.id
rm -rf ~/public_html/dist ~/public_html/assets
# Upload previous version

# 2. Rollback backend
cPanel → Setup Node.js App → yasmin-api → Delete
# Setup new app with previous code from git tag

# 3. Rollback database
ssh username@rsyasmin.id
cd ~/
./scripts/restore/mysql-restore.sh backups/yasmin_prod_20261001.sql.gz

# Test
curl -I https://rsyasmin.id
curl -I https://api.rsyasmin.id/health
```

---

## Production Checklist

- [ ] Frontend build successful (npm run build --prefix frontend)
- [ ] Backend build successful (npm ci --production --prefix backend)
- [ ] .env.production configured with real credentials
- [ ] SSL certificates valid for rsyasmin.id + api.rsyasmin.id
- [ ] Database schema pushed (prisma db push)
- [ ] Frontend uploaded to /home/username/public_html/
- [ ] Backend uploaded to /home/username/Node-Apps/yasmin-api/
- [ ] Node.js app created in cPanel
- [ ] Health endpoint responds (curl https://api.rsyasmin.id/health)
- [ ] CORS headers present
- [ ] Rate limit working (test 55+ requests)
- [ ] Database credentials verified
- [ ] Backup configured in cPanel
- [ ] Monitoring setup (PM2 or cPanel monitoring)
- [ ] Tested full login flow (frontend → API → DB)
