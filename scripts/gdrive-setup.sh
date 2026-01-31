#!/bin/bash
#
# Google Drive フォルダ構造セットアップ
#

set -e

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    echo "make backup-gdrive を実行してください"
    exit 1
fi

echo "========================================"
echo "Google Drive フォルダ構造セットアップ"
echo "========================================"
echo ""

ROOT="gdrive:SanyuTech_DX"

# メインフォルダ
folders=(
    ""
    "案件"
    "経費"
    "月次帳票"
    "安全書類"
    "日報写真"
)

for folder in "${folders[@]}"; do
    if [ -z "$folder" ]; then
        path="$ROOT"
    else
        path="$ROOT/$folder"
    fi

    if rclone mkdir "$path" 2>/dev/null; then
        log_info "作成: $path"
    fi
done

echo ""
log_info "フォルダ構造の作成が完了しました"
echo ""
echo "=== 作成されたフォルダ ==="
rclone lsd "$ROOT" 2>/dev/null || echo "(フォルダ一覧を取得できませんでした)"
