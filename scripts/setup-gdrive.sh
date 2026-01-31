#!/bin/bash
#
# Google Drive バックアップ連携セットアップ
# rclone を使用してバックアップをGoogle Driveに自動同期
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
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

echo "========================================"
echo "Google Drive バックアップ連携セットアップ"
echo "========================================"
echo ""

# rcloneがインストールされているか確認
if ! command -v rclone &> /dev/null; then
    log_warn "rclone がインストールされていません"
    echo ""
    echo "rclone はクラウドストレージと同期するためのツールです。"
    echo ""
    read -p "今すぐインストールしますか? (y/n): " install_confirm

    if [ "$install_confirm" = "y" ]; then
        if command -v brew &> /dev/null; then
            log_info "Homebrew で rclone をインストール中..."
            brew install rclone
        else
            log_info "rclone をダウンロード中..."
            curl https://rclone.org/install.sh | sudo bash
        fi
        log_info "rclone インストール完了"
    else
        echo ""
        echo "手動でインストールする場合:"
        echo "  brew install rclone"
        echo "または"
        echo "  curl https://rclone.org/install.sh | sudo bash"
        exit 1
    fi
fi

echo ""
log_info "rclone バージョン: $(rclone version | head -1)"
echo ""

# Google Drive設定の確認
if rclone listremotes | grep -q "gdrive:"; then
    log_info "Google Drive (gdrive) は既に設定されています"
    echo ""
    read -p "再設定しますか? (y/n): " reconfig
    if [ "$reconfig" != "y" ]; then
        GDRIVE_CONFIGURED=true
    fi
fi

if [ "$GDRIVE_CONFIGURED" != "true" ]; then
    echo ""
    echo "=== Google Drive の設定 ==="
    echo ""
    echo "これからブラウザが開き、Googleアカウントでログインを求められます。"
    echo "ログイン後、rclone にアクセス許可を与えてください。"
    echo ""
    read -p "準備ができたら Enter を押してください..."

    # rclone config で Google Drive を設定
    echo ""
    log_info "Google Drive を設定中..."
    echo ""
    echo "以下の質問に答えてください:"
    echo "  name> gdrive"
    echo "  Storage> drive (または番号で選択)"
    echo "  client_id> (空欄でEnter)"
    echo "  client_secret> (空欄でEnter)"
    echo "  scope> 1 (Full access)"
    echo "  root_folder_id> (空欄でEnter)"
    echo "  service_account_file> (空欄でEnter)"
    echo "  Edit advanced config> n"
    echo "  Use auto config> y"
    echo "  Configure as team drive> n"
    echo ""

    rclone config
fi

# 設定確認
echo ""
if ! rclone listremotes | grep -q "gdrive:"; then
    log_error "Google Drive (gdrive) が設定されていません"
    echo "rclone config を実行して 'gdrive' という名前で設定してください"
    exit 1
fi

log_info "Google Drive 接続テスト中..."
if rclone lsd gdrive: &> /dev/null; then
    log_info "接続成功！"
else
    log_error "接続失敗。rclone config で再設定してください"
    exit 1
fi

# バックアップフォルダ名の設定
echo ""
echo "=== Google Drive のバックアップフォルダ設定 ==="
echo ""
read -p "Google Drive上のフォルダ名 (デフォルト: SanyuTech_Backups): " GDRIVE_FOLDER
GDRIVE_FOLDER=${GDRIVE_FOLDER:-SanyuTech_Backups}

# フォルダ作成
log_info "Google Drive に ${GDRIVE_FOLDER} フォルダを作成中..."
rclone mkdir "gdrive:${GDRIVE_FOLDER}" 2>/dev/null || true

# 同期スクリプト作成
SYNC_SCRIPT="${SCRIPT_DIR}/sync-gdrive.sh"
cat > "$SYNC_SCRIPT" << EOF
#!/bin/bash
#
# Google Drive バックアップ同期
#

BACKUP_DIR="${BACKUP_DIR}"
GDRIVE_FOLDER="${GDRIVE_FOLDER}"
LOG_FILE="${PROJECT_DIR}/logs/gdrive-sync.log"

mkdir -p "${PROJECT_DIR}/logs"

echo "[\$(date '+%Y-%m-%d %H:%M:%S')] Google Drive 同期開始" >> "\$LOG_FILE"

# バックアップファイルをGoogle Driveにアップロード
if rclone sync "\$BACKUP_DIR" "gdrive:\$GDRIVE_FOLDER" --log-file="\$LOG_FILE" --log-level INFO; then
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] 同期完了" >> "\$LOG_FILE"
else
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] 同期失敗" >> "\$LOG_FILE"
    exit 1
fi
EOF

chmod +x "$SYNC_SCRIPT"
log_info "同期スクリプト作成: ${SYNC_SCRIPT}"

# バックアップスクリプトを更新して、バックアップ後に自動同期
echo ""
echo "=== 自動同期の設定 ==="
echo ""
echo "バックアップ完了後に自動でGoogle Driveに同期しますか？"
read -p "(y/n): " auto_sync

if [ "$auto_sync" = "y" ]; then
    # backup.shの最後に同期を追加するのではなく、cronに追加
    CURRENT_CRONTAB=$(crontab -l 2>/dev/null || echo "")

    if echo "$CURRENT_CRONTAB" | grep -q "sync-gdrive.sh"; then
        log_warn "Google Drive同期は既にcronに登録されています"
    else
        # バックアップの5分後に同期を実行
        SYNC_CRON="5 3 * * * ${SYNC_SCRIPT} >> ${PROJECT_DIR}/logs/gdrive-sync.log 2>&1"
        NEW_CRONTAB="${CURRENT_CRONTAB}
# SanyuTech DX Platform - Google Drive同期 (バックアップの5分後)
${SYNC_CRON}"
        echo "$NEW_CRONTAB" | crontab -
        log_info "cron に Google Drive 同期を追加しました（毎日 03:05）"
    fi
fi

# テスト同期
echo ""
read -p "今すぐテスト同期しますか? (y/n): " test_sync

if [ "$test_sync" = "y" ]; then
    log_info "テスト同期中..."
    if "$SYNC_SCRIPT"; then
        log_info "同期成功！"
        echo ""
        echo "Google Drive の ${GDRIVE_FOLDER} フォルダを確認してください:"
        rclone ls "gdrive:${GDRIVE_FOLDER}"
    else
        log_error "同期失敗"
    fi
fi

echo ""
echo "========================================"
echo "セットアップ完了"
echo "========================================"
echo ""
echo "=== 設定内容 ==="
echo "Google Drive フォルダ: ${GDRIVE_FOLDER}"
echo "同期タイミング: 毎日 03:05（バックアップの5分後）"
echo ""
echo "=== 管理コマンド ==="
echo "  ${SYNC_SCRIPT}           # 手動で同期"
echo "  rclone ls gdrive:${GDRIVE_FOLDER}  # Google Drive の内容確認"
echo "  tail -f logs/gdrive-sync.log       # 同期ログ確認"
echo ""
