#!/bin/bash
#
# PostgreSQL バックアップスクリプト
# 世代管理付き（デフォルト7日保持）
#

set -e

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"
RETENTION_DAYS=${RETENTION_DAYS:-7}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE_TODAY=$(date +%Y%m%d)

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 環境変数読み込み
if [ -f "${PROJECT_DIR}/.env" ]; then
    source "${PROJECT_DIR}/.env"
fi
if [ -f "${PROJECT_DIR}/.env.local" ]; then
    source "${PROJECT_DIR}/.env.local"
fi

# デフォルト値
POSTGRES_USER=${POSTGRES_USER:-sanyu}
POSTGRES_DB=${POSTGRES_DB:-sanyu_platform_development}

# 通知用Webhook URL（任意）
BACKUP_WEBHOOK_URL="${BACKUP_WEBHOOK_URL:-}"

# 暗号化設定（任意）
ENCRYPT_BACKUP="${ENCRYPT_BACKUP:-false}"
BACKUP_ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"

# Google Drive連携設定（任意）
GDRIVE_SYNC="${GDRIVE_SYNC:-false}"

# 通知送信関数
send_notification() {
    local message="$1"
    if [ -n "$BACKUP_WEBHOOK_URL" ]; then
        curl -s -X POST "$BACKUP_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": {\"type\": \"text\", \"text\": \"$message\"}}" \
            > /dev/null 2>&1 || true
    fi
}

# 暗号化関数（AES-256-CBC）
encrypt_file() {
    local input_file="$1"

    if [ "$ENCRYPT_BACKUP" != "true" ]; then
        echo "$input_file"
        return
    fi

    if [ -z "$BACKUP_ENCRYPTION_KEY" ]; then
        log_warn "BACKUP_ENCRYPTION_KEY未設定のため暗号化をスキップ"
        echo "$input_file"
        return
    fi

    local output_file="${input_file}.enc"
    log_info "暗号化中: $(basename "$input_file")"

    openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
        -in "$input_file" \
        -out "$output_file" \
        -pass env:BACKUP_ENCRYPTION_KEY

    rm -f "$input_file"
    log_info "暗号化完了: $(basename "$output_file")"
    echo "$output_file"
}

# Google Drive同期関数
sync_to_gdrive() {
    if [ "$GDRIVE_SYNC" != "true" ]; then
        return
    fi

    if ! command -v rclone &> /dev/null; then
        log_warn "rclone未インストールのためGoogle Drive同期をスキップ"
        return
    fi

    if ! rclone listremotes 2>/dev/null | grep -q "^gdrive:"; then
        log_warn "gdriveリモート未設定のためGoogle Drive同期をスキップ"
        return
    fi

    log_info "Google Driveに同期中..."

    local gdrive_folder="${GDRIVE_BACKUP_FOLDER:-SanyuTech_Backups}"

    if rclone sync "${BACKUP_DIR}" "gdrive:${gdrive_folder}" --log-level ERROR 2>/dev/null; then
        log_info "Google Drive同期完了"
    else
        log_warn "Google Drive同期に失敗しました"
    fi
}

# バックアップディレクトリ作成
mkdir -p "${BACKUP_DIR}"

# バックアップ実行
backup_database() {
    local backup_file="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"

    log_info "バックアップ開始: ${POSTGRES_DB}"
    log_info "出力先: ${backup_file}"

    cd "${PROJECT_DIR}"

    # Docker経由でpg_dump実行
    if docker compose exec -T postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" 2>/dev/null | gzip > "${backup_file}"; then
        local size=$(du -h "${backup_file}" | cut -f1)
        log_info "バックアップ完了: ${backup_file} (${size})"

        # 暗号化（有効な場合）
        backup_file=$(encrypt_file "${backup_file}")

        echo "${backup_file}"
    else
        log_error "バックアップ失敗"
        rm -f "${backup_file}"
        exit 1
    fi
}

# n8nデータのバックアップ
backup_n8n() {
    local n8n_backup_file="${BACKUP_DIR}/n8n_${TIMESTAMP}.tar.gz"

    log_info "n8nデータバックアップ開始"

    cd "${PROJECT_DIR}"

    # n8nボリュームからバックアップ
    if docker compose exec -T n8n tar czf - -C /home/node .n8n 2>/dev/null > "${n8n_backup_file}"; then
        local size=$(du -h "${n8n_backup_file}" | cut -f1)
        log_info "n8nバックアップ完了: ${n8n_backup_file} (${size})"

        # 暗号化（有効な場合）
        n8n_backup_file=$(encrypt_file "${n8n_backup_file}")
    else
        log_warn "n8nバックアップをスキップ（コンテナ未起動の可能性）"
        rm -f "${n8n_backup_file}"
    fi
}

# 古いバックアップの削除
cleanup_old_backups() {
    log_info "古いバックアップを削除中（${RETENTION_DAYS}日以上前）"

    local count=0

    # DBバックアップ（暗号化・非暗号化両方）
    while IFS= read -r -d '' file; do
        rm -f "$file"
        log_info "  削除: $(basename "$file")"
        ((count++)) || true
    done < <(find "${BACKUP_DIR}" -name "db_*.sql.gz" -mtime +${RETENTION_DAYS} -print0 2>/dev/null)

    while IFS= read -r -d '' file; do
        rm -f "$file"
        log_info "  削除: $(basename "$file")"
        ((count++)) || true
    done < <(find "${BACKUP_DIR}" -name "db_*.sql.gz.enc" -mtime +${RETENTION_DAYS} -print0 2>/dev/null)

    # n8nバックアップ（暗号化・非暗号化両方）
    while IFS= read -r -d '' file; do
        rm -f "$file"
        log_info "  削除: $(basename "$file")"
        ((count++)) || true
    done < <(find "${BACKUP_DIR}" -name "n8n_*.tar.gz" -mtime +${RETENTION_DAYS} -print0 2>/dev/null)

    while IFS= read -r -d '' file; do
        rm -f "$file"
        log_info "  削除: $(basename "$file")"
        ((count++)) || true
    done < <(find "${BACKUP_DIR}" -name "n8n_*.tar.gz.enc" -mtime +${RETENTION_DAYS} -print0 2>/dev/null)

    if [ $count -eq 0 ]; then
        log_info "  削除対象なし"
    else
        log_info "  ${count}ファイル削除完了"
    fi
}

# バックアップ一覧表示
list_backups() {
    log_info "バックアップ一覧:"
    echo ""
    echo "=== データベース ==="
    if ls "${BACKUP_DIR}"/db_*.sql.gz* 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/db_*.sql.gz* | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  バックアップなし"
    fi
    echo ""
    echo "=== n8n ==="
    if ls "${BACKUP_DIR}"/n8n_*.tar.gz* 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/n8n_*.tar.gz* | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  バックアップなし"
    fi
    echo ""
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -a, --all       全てバックアップ（DB + n8n）"
    echo "  -d, --db        データベースのみバックアップ"
    echo "  -n, --n8n       n8nデータのみバックアップ"
    echo "  -c, --cleanup   古いバックアップを削除"
    echo "  -l, --list      バックアップ一覧表示"
    echo "  -h, --help      このヘルプを表示"
    echo ""
    echo "環境変数:"
    echo "  RETENTION_DAYS         保持日数（デフォルト: 7）"
    echo "  ENCRYPT_BACKUP         暗号化有効化（true/false）"
    echo "  BACKUP_ENCRYPTION_KEY  暗号化キー（32文字以上推奨）"
    echo "  GDRIVE_SYNC            Google Drive同期（true/false）"
    echo "  GDRIVE_BACKUP_FOLDER   Google Driveフォルダ名（デフォルト: SanyuTech_Backups）"
    echo ""
    echo "例:"
    echo "  $0 --all                          # 全てバックアップ"
    echo "  $0 --db --cleanup                 # DBバックアップ後、古いファイル削除"
    echo "  ENCRYPT_BACKUP=true $0 --all      # 暗号化してバックアップ"
    echo "  GDRIVE_SYNC=true $0 --all         # Google Driveに同期"
}

# メイン処理
main() {
    local do_db=false
    local do_n8n=false
    local do_cleanup=false
    local do_list=false

    # 引数なしの場合はDBバックアップのみ
    if [ $# -eq 0 ]; then
        do_db=true
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            -a|--all)
                do_db=true
                do_n8n=true
                ;;
            -d|--db)
                do_db=true
                ;;
            -n|--n8n)
                do_n8n=true
                ;;
            -c|--cleanup)
                do_cleanup=true
                ;;
            -l|--list)
                do_list=true
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    echo "========================================"
    echo "SanyuTech DX Platform バックアップ"
    echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""

    if $do_list; then
        list_backups
    fi

    if $do_db; then
        backup_database
        echo ""
    fi

    if $do_n8n; then
        backup_n8n
        echo ""
    fi

    if $do_cleanup; then
        cleanup_old_backups
        echo ""
    fi

    # Google Drive同期（バックアップ実行時のみ）
    if $do_db || $do_n8n; then
        sync_to_gdrive
        echo ""
    fi

    log_info "完了"

    # 成功通知（DB or n8nバックアップ実行時のみ）
    if $do_db || $do_n8n; then
        local notify_msg="✅ バックアップ完了: $(date '+%Y-%m-%d %H:%M')"
        [ "$ENCRYPT_BACKUP" = "true" ] && notify_msg="${notify_msg} [暗号化]"
        [ "$GDRIVE_SYNC" = "true" ] && notify_msg="${notify_msg} [GDrive同期]"
        send_notification "$notify_msg"
    fi
}

# エラー時の通知
trap 'send_notification "❌ バックアップ失敗: $(date "+%Y-%m-%d %H:%M") - 確認してください"' ERR

main "$@"
