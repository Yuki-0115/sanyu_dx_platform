#!/bin/bash
#
# Google Drive テストアップロード
#

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# rclone確認
if ! command -v rclone &> /dev/null; then
    log_error "rcloneがインストールされていません"
    exit 1
fi

if ! rclone listremotes | grep -q "^gdrive:"; then
    log_error "gdriveリモートが設定されていません"
    exit 1
fi

echo "========================================"
echo "Google Drive テストアップロード"
echo "========================================"
echo ""

# テストファイル作成
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
TEST_FILE="/tmp/sanyu_test_${TIMESTAMP}.txt"

cat > "$TEST_FILE" << EOF
SanyuTech DX Platform テストファイル
======================================
作成日時: $(date '+%Y-%m-%d %H:%M:%S')
ホスト: $(hostname)

このファイルは自動テストで作成されました。
削除しても問題ありません。
EOF

log_info "テストファイル作成: $TEST_FILE"

# アップロード
REMOTE_PATH="gdrive:SanyuTech_DX/test_${TIMESTAMP}.txt"
log_info "アップロード中: $REMOTE_PATH"

if rclone copyto "$TEST_FILE" "$REMOTE_PATH"; then
    echo ""
    log_info "✅ テストアップロード成功！"
    echo ""
    echo "=== Google Drive の内容 ==="
    rclone ls "gdrive:SanyuTech_DX/" | grep test_ | head -5
    echo ""
    echo "Google Driveで確認してください:"
    echo "https://drive.google.com/drive/folders/SanyuTech_DX"
else
    log_error "❌ テストアップロード失敗"
    exit 1
fi

# クリーンアップ
rm -f "$TEST_FILE"
