#!/bin/bash
#
# cron自動バックアップセットアップ
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"
LOG_FILE="${PROJECT_DIR}/logs/backup.log"

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
mkdir -p "${PROJECT_DIR}/logs"

# 現在のcrontab取得
CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")

# 既存のエントリをチェック
if echo "$CURRENT_CRONTAB" | grep -q "$BACKUP_SCRIPT"; then
    log_warn "バックアップジョブは既に登録されています"
    echo ""
    echo "現在の設定:"
    echo "$CURRENT_CRONTAB" | grep "$BACKUP_SCRIPT"
    echo ""
    read -p "上書きしますか? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        log_info "キャンセルしました"
        exit 0
    fi
    # 既存のエントリを削除
    CURRENT_CRONTAB=$(echo "$CURRENT_CRONTAB" | grep -v "$BACKUP_SCRIPT")
fi

# バックアップ時刻の選択
echo ""
echo "=== バックアップ時刻の設定 ==="
echo ""
echo "  [1] 毎日 03:00 (推奨)"
echo "  [2] 毎日 00:00"
echo "  [3] 毎日 06:00"
echo "  [4] カスタム"
echo ""
read -p "選択してください (1-4): " choice

case "$choice" in
    1)
        CRON_TIME="0 3 * * *"
        TIME_DESC="毎日 03:00"
        ;;
    2)
        CRON_TIME="0 0 * * *"
        TIME_DESC="毎日 00:00"
        ;;
    3)
        CRON_TIME="0 6 * * *"
        TIME_DESC="毎日 06:00"
        ;;
    4)
        echo ""
        echo "cron形式で入力してください (例: 0 3 * * *)"
        read -p "時刻: " CRON_TIME
        TIME_DESC="カスタム: $CRON_TIME"
        ;;
    *)
        log_error "無効な選択です"
        exit 1
        ;;
esac

# 保持日数の設定
echo ""
read -p "バックアップ保持日数 (デフォルト: 7): " RETENTION
RETENTION=${RETENTION:-7}

# cronエントリ作成
CRON_ENTRY="${CRON_TIME} cd ${PROJECT_DIR} && RETENTION_DAYS=${RETENTION} ${BACKUP_SCRIPT} --all --cleanup >> ${LOG_FILE} 2>&1"

# crontabに追加
NEW_CRONTAB="${CURRENT_CRONTAB}
# SanyuTech DX Platform - 自動バックアップ (${TIME_DESC}, ${RETENTION}日保持)
${CRON_ENTRY}"

echo "$NEW_CRONTAB" | crontab -

echo ""
log_info "cronジョブを登録しました"
echo ""
echo "=== 設定内容 ==="
echo "時刻: ${TIME_DESC}"
echo "保持: ${RETENTION}日"
echo "ログ: ${LOG_FILE}"
echo ""
echo "=== 登録されたcronジョブ ==="
crontab -l | grep -A1 "SanyuTech" || true
echo ""

# 手動テスト確認
read -p "今すぐテスト実行しますか? (y/n): " test_confirm
if [ "$test_confirm" = "y" ]; then
    log_info "テスト実行中..."
    RETENTION_DAYS=${RETENTION} ${BACKUP_SCRIPT} --all --cleanup
fi

echo ""
log_info "セットアップ完了"
echo ""
echo "=== 管理コマンド ==="
echo "  crontab -l          # 現在の設定を確認"
echo "  crontab -e          # 設定を編集"
echo "  tail -f ${LOG_FILE}  # ログを確認"
