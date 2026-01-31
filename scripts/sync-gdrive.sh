#!/bin/bash
#
# Google Drive バックアップ同期
#

BACKUP_DIR="/Users/watanabeyuki/workspace/sanyu_dx_platform/backups"
GDRIVE_FOLDER="SanyuTech_Backups"
LOG_FILE="/Users/watanabeyuki/workspace/sanyu_dx_platform/logs/gdrive-sync.log"

mkdir -p "/Users/watanabeyuki/workspace/sanyu_dx_platform/logs"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Google Drive 同期開始" >> "$LOG_FILE"

# バックアップファイルをGoogle Driveにアップロード
if rclone sync "$BACKUP_DIR" "gdrive:$GDRIVE_FOLDER" --log-file="$LOG_FILE" --log-level INFO; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 同期完了" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 同期失敗" >> "$LOG_FILE"
    exit 1
fi
