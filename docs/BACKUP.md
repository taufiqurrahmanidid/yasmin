# Backup & Restore - RS Yasmin

## Overview

Automated MySQL backup system dengan retention policy:
- **Daily backup**: 02:00 WIB, retention 7 hari
- **Weekly backup**: 03:00 WIB Minggu, retention 30 hari
- Kompresi gzip untuk efisiensi storage
- Safety backup sebelum restore

## Setup

### 1. Install Cron Jobs

```bash
cd /path/to/yasmin
sudo ./scripts/backup/setup-cron.sh
```

### 2. Manual Backup

```bash
# Daily backup
./scripts/backup/mysql-backup.sh daily

# Weekly backup
./scripts/backup/mysql-backup.sh weekly

# Manual backup (no retention cleanup)
./scripts/backup/mysql-backup.sh manual
```

### 3. Restore

```bash
# List available backups
ls -lh backups/

# Restore from backup
./scripts/restore/mysql-restore.sh backups/yasmin_daily_20261001_020000.sql.gz
```

**WARNING**: Restore akan overwrite database. Safety backup dibuat otomatis sebelum restore.

## File Locations

- **Backup files**: `./backups/yasmin_*.sql.gz`
- **Backup script**: `./scripts/backup/mysql-backup.sh`
- **Restore script**: `./scripts/restore/mysql-restore.sh`
- **Logs**: `./logs/backup-*.log`

## Monitoring

```bash
# Check cron jobs
crontab -l | grep mysql-backup

# View recent backups
ls -lht backups/ | head -10

# Check backup logs
tail -f logs/backup-daily.log
```

## Retention Policy

| Type | Schedule | Retention |
|------|----------|-----------|
| Daily | 02:00 WIB | 7 days |
| Weekly | 03:00 WIB Sunday | 30 days |
| Manual | On-demand | No auto-cleanup |

## Database Credentials

Scripts read from `.env` file:
```
DATABASE_URL=mysql://user:password@host:port/dbname
```

## Troubleshooting

### Backup fails: "command not found mysqldump"

```bash
# Install MySQL client
sudo apt-get install mysql-client
```

### Permission denied

```bash
chmod +x scripts/backup/*.sh scripts/restore/*.sh
```

### Disk space full

```bash
# Check backup directory size
du -sh backups/

# Manual cleanup old backups
find backups/ -name "*.sql.gz" -mtime +30 -delete
```

## Testing

```bash
# 1. Create test backup
./scripts/backup/mysql-backup.sh manual

# 2. Verify file created
ls -lh backups/yasmin_manual_*.sql.gz

# 3. Test restore (STAGING ONLY!)
./scripts/restore/mysql-restore.sh backups/yasmin_manual_*.sql.gz
```

**NEVER test restore on production without proper backup first!**

## Recovery Scenarios

### Accidental Data Delete

1. Stop application: `pm2 stop all`
2. Restore from latest backup
3. Verify data
4. Restart: `pm2 start all`

### Database Corruption

1. Identify last good backup
2. Restore from that backup
3. Replay any missing transactions (check application logs)

### Migration to New Server

1. Create manual backup on old server
2. Transfer backup file to new server
3. Setup database on new server
4. Restore backup
5. Update `.env` with new credentials
