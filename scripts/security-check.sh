#!/bin/bash
#
# セキュリティチェックスクリプト
# rclone設定ファイルやその他の機密ファイルのセキュリティを確認・修正
#

set -e

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================"
echo "SanyuTech DX Platform セキュリティチェック"
echo "========================================"
echo ""

ISSUES_FOUND=0

# 1. rclone設定ファイルのパーミッションチェック
echo "=== rclone設定ファイル ==="
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"

if [ -f "$RCLONE_CONFIG" ]; then
    CURRENT_PERM=$(stat -f "%Lp" "$RCLONE_CONFIG" 2>/dev/null || stat -c "%a" "$RCLONE_CONFIG" 2>/dev/null)

    if [ "$CURRENT_PERM" = "600" ]; then
        log_info "rclone.conf のパーミッション: $CURRENT_PERM (正常)"
    else
        log_warn "rclone.conf のパーミッションが緩すぎます: $CURRENT_PERM"
        echo "    修正中..."
        chmod 600 "$RCLONE_CONFIG"
        log_info "chmod 600 に修正しました"
        ((ISSUES_FOUND++))
    fi

    # ディレクトリのパーミッションも確認
    RCLONE_DIR="$HOME/.config/rclone"
    DIR_PERM=$(stat -f "%Lp" "$RCLONE_DIR" 2>/dev/null || stat -c "%a" "$RCLONE_DIR" 2>/dev/null)

    if [ "$DIR_PERM" = "700" ]; then
        log_info "rcloneディレクトリのパーミッション: $DIR_PERM (正常)"
    else
        log_warn "rcloneディレクトリのパーミッションが緩すぎます: $DIR_PERM"
        echo "    修正中..."
        chmod 700 "$RCLONE_DIR"
        log_info "chmod 700 に修正しました"
        ((ISSUES_FOUND++))
    fi
else
    log_warn "rclone.conf が見つかりません"
fi

echo ""

# 2. .envファイルのチェック
echo "=== 環境変数ファイル ==="
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

for env_file in "$SCRIPT_DIR/.env" "$SCRIPT_DIR/.env.local"; do
    if [ -f "$env_file" ]; then
        ENV_PERM=$(stat -f "%Lp" "$env_file" 2>/dev/null || stat -c "%a" "$env_file" 2>/dev/null)

        if [ "$ENV_PERM" = "600" ] || [ "$ENV_PERM" = "644" ]; then
            log_info "$(basename $env_file) のパーミッション: $ENV_PERM"
        else
            log_warn "$(basename $env_file) のパーミッションを確認: $ENV_PERM"
        fi
    fi
done

echo ""

# 3. .gitignoreに機密ファイルが含まれているか確認
echo "=== .gitignore チェック ==="
GITIGNORE="$SCRIPT_DIR/.gitignore"

if [ -f "$GITIGNORE" ]; then
    REQUIRED_PATTERNS=(".env" ".env.local" "*.pem" "*.key" "rclone.conf")

    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if grep -q "$pattern" "$GITIGNORE" 2>/dev/null; then
            log_info "$pattern は .gitignore に含まれています"
        else
            log_warn "$pattern が .gitignore に含まれていません"
            ((ISSUES_FOUND++))
        fi
    done
else
    log_error ".gitignore が見つかりません"
    ((ISSUES_FOUND++))
fi

echo ""

# 4. バックアップディレクトリのパーミッション
echo "=== バックアップディレクトリ ==="
BACKUP_DIR="$SCRIPT_DIR/backups"

if [ -d "$BACKUP_DIR" ]; then
    BACKUP_PERM=$(stat -f "%Lp" "$BACKUP_DIR" 2>/dev/null || stat -c "%a" "$BACKUP_DIR" 2>/dev/null)

    if [ "$BACKUP_PERM" = "700" ] || [ "$BACKUP_PERM" = "750" ]; then
        log_info "backups/ ディレクトリのパーミッション: $BACKUP_PERM (正常)"
    else
        log_warn "backups/ ディレクトリのパーミッションが緩すぎます: $BACKUP_PERM"
        echo "    修正中..."
        chmod 750 "$BACKUP_DIR"
        log_info "chmod 750 に修正しました"
        ((ISSUES_FOUND++))
    fi
else
    log_info "backups/ ディレクトリはまだ作成されていません"
fi

echo ""

# 5. Dockerシークレットの確認
echo "=== Docker設定 ==="
DOCKER_COMPOSE="$SCRIPT_DIR/docker-compose.yml"

if [ -f "$DOCKER_COMPOSE" ]; then
    # ハードコードされたパスワードがないか確認
    if grep -E "(password|secret|token).*:.*['\"].*['\"]" "$DOCKER_COMPOSE" 2>/dev/null | grep -v '\${' > /dev/null; then
        log_warn "docker-compose.yml にハードコードされた機密情報がある可能性があります"
        ((ISSUES_FOUND++))
    else
        log_info "docker-compose.yml に明らかなハードコードはありません"
    fi
fi

echo ""

# 6. cronジョブのログファイル
echo "=== cronログファイル ==="
CRON_LOGS=("$SCRIPT_DIR/logs/backup.log" "$SCRIPT_DIR/logs/gdrive-sync.log")

for log_file in "${CRON_LOGS[@]}"; do
    if [ -f "$log_file" ]; then
        LOG_PERM=$(stat -f "%Lp" "$log_file" 2>/dev/null || stat -c "%a" "$log_file" 2>/dev/null)
        log_info "$(basename $log_file) のパーミッション: $LOG_PERM"
    fi
done

echo ""
echo "========================================"

if [ $ISSUES_FOUND -eq 0 ]; then
    log_info "セキュリティチェック完了: 問題なし"
else
    log_warn "セキュリティチェック完了: ${ISSUES_FOUND}件の問題を修正しました"
fi

echo ""
