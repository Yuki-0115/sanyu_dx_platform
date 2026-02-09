#!/bin/bash
#
# Google Drive バックアップ同期
# backup.shから呼び出されるか、単独で実行可能
#

set -e

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
LOG_DIR="${PROJECT_DIR}/logs"

# 環境変数読み込み
if [ -f "${PROJECT_DIR}/.env" ]; then
    source "${PROJECT_DIR}/.env"
fi
if [ -f "${PROJECT_DIR}/.env.local" ]; then
    source "${PROJECT_DIR}/.env.local"
fi

GDRIVE_BACKUP_FOLDER="${GDRIVE_BACKUP_FOLDER:-SanyuTech_Backups}"

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ログディレクトリ作成
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/gdrive-sync.log"

# rclone確認
if ! command -v rclone &> /dev/null; then
    log_error "rcloneがインストールされていません"
    exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -q "^gdrive:"; then
    log_error "gdriveリモートが設定されていません"
    echo "rclone config を実行してGoogle Driveを設定してください"
    exit 1
fi

echo "========================================"
echo "Google Drive バックアップ同期"
echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

log_info "同期先: gdrive:${GDRIVE_BACKUP_FOLDER}"
log_info "同期元: ${BACKUP_DIR}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Google Drive 同期開始" >> "$LOG_FILE"

# バックアップファイルをGoogle Driveにアップロード
if rclone sync "$BACKUP_DIR" "gdrive:${GDRIVE_BACKUP_FOLDER}" --log-file="$LOG_FILE" --log-level INFO; then
    log_info "同期完了"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 同期完了" >> "$LOG_FILE"
else
    log_error "同期失敗"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 同期失敗" >> "$LOG_FILE"
    exit 1
fi
