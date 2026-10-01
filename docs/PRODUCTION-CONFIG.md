# Production Config - RS Yasmin

## Environment Setup

### Development

```bash
NODE_ENV=development
JWT_SECRET=dev-secret-change-in-production
DATABASE_URL=mysql://user:password@localhost:3306/yasmin_rs
VITE_API_URL=http://localhost:8000
```

### Testing

```bash
NODE_ENV=test
JWT_SECRET=test-secret-key-for-ci-only
DATABASE_URL=mysql://user:password@localhost:3306/yasmin_test
VITE_API_URL=http://localhost:8000
```

### Production

```bash
NODE_ENV=production
JWT_SECRET=[REDACTED - 64 random chars]
DATABASE_URL=mysql://prod_user:[REDACTED]@db.rsyasmin.id:3306/yasmin_prod
VITE_API_URL=https://api.rsyasmin.id
DATABASE_SSL=true
LOG_LEVEL=info
RATE_LIMIT=100
RATE_LIMIT_WINDOW=15m
```

## Environment Variables

### Backend

| Variable | Dev | Test | Prod | Required |
|----------|-----|------|------|----------|
| NODE_ENV | development | test | production | ✓ |
| JWT_SECRET | dev-secret | test-secret | [REDACTED] | ✓ |
| DATABASE_URL | localhost | localhost | db.rsyasmin.id | ✓ |
| PORT | 8000 | 8000 | 8000 | ✗ |
| LOG_LEVEL | debug | silent | info | ✗ |
| RATE_LIMIT | 100 | 100 | 50 | ✗ |
| DATABASE_SSL | false | false | true | ✗ |

### Frontend

| Variable | Dev | Test | Prod | Required |
|----------|-----|------|------|----------|
| VITE_API_URL | http://localhost:8000 | http://localhost:8000 | https://api.rsyasmin.id | ✓ |
| VITE_ENV | development | test | production | ✗ |

## Configuration Files

### .env.development

```bash
NODE_ENV=development
JWT_SECRET=dev-secret-change-in-production
DATABASE_URL=mysql://yasmin_user:dev_password@localhost:3306/yasmin_rs
PORT=8000
LOG_LEVEL=debug
VITE_API_URL=http://localhost:8000
```

### .env.test

```bash
NODE_ENV=test
JWT_SECRET=test-secret-key-for-ci-only
DATABASE_URL=mysql://test_user:test_password@localhost:3306/yasmin_test
PORT=8000
LOG_LEVEL=silent
VITE_API_URL=http://localhost:8000
```

### .env.production

```bash
NODE_ENV=production
JWT_SECRET=[generate via: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"]
DATABASE_URL=mysql://[db_user]:[db_password]@[db_host]:3306/yasmin_prod
PORT=8000
LOG_LEVEL=info
DATABASE_SSL=true
DATABASE_CA=/etc/ssl/certs/ca-certificates.crt
RATE_LIMIT=50
RATE_LIMIT_WINDOW=15m
VITE_API_URL=https://api.rsyasmin.id
```

## Deployment

### Development

```bash
# Load environment
source .env.development

# Start server
pm2 start ecosystem.config.js --env development
```

### Production

```bash
# Load environment (from secure storage)
export $(cat /etc/yasmin/.env.prod | xargs)

# Generate Prisma client
npm run db:generate --prefix backend

# Start in cluster mode
pm2 start ecosystem.config.js --env production
```

## Security Checklist

- [ ] JWT_SECRET is 64+ random characters
- [ ] DATABASE_URL uses strong password (16+ chars, mixed case, numbers, symbols)
- [ ] DATABASE_SSL=true in production
- [ ] NODE_ENV=production (not development)
- [ ] .env files NOT committed to git
- [ ] HTTPS only in production
- [ ] CORS whitelist set to actual domain
- [ ] Rate limits configured per environment
- [ ] Log level set to info in production
- [ ] Database backups enabled
- [ ] Secrets stored in secure vault (not .env files)

## Starting Application

### Development

```bash
npm run dev --prefix frontend &
npm start --prefix backend &
```

### Production (PM2)

```bash
pm2 start ecosystem.config.js --env production --name yasmin-prod
pm2 save
pm2 startup
```

### Scaling

```bash
# Add more backend instances
pm2 scale yasmin-api +2

# Monitor
pm2 monitor
```

## Verification

```bash
# Check environment loaded
npm start --prefix backend 2>&1 | grep "Environment\|Database\|JWT"

# Health check
curl https://api.rsyasmin.id/health

# Verify headers
curl -i https://api.rsyasmin.id/health | grep -E "Strict|X-Frame|Content-Security"
```
