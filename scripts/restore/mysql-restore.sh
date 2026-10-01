#!/bin/bash
# RS Yasmin MySQL Restore Script
# Usage: ./mysql-restore.sh <backup-file.sql.gz>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file.sql.gz>"
    echo ""
    echo "Available backups:"
    ls -lh "$(dirname "$0")/../../backups/"*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Load environment
if [ -f "$(dirname "$0")/../../.env" ]; then
    source "$(dirname "$0")/../../.env"
fi

# Parse DATABASE_URL
DB_USER=$(echo $DATABASE_URL | sed -n 's/.*\/\/\([^:]*\):.*/\1/p')
DB_PASS=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')

DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}

echo "=== RS Yasmin MySQL Restore ==="
echo "WARNING: This will OVERWRITE existing data in database: $DB_NAME"
echo "Backup file: $BACKUP_FILE"
echo "Database: $DB_NAME"
echo "Host: $DB_HOST:$DB_PORT"
echo ""
read -p "Are you sure you want to continue? (type 'YES' to confirm): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""
echo "Starting restore..."
echo "Time: $(date)"

# Create backup of current state before restore
SAFETY_BACKUP="$(dirname "$0")/../../backups/pre-restore_$(date +%Y%m%d_%H%M%S).sql.gz"
echo "Creating safety backup: $SAFETY_BACKUP"
MYSQL_PWD=$DB_PASS mysqldump \
    --user=$DB_USER \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --single-transaction \
    $DB_NAME | gzip > "$SAFETY_BACKUP" || echo "Warning: Safety backup failed"

# Perform restore
echo "Restoring from: $BACKUP_FILE"
gunzip < "$BACKUP_FILE" | MYSQL_PWD=$DB_PASS mysql \
    --user=$DB_USER \
    --host=$DB_HOST \
    --port=$DB_PORT \
    $DB_NAME

echo ""
echo "=== Restore Complete ==="
echo "Database: $DB_NAME restored successfully"
echo "Safety backup: $SAFETY_BACKUP"
echo "Time: $(date)"
