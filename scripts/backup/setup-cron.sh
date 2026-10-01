#!/bin/bash
# Setup cron jobs for automated backups
# Run as: sudo ./setup-cron.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== RS Yasmin Backup Cron Setup ==="
echo "Project: $PROJECT_ROOT"
echo ""

# Cron entries
DAILY_BACKUP="0 2 * * * cd $PROJECT_ROOT && $SCRIPT_DIR/mysql-backup.sh daily >> $PROJECT_ROOT/logs/backup-daily.log 2>&1"
WEEKLY_BACKUP="0 3 * * 0 cd $PROJECT_ROOT && $SCRIPT_DIR/mysql-backup.sh weekly >> $PROJECT_ROOT/logs/backup-weekly.log 2>&1"

echo "Cron jobs to be added:"
echo "1. Daily backup: 02:00 WIB every day"
echo "2. Weekly backup: 03:00 WIB every Sunday"
echo ""
echo "$DAILY_BACKUP"
echo "$WEEKLY_BACKUP"
echo ""

read -p "Add to crontab? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Setup cancelled."
    exit 0
fi

# Backup current crontab
crontab -l > /tmp/crontab.backup 2>/dev/null || true

# Add new entries (avoid duplicates)
(crontab -l 2>/dev/null | grep -v "mysql-backup.sh"; echo "$DAILY_BACKUP"; echo "$WEEKLY_BACKUP") | crontab -

echo ""
echo "✓ Cron jobs added successfully"
echo ""
echo "Current crontab:"
crontab -l | grep mysql-backup.sh || echo "No backup cron jobs found"
echo ""
echo "Logs will be written to:"
echo "  - $PROJECT_ROOT/logs/backup-daily.log"
echo "  - $PROJECT_ROOT/logs/backup-weekly.log"
echo ""
echo "To remove cron jobs: crontab -e"
