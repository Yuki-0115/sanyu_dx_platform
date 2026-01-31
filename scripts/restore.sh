#!/bin/bash
#
# PostgreSQL リストアスクリプト
#

set -e

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_DIR}/backups"

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# バックアップ一覧表示
list_backups() {
    echo ""
    echo "=== 利用可能なバックアップ ==="
    echo ""

    local i=1
    BACKUP_FILES=()

    while IFS= read -r file; do
        local filename=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local date=$(echo "$filename" | sed 's/db_\([0-9]*\)_\([0-9]*\).*/\1 \2/' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\) \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
        echo -e "  ${CYAN}[$i]${NC} $filename (${size}) - ${date}"
        BACKUP_FILES+=("$file")
        ((i++))
    done < <(ls -t "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null)

    if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
        log_error "バックアップファイルが見つかりません"
        exit 1
    fi
    echo ""
}

# データベースリストア
restore_database() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        log_error "ファイルが見つかりません: $backup_file"
        exit 1
    fi

    log_info "リストア対象: $(basename "$backup_file")"

    cd "${PROJECT_DIR}"

    # 確認
    echo ""
    echo -e "${YELLOW}警告: この操作は現在のデータベースを完全に上書きします${NC}"
    echo ""
    read -p "本当にリストアしますか? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "キャンセルしました"
        exit 0
    fi

    log_info "リストア開始..."

    # 既存の接続を切断してDBを再作成
    log_info "既存の接続を切断中..."
    docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d postgres -c "
        SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE pg_stat_activity.datname = '${POSTGRES_DB}'
        AND pid <> pg_backend_pid();
    " 2>/dev/null || true

    log_info "データベースを再作成中..."
    docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};" 2>/dev/null
    docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE ${POSTGRES_DB};" 2>/dev/null

    log_info "データをリストア中..."
    if gunzip -c "$backup_file" | docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" 2>/dev/null; then
        log_info "リストア完了"
    else
        log_error "リストア失敗"
        exit 1
    fi

    echo ""
    log_info "Railsのマイグレーション確認..."
    docker compose exec -T platform bin/rails db:migrate:status 2>/dev/null | tail -20 || true
}

# n8nデータリストア
restore_n8n() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        log_error "ファイルが見つかりません: $backup_file"
        exit 1
    fi

    log_info "n8nリストア対象: $(basename "$backup_file")"

    cd "${PROJECT_DIR}"

    echo ""
    echo -e "${YELLOW}警告: この操作は現在のn8n設定を上書きします${NC}"
    echo ""
    read -p "本当にリストアしますか? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "キャンセルしました"
        exit 0
    fi

    log_info "n8nリストア開始..."

    # n8nコンテナを停止
    docker compose stop n8n

    # リストア
    cat "$backup_file" | docker compose run --rm -T n8n tar xzf - -C /home/node 2>/dev/null

    # n8nコンテナを再起動
    docker compose start n8n

    log_info "n8nリストア完了"
}

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [オプション] [ファイル]"
    echo ""
    echo "オプション:"
    echo "  -d, --db [file]    データベースをリストア"
    echo "  -n, --n8n [file]   n8nデータをリストア"
    echo "  -l, --list         バックアップ一覧表示"
    echo "  -i, --interactive  対話モード（ファイル選択）"
    echo "  -h, --help         このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0 --list                              # 一覧表示"
    echo "  $0 --interactive                       # 対話モードでリストア"
    echo "  $0 --db backups/db_20250130_120000.sql.gz  # 指定ファイルでリストア"
}

# 対話モード
interactive_mode() {
    list_backups

    read -p "リストアするバックアップ番号を入力 (1-${#BACKUP_FILES[@]}): " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#BACKUP_FILES[@]} ]; then
        log_error "無効な選択です"
        exit 1
    fi

    local selected_file="${BACKUP_FILES[$((choice-1))]}"
    restore_database "$selected_file"
}

# メイン処理
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--db)
                shift
                if [ -n "$1" ] && [ "${1:0:1}" != "-" ]; then
                    restore_database "$1"
                    shift
                else
                    log_error "ファイルを指定してください"
                    exit 1
                fi
                ;;
            -n|--n8n)
                shift
                if [ -n "$1" ] && [ "${1:0:1}" != "-" ]; then
                    restore_n8n "$1"
                    shift
                else
                    log_error "ファイルを指定してください"
                    exit 1
                fi
                ;;
            -l|--list)
                list_backups
                ;;
            -i|--interactive)
                interactive_mode
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
        shift 2>/dev/null || true
    done
}

echo "========================================"
echo "SanyuTech DX Platform リストア"
echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

main "$@"
