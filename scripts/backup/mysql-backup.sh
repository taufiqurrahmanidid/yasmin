#!/bin/bash
# RS Yasmin MySQL Backup Script
# Usage: ./mysql-backup.sh [daily|weekly|manual]

set -e

# Load environment
if [ -f "$(dirname "$0")/../../.env" ]; then
    source "$(dirname "$0")/../../.env"
fi

BACKUP_TYPE=${1:-daily}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$0")/../../backups"
BACKUP_FILE="${BACKUP_DIR}/yasmin_${BACKUP_TYPE}_${TIMESTAMP}.sql.gz"
RETENTION_DAYS_DAILY=7
RETENTION_DAYS_WEEKLY=30

# Parse DATABASE_URL: mysql://user:pass@host:port/dbname
DB_USER=$(echo $DATABASE_URL | sed -n 's/.*\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')

# Fallback defaults
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}

echo "=== RS Yasmin MySQL Backup ==="
echo "Type: $BACKUP_TYPE"
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo "Time: $(date)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Perform backup with compression
echo "Starting backup..."
MYSQL_PWD=$DB_PASS mysqldump \
    --user=$DB_USER \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --compress \
    --quick \
    --skip-lock-tables \
    $DB_NAME | gzip > "$BACKUP_FILE"

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "✓ Backup completed: $BACKUP_FILE ($BACKUP_SIZE)"

# Cleanup old backups
if [ "$BACKUP_TYPE" = "daily" ]; then
    echo "Cleaning up daily backups older than $RETENTION_DAYS_DAILY days..."
    find "$BACKUP_DIR" -name "yasmin_daily_*.sql.gz" -mtime +$RETENTION_DAYS_DAILY -delete
elif [ "$BACKUP_TYPE" = "weekly" ]; then
    echo "Cleaning up weekly backups older than $RETENTION_DAYS_WEEKLY days..."
    find "$BACKUP_DIR" -name "yasmin_weekly_*.sql.gz" -mtime +$RETENTION_DAYS_WEEKLY -delete
fi

# List recent backups
echo ""
echo "Recent backups:"
ls -lh "$BACKUP_DIR" | tail -5

echo ""
echo "=== Backup Complete ==="
echo "File: $BACKUP_FILE"
echo "Size: $BACKUP_SIZE"
