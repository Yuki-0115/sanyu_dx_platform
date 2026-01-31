# ===========================================
# SanyuTech DX Platform - 開発自動化
# ===========================================

include .env
export

# Colors
GREEN := \033[1;32m
YELLOW := \033[1;33m
RED := \033[1;31m
NC := \033[0m

.PHONY: help
help: ## ヘルプ表示
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf " $(GREEN)%-22s$(NC) %s\n", $$1, $$2}'

# ===========================================
# サービス管理
# ===========================================

.PHONY: up
up: ## 全サービス起動
	@echo "$(GREEN)Starting all services...$(NC)"
	docker compose up -d
	@echo "$(GREEN)Platform: http://localhost:$(PLATFORM_PORT)$(NC)"
	@echo "$(GREEN)Worker Web: http://localhost:$(WORKER_WEB_PORT)$(NC)"
	@echo "$(GREEN)n8n: http://localhost:$(N8N_PORT)$(NC)"

.PHONY: down
down: ## 全サービス停止
	docker compose down

.PHONY: restart
restart: down up ## 全サービス再起動

.PHONY: logs
logs: ## 全サービスログ表示
	docker compose logs -f

.PHONY: ps
ps: ## サービス状態確認
	docker compose ps

.PHONY: clean
clean: ## クリーンアップ（注意：データ削除）
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	docker compose down -v --rmi local --remove-orphans
	@echo "$(GREEN)Cleaned up.$(NC)"

# ===========================================
# Platform（基幹アプリ）
# ===========================================

.PHONY: platform-new
platform-new: ## Platform: Railsアプリ新規作成
	@if [ -d "rails/platform" ]; then \
		echo "$(YELLOW)Platform already exists.$(NC)"; \
	else \
		docker compose run --rm platform bash -c " \
			rails new /platform \
				--database=postgresql \
				--css=tailwind \
				--skip-docker \
				--skip-test \
			&& cd /platform \
			&& bundle add devise \
			&& bundle add pagy \
			&& bundle add rspec-rails --group development,test \
			&& bundle add factory_bot_rails --group development,test \
		"; \
	fi

.PHONY: platform-up
platform-up: ## Platform: 起動
	docker compose up -d platform
	@echo "$(GREEN)Platform: http://localhost:$(PLATFORM_PORT)$(NC)"

.PHONY: platform-logs
platform-logs: ## Platform: ログ表示
	docker compose logs -f platform

.PHONY: platform-shell
platform-shell: ## Platform: シェル接続
	docker compose exec platform bash

.PHONY: platform-console
platform-console: ## Platform: Railsコンソール
	docker compose exec platform bin/rails console

.PHONY: platform-migrate
platform-migrate: ## Platform: マイグレーション実行
	docker compose exec platform bin/rails db:migrate

.PHONY: platform-seed
platform-seed: ## Platform: シードデータ投入
	docker compose exec platform bin/rails db:seed

.PHONY: platform-reset
platform-reset: ## Platform: DB リセット
	docker compose exec platform bin/rails db:reset

.PHONY: platform-routes
platform-routes: ## Platform: ルーティング確認
	docker compose exec platform bin/rails routes

.PHONY: platform-test
platform-test: ## Platform: テスト実行
	docker compose exec platform bundle exec rspec

# ===========================================
# Worker Web（作業員向けWeb）
# ===========================================

.PHONY: worker-new
worker-new: ## Worker Web: Railsアプリ新規作成
	@if [ -d "rails/worker_web" ]; then \
		echo "$(YELLOW)Worker Web already exists.$(NC)"; \
	else \
		docker compose run --rm worker-web bash -c " \
			rails new /worker_web \
				--database=postgresql \
				--css=tailwind \
				--skip-docker \
				--skip-test \
		"; \
	fi

.PHONY: worker-up
worker-up: ## Worker Web: 起動
	docker compose up -d worker-web
	@echo "$(GREEN)Worker Web: http://localhost:$(WORKER_WEB_PORT)$(NC)"

.PHONY: worker-logs
worker-logs: ## Worker Web: ログ表示
	docker compose logs -f worker-web

.PHONY: worker-shell
worker-shell: ## Worker Web: シェル接続
	docker compose exec worker-web bash

.PHONY: worker-console
worker-console: ## Worker Web: Railsコンソール
	docker compose exec worker-web bin/rails console

# ===========================================
# PostgreSQL
# ===========================================

.PHONY: postgres-up
postgres-up: ## PostgreSQL: 起動
	docker compose up -d postgres
	@echo "$(GREEN)PostgreSQL is running on port $(POSTGRES_PORT)$(NC)"

.PHONY: postgres-logs
postgres-logs: ## PostgreSQL: ログ表示
	docker compose logs -f postgres

.PHONY: postgres-shell
postgres-shell: ## PostgreSQL: psql接続
	docker compose exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

# ===========================================
# バックアップ/リストア
# ===========================================

.PHONY: backup
backup: ## バックアップ: DB + n8n（世代管理付き）
	@chmod +x scripts/backup.sh
	@scripts/backup.sh --all --cleanup

.PHONY: backup-db
backup-db: ## バックアップ: DBのみ
	@chmod +x scripts/backup.sh
	@scripts/backup.sh --db

.PHONY: backup-list
backup-list: ## バックアップ: 一覧表示
	@chmod +x scripts/backup.sh
	@scripts/backup.sh --list

.PHONY: restore
restore: ## リストア: 対話モード
	@chmod +x scripts/restore.sh
	@scripts/restore.sh --interactive

.PHONY: restore-list
restore-list: ## リストア: バックアップ一覧表示
	@chmod +x scripts/restore.sh
	@scripts/restore.sh --list

.PHONY: postgres-backup
postgres-backup: backup-db ## PostgreSQL: バックアップ（backup-dbのエイリアス）

.PHONY: backup-cron
backup-cron: ## バックアップ: 自動バックアップ設定（cron）
	@chmod +x scripts/setup-cron.sh
	@scripts/setup-cron.sh

.PHONY: backup-gdrive
backup-gdrive: ## バックアップ: Google Drive連携設定
	@chmod +x scripts/setup-gdrive.sh
	@scripts/setup-gdrive.sh

.PHONY: backup-sync
backup-sync: ## バックアップ: Google Driveに今すぐ同期
	@if [ -f scripts/sync-gdrive.sh ]; then \
		scripts/sync-gdrive.sh; \
	else \
		echo "Google Drive連携が設定されていません。make backup-gdrive を実行してください"; \
	fi

# ===========================================
# Google Drive書類管理
# ===========================================

.PHONY: gdrive-status
gdrive-status: ## Google Drive: 連携状態確認
	@echo "=== rclone リモート一覧 ==="
	@rclone listremotes 2>/dev/null || echo "rcloneが見つかりません"
	@echo ""
	@echo "=== gdrive 接続テスト ==="
	@rclone lsd gdrive: 2>/dev/null | head -5 || echo "gdrive接続失敗"

.PHONY: gdrive-setup
gdrive-setup: ## Google Drive: フォルダ構造を初期作成
	@chmod +x scripts/gdrive-setup.sh
	@scripts/gdrive-setup.sh

.PHONY: gdrive-test
gdrive-test: ## Google Drive: テストアップロード
	@chmod +x scripts/gdrive-test.sh
	@scripts/gdrive-test.sh

.PHONY: gdrive-list
gdrive-list: ## Google Drive: フォルダ内容を表示
	@rclone lsd gdrive:SanyuTech_DX/ 2>/dev/null || echo "フォルダが見つかりません"

# ===========================================
# セキュリティ
# ===========================================

.PHONY: security-check
security-check: ## セキュリティ: 設定ファイルのパーミッションをチェック・修正
	@chmod +x scripts/security-check.sh
	@scripts/security-check.sh

# ===========================================
# n8n
# ===========================================

.PHONY: n8n-up
n8n-up: ## n8n: 起動
	docker compose up -d n8n
	@echo "$(GREEN)n8n: http://localhost:$(N8N_PORT)$(NC)"

.PHONY: n8n-logs
n8n-logs: ## n8n: ログ表示
	docker compose logs -f n8n

# ===========================================
# 開発ユーティリティ
# ===========================================

.PHONY: setup
setup: ## 初期セットアップ（初回のみ）
	@echo "$(GREEN)Setting up SanyuTech DX Platform...$(NC)"
	@cp -n .env.local.example .env.local 2>/dev/null || true
	@echo "$(YELLOW)1. Edit .env.local with your credentials$(NC)"
	@echo "$(YELLOW)2. Run 'make platform-new' to create Rails app$(NC)"
	@echo "$(YELLOW)3. Run 'make up' to start all services$(NC)"

.PHONY: build
build: ## Dockerイメージビルド
	docker compose build --no-cache

.PHONY: status
status: ## 開発環境ステータス確認
	@echo "$(GREEN)=== Docker Services ===$(NC)"
	@docker compose ps
	@echo ""
	@echo "$(GREEN)=== URLs ===$(NC)"
	@echo "Platform:   http://localhost:$(PLATFORM_PORT)"
	@echo "Worker Web: http://localhost:$(WORKER_WEB_PORT)"
	@echo "n8n:        http://localhost:$(N8N_PORT)"
