# アーキテクチャ設計書

SanyuTech DX Platform の技術設計詳細

**最終更新**: 2026-02-12
**バージョン**: 2.0.0

> **Note**: 最新のDBスキーマは `rails/platform/db/schema.rb` を参照してください。

---

## 目次

- [システム概要](#システム概要)
- [システム構成](#システム構成)
- [データベース設計](#データベース設計)
- [機能モジュール一覧](#機能モジュール一覧)
- [サービス層・Concern](#サービス層concern)
- [API設計](#api設計)
- [認証・認可設計](#認証認可設計)
- [セキュリティ設計](#セキュリティ設計)
- [外部連携](#外部連携)

---

## システム概要

### ビジネス要求

建設会社の業務を一気通貫でデジタル化し、以下を実現する：

1. **数字が見える**: リアルタイムで経営数字を把握
2. **壊れない**: 監査ログで全変更を追跡
3. **代わりが効く**: 属人化を排除、仕組みで業務を回す
4. **成長できる**: データに基づく評価・改善

### 直列型プロセス

```
案件登録
    │
    ▼
見積作成
    │
    ▼
【営業】4点チェック ──→ 売上確定
    │    ├─ 契約書あり
    │    ├─ 発注書あり
    │    ├─ 入金条件明記
    │    └─ 顧客承認
    │
    ▼
【営業→工務】引継ぎチェックリスト
    │
    ▼
【工務】着工前ゲート ──→ 着工OK
    │
    ▼
【工務】実行予算作成 ──→ 予算確定
    │
    ▼
【工事】施工・日報入力
    │
    ▼
【工務】原価確定
    │
    ▼
【経理】請求ゲート ──→ 請求書発行
    │
    ▼
【経理】入金確認
    │
    ▼
【統括】粗利確定
```

---

## システム構成

### 全体構成図

```
┌─────────────────────────────────────────────────────────────┐
│                    社内サーバー（ミニPC）                    │
│  ┌───────────────────────────────────────────────────────┐ │
│  │              Docker Compose                           │ │
│  │                                                       │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │ │
│  │  │  Platform   │  │ Worker Web  │  │    n8n      │   │ │
│  │  │  (Rails 8)  │  │  (Rails 8)  │  │  (自動化)   │   │ │
│  │  │   :3001     │  │   :3002     │  │   :5678     │   │ │
│  │  │             │  │             │  │             │   │ │
│  │  │ ・経営管理  │  │ ・段取り表  │  │ ・通知     │   │ │
│  │  │ ・営業管理  │  │ ・日報入力  │  │ ・バック   │   │ │
│  │  │ ・工務管理  │  │ ・有給申請  │  │   アップ   │   │ │
│  │  │ ・経理管理  │  │             │  │             │   │ │
│  │  │ ・安全書類  │  │             │  │             │   │ │
│  │  │ ・帳票出力  │  │             │  │             │   │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │ │
│  │         │                │                │          │ │
│  │         └────────────────┼────────────────┘          │ │
│  │                          ▼                           │ │
│  │                 ┌─────────────┐                      │ │
│  │                 │ PostgreSQL  │                      │ │
│  │                 │    :5432    │                      │ │
│  │                 └─────────────┘                      │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
        │                           │
        │ Cloudflare Tunnel        │ バックアップ（AES-256-CBC暗号化）
        ▼                           ▼
┌───────────────┐           ┌───────────────┐
│ 職長スマホ    │           │ Google Drive  │
│ 経営層PC      │           │  (rclone)     │
│ 作業員スマホ  │           │               │
└───────────────┘           └───────────────┘
        │
        ▼
┌───────────────┐
│ LINE WORKS    │
│ (Bot通知)     │
└───────────────┘
```

### コンポーネント詳細

| コンポーネント | ポート | 技術 | 責務 |
|---------------|--------|------|------|
| Platform | 3001 | Rails 8 | 基幹業務（経営/営業/工務/経理/事務） |
| Worker Web | 3002 | Rails 8 | 作業員向け（段取り表/日報入力/有給申請） |
| n8n | 5678 | n8n 2.1.1 | ワークフロー自動化・通知 |
| PostgreSQL | 5432 | PostgreSQL 16 | データベース（Platform/Worker Web共有） |

---

## データベース設計

### テーブル一覧（58テーブル）

#### コアマスタ

| テーブル | 説明 |
|----------|------|
| `employees` | 社員マスタ（認証・権限含む） |
| `clients` | 顧客マスタ |
| `partners` | 協力会社マスタ |
| `projects` | 案件マスタ（中心テーブル） |

#### 見積・予算

| テーブル | 説明 |
|----------|------|
| `estimates` | 見積書 |
| `estimate_items` | 見積明細行 |
| `estimate_categories` | 見積カテゴリ（明細グループ） |
| `estimate_confirmations` | 見積確認チェックリスト |
| `estimate_item_costs` | 見積項目別原価内訳 |
| `budgets` | 実行予算 |

#### 日報・出面・経費

| テーブル | 説明 |
|----------|------|
| `daily_reports` | 日報（1案件1日1レコード） |
| `attendances` | 出面（日報子テーブル） |
| `expenses` | 経費（日報・日報外兼用） |
| `fuel_entries` | 燃料経費（レシート写真添付） |
| `highway_entries` | 高速代（レシート写真添付） |
| `outsourcing_entries` | 外注明細（日報子テーブル） |

#### 請求・入金

| テーブル | 説明 |
|----------|------|
| `invoices` | 請求書 |
| `invoice_items` | 請求明細行 |
| `payments` | 入金記録 |
| `received_invoices` | 受領請求書（3段階承認） |

#### 月次確定・帳票

| テーブル | 説明 |
|----------|------|
| `monthly_salaries` | 月次確定給与 |
| `monthly_outsourcing_costs` | 月次確定外注費 |
| `monthly_progresses` | 月次出来高（全社） |
| `project_monthly_progresses` | 月次出来高（案件別） |
| `monthly_fixed_costs` | 月次固定費（現場別） |
| `monthly_admin_expenses` | 販管費（第1層） |
| `monthly_cost_confirmations` | 月次原価確定ステータス |

#### 相殺

| テーブル | 説明 |
|----------|------|
| `offsets` | 仮社員相殺 |

#### 安全書類

| テーブル | 説明 |
|----------|------|
| `safety_document_types` | 安全書類種類マスタ |
| `safety_folders` | 安全書類フォルダ |
| `safety_files` | 安全書類ファイル（複数添付対応） |
| `project_safety_requirements` | 案件別必要書類設定 |

#### 有給管理

| テーブル | 説明 |
|----------|------|
| `paid_leave_grants` | 有給付与（FIFO消化） |
| `paid_leave_requests` | 有給申請（承認ワークフロー） |

#### スケジュール・配置

| テーブル | 説明 |
|----------|------|
| `work_schedules` | 作業員スケジュール |
| `outsourcing_schedules` | 外注配置スケジュール |
| `daily_schedule_notes` | 段取り表備考 |
| `project_assignments` | 案件配置計画 |

#### 資金繰り

| テーブル | 説明 |
|----------|------|
| `cash_flow_entries` | 資金繰りエントリ（予実管理） |

#### テンプレート

| テーブル | 説明 |
|----------|------|
| `estimate_templates` | 見積テンプレート |
| `estimate_item_templates` | 見積項目テンプレート |
| `cost_breakdown_templates` | 原価内訳テンプレート |
| `cost_units` | 単位マスタ |
| `base_cost_templates` | 基本単価テンプレート（全案件共通） |
| `project_cost_templates` | 案件別単価テンプレート |

#### マスタ（その他）

| テーブル | 説明 |
|----------|------|
| `payment_terms` | 支払条件（polymorphic: Client/Partner） |
| `fixed_expense_schedules` | 固定費スケジュール |
| `fixed_expense_monthly_amounts` | 固定費月別金額 |
| `company_holidays` | 会社休日カレンダー |
| `company_events` | 会社イベント |

#### プロジェクト付帯

| テーブル | 説明 |
|----------|------|
| `project_messages` | 案件内メッセージ（@メンション対応） |
| `project_documents` | 案件書類ファイリング |

#### システム

| テーブル | 説明 |
|----------|------|
| `audit_logs` | 監査ログ |
| `data_imports` | データ取込履歴 |
| `active_storage_blobs` | ファイルストレージ（Rails標準） |
| `active_storage_attachments` | ファイル関連付け |
| `active_storage_variant_records` | 画像バリアント |

### ER図（主要リレーション）

```
                          ┌───────────────┐
                          │   clients     │
                          │   (顧客)      │
                          └───────┬───────┘
                                  │ 1:N
                                  ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────┐
│  estimates    │◄────────│   projects    │────────►│   budgets     │
│   (見積)      │  1:N    │   (案件)      │   1:1   │  (実行予算)   │
└───────┬───────┘         └───────┬───────┘         └───────────────┘
        │                   │    │    │
  estimate_items       ┌────┘    │    └────┐
  estimate_categories  │         │         │
  estimate_item_costs  ▼         ▼         ▼
               ┌────────────┐ ┌──────────┐ ┌───────────┐
               │daily_reports│ │ invoices │ │  offsets   │
               │  (日報)     │ │ (請求)   │ │  (相殺)   │
               └──────┬─────┘ └────┬─────┘ └───────────┘
                      │            │
           ┌──────────┼──────┐     │
           ▼          ▼      ▼     ▼
     ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐
     │attendances│ │expenses│ │fuel/hwy  │ │ payments │
     │  (出面)   │ │ (経費) │ │(燃料/高速)│ │  (入金)  │
     └──────────┘ └────────┘ └──────────┘ └──────────┘

  ┌───────────────────────────────────────────┐
  │  月次確定系（横断）                        │
  │  monthly_salaries / monthly_outsourcing   │
  │  monthly_progresses / monthly_fixed_costs │
  │  monthly_admin_expenses                   │
  └───────────────────────────────────────────┘

  ┌───────────────────────────────────────────┐
  │  安全書類系                               │
  │  safety_document_types → safety_folders   │
  │  → safety_files / project_safety_req.     │
  └───────────────────────────────────────────┘
```

### 主要テーブル定義

> 全カラムの詳細は `rails/platform/db/schema.rb` を参照。以下は設計意図の補足。

#### projects（案件マスタ）

案件がシステムの中心。全データが `project_id` で紐付く。

```
ステータス遷移:
  draft → estimating → ordered → preparing → in_progress → completed → invoiced → paid → closed
                        ↑
                  4点チェック完了
```

- `has_contract`, `has_order`, `has_payment_terms`, `has_customer_approval`: 4点チェック
- `pre_construction_check` (JSONB): 着工前ゲートチェック項目
- `drive_folder_url`: Google Drive案件フォルダURL
- `sales_user_id`, `engineering_user_id`, `construction_user_id`: 担当者
- `initial_revenue`, `initial_cost`: データ移行時の初期値

#### daily_reports（日報）

1案件1日1レコード。職長が一括入力。

子テーブル:
- `attendances`: 出面（1社員1レコード）
- `expenses`: 経費
- `fuel_entries`: 燃料（`has_one_attached :receipt`）
- `highway_entries`: 高速代（`has_one_attached :receipt`）
- `outsourcing_entries`: 外注明細

#### received_invoices（受領請求書）

3段階承認ワークフロー:
```
登録 → accounting_ok → sales_ok → engineering_ok → 確認済
```
各段階で承認者IDと日時を記録。却下時は `rejection_reason` 必須。

#### payment_terms（支払条件）

Polymorphic: `termable_type` / `termable_id` で Client または Partner に紐付く。

---

## 機能モジュール一覧

### Platform コントローラー構成

```
app/controllers/
├── dashboard_controller.rb            # トップダッシュボード
├── management_dashboard_controller.rb # 経営ダッシュボード
│
├── projects_controller.rb             # 案件管理
├── estimates_controller.rb            # 見積管理（projects nested）
├── budgets_controller.rb              # 実行予算（projects nested）
├── site_ledgers_controller.rb         # 現場台帳（projects nested）
│
├── schedule_controller.rb             # 段取り表
├── daily_reports_controller.rb        # 日報（projects nested）
├── all_daily_reports_controller.rb    # 全日報一覧
├── external_daily_reports_controller.rb # 常用日報（外部現場）
├── attendance_sheets_controller.rb    # 勤怠管理表
│
├── invoices_controller.rb             # 請求管理（projects nested）
├── all_invoices_controller.rb         # 全請求書一覧
├── payments_controller.rb             # 入金管理（invoices nested）
│
├── monthly_profit_losses_controller.rb     # 月次損益（年度・トレンド・比較）
├── monthly_income_statements_controller.rb # 月次損益計算書（第1層）
├── monthly_salaries_controller.rb          # 月次確定給与
├── monthly_outsourcing_costs_controller.rb # 月次確定外注費
├── monthly_progresses_controller.rb        # 月次出来高
├── monthly_fixed_costs_controller.rb       # 月次固定費
├── monthly_admin_expenses_controller.rb    # 販管費
├── monthly_reports_controller.rb           # 月次帳票（CSV出力）
│
├── cash_flow_calendar_controller.rb   # 資金繰り表
├── offsets_controller.rb              # 仮社員相殺
├── provisional_expenses_controller.rb # 仮経費確定
├── expense_reports_controller.rb      # 経費報告（日報外）
│
├── safety_documents_controller.rb     # 安全書類管理
├── safety_doc_tracking_controller.rb  # 安全書類ステータス
├── safety_document_types_controller.rb # 安全書類種類マスタ
│
├── paid_leaves_controller.rb          # 有給管理（管理者向け）
├── paid_leave_requests_controller.rb  # 有給申請（社員向け）
│
├── templates_controller.rb            # テンプレート統合ダッシュボード
├── estimate_templates_controller.rb   # 見積テンプレート
├── estimate_item_templates_controller.rb # 見積項目テンプレート
├── cost_breakdown_templates_controller.rb # 原価内訳テンプレート
├── cost_units_controller.rb           # 単位マスタ
├── base_cost_templates_controller.rb  # 基本単価テンプレート
├── cost_templates_controller.rb       # 日報用原価テンプレート一覧
│
├── project_messages_controller.rb     # 案件内メッセージ
├── project_documents_controller.rb    # 書類ファイリング
├── project_assignments_controller.rb  # 案件配置
├── outsourcing_reports_controller.rb  # 外注レポート
├── data_imports_controller.rb         # データ取込
│
├── accounting/                        # 経理名前空間
│   ├── expenses_controller.rb         #   経費処理・精算
│   ├── reimbursements_controller.rb   #   立替精算管理
│   └── received_invoices_controller.rb #  受領請求書（3段階承認）
│
├── admin/                             # 管理者名前空間
│   ├── quick_projects_controller.rb   #   簡易案件登録
│   └── data_imports_controller.rb     #   Excel一括取込
│
└── master/                            # マスタ管理名前空間
    ├── clients_controller.rb          #   顧客マスタ
    ├── partners_controller.rb         #   協力会社マスタ
    ├── employees_controller.rb        #   社員マスタ
    ├── payment_terms_controller.rb    #   支払条件
    ├── fixed_expense_schedules_controller.rb    # 固定費スケジュール
    ├── fixed_expense_monthly_amounts_controller.rb # 固定費月別金額
    ├── company_holidays_controller.rb #   休日カレンダー
    └── company_events_controller.rb   #   イベント管理
```

### Worker Web コントローラー構成

```
app/controllers/
├── dashboard_controller.rb            # ホーム
├── sessions_controller.rb             # ログイン
├── schedule_controller.rb             # 段取り表（閲覧）
├── assignments_controller.rb          # 配置確認
├── daily_reports_controller.rb        # 日報入力
├── attendances_controller.rb          # 出面入力
└── paid_leave_requests_controller.rb  # 有給申請
```

---

## サービス層・Concern

### サービスクラス

| サービス | 責務 |
|----------|------|
| `EstimatePdfGenerator` | 見積書PDF生成 |
| `MonthlyReportGenerator` | 月次帳票CSV生成（原価・損益・経費） |
| `PaidLeaveGrantService` | 有給付与処理（FIFO消化ロジック） |
| `PaidLeaveReportService` | 有給レポート集計 |
| `PaidLeavePdfService` | 有給管理簿PDF生成（Grover） |
| `CashFlowEntryGenerator` | 資金繰りエントリ自動生成 |
| `LineWorksNotifier` | LINE WORKS Bot API通知送信 |
| `GoogleDriveService` | Google Drive API操作 |
| `GoogleDriveRcloneService` | rcloneによるDrive同期 |
| `GoogleSheetsService` | Google Sheets操作 |
| `MigrationImportService` | Excelデータ移行（ヘッダマッピング） |

### Model Concern

| Concern | 責務 |
|---------|------|
| `Auditable` | 変更ログ自動記録（create/update/delete） |
| `Notifiable` | LINE WORKS通知トリガー |
| `MonthlyScoped` | 年月によるスコープフィルタ |
| `CostTemplateFormatting` | テンプレート表示フォーマット |

### Controller Concern

| Concern | 責務 |
|---------|------|
| `Authorizable` | RBAC認可チェック |
| `ProjectScoped` | 案件スコープフィルタ |
| `MonthlyPeriod` | 年月パラメータ処理 |
| `DailyReportActions` | 日報CRUD共通ロジック |

---

## API設計

### RESTful API（n8n連携用）

```
# データ取得
GET    /api/v1/projects              # 案件一覧
GET    /api/v1/projects/:id          # 案件詳細
GET    /api/v1/projects/summary      # 案件サマリ
GET    /api/v1/projects/:id/assignments # 案件配置情報
GET    /api/v1/daily_reports         # 日報一覧
GET    /api/v1/daily_reports/:id     # 日報詳細
GET    /api/v1/daily_reports/unconfirmed # 未確定日報

# Webhook（n8n → LINE WORKS通知）
POST   /api/v1/webhooks/project_created        # 案件作成
POST   /api/v1/webhooks/four_point_completed   # 4点チェック完了
POST   /api/v1/webhooks/budget_confirmed       # 予算確定
POST   /api/v1/webhooks/daily_report_submitted # 日報提出
POST   /api/v1/webhooks/offset_confirmed       # 相殺確定
```

---

## 認証・認可設計

### 認証（Devise）

```ruby
devise_for :employees, path: 'auth', path_names: {
  sign_in: 'login',
  sign_out: 'logout'
}
```

Platform と Worker Web は同じ `employees` テーブルを共有。Worker Web は独自のセッション管理。

### 認可（RBAC）

```ruby
ROLES = %w[
  admin        # 管理者（全権限）
  management   # 経営層（全閲覧＋承認）
  accounting   # 経理（会計・請求・相殺・精算）
  sales        # 営業（案件・見積・契約）
  engineering  # 工務（予算・原価・着工）
  construction # 工事（日報・配置・追加工事）
  worker       # 作業員（Worker Web利用）
]
```

### 権限マトリクス

| 機能 | admin | management | accounting | sales | engineering | construction | worker |
|------|-------|------------|------------|-------|-------------|--------------|--------|
| 経営ダッシュボード | ◎ | ◎ | ○ | ○ | ○ | - | - |
| 案件管理 | ◎ | ○ | - | ◎ | ○ | ○ | - |
| 見積・契約 | ◎ | ○ | - | ◎ | - | - | - |
| 実行予算 | ◎ | ○ | - | - | ◎ | ○ | - |
| 日報入力 | ◎ | - | - | - | - | ◎ | ○ |
| 請求・入金 | ◎ | ○ | ◎ | - | - | - | - |
| 相殺処理 | ◎ | ○ | ◎ | - | - | - | - |
| 受領請求書承認 | ◎ | - | ◎ | ◎ | ◎ | - | - |
| 月次確定 | ◎ | ◎ | ◎ | - | - | - | - |
| 安全書類 | ◎ | - | - | - | ○ | ◎ | - |
| 有給管理 | ◎ | ◎ | - | - | - | - | - |
| マスタ管理 | ◎ | - | - | - | - | - | - |
| データ取込 | ◎ | - | - | - | - | - | - |

◎: 全権限 ○: 閲覧+一部編集 -: アクセス不可

---

## セキュリティ設計

### ネットワーク

- **Cloudflare Tunnel**: 社外アクセス用（Tailscale VPNから移行）
- **Docker内部ネットワーク**: サービス間通信は内部ネットワーク内

### アプリケーション

| 対策 | 実装 |
|------|------|
| 認証 | Devise + セッション管理 |
| 認可 | RBAC + before_action (Authorizable concern) |
| SQLインジェクション | パラメータバインディング |
| XSS | ERB自動エスケープ + CSP（unsafe-inline禁止） |
| CSRF | Rails標準トークン |
| JS | Stimulus必須（インラインスクリプト禁止） |
| 監査 | 全変更ログ記録（Auditable concern） |
| ファイル添付 | Active Storage + バリデーション |

### バックアップ

| 項目 | 内容 |
|------|------|
| 頻度 | 日次自動 |
| 暗号化 | AES-256-CBC |
| 世代管理 | 20世代 |
| リモート同期 | Google Drive（rclone） |
| リストア | `make restore` で復元可能 |

---

## 外部連携

### LINE WORKS

- **方式**: Bot API（JWT認証）
- **サービス**: `LineWorksNotifier`
- **通知イベント**: 案件作成、4点チェック完了、着工、日報提出、相殺確定
- **@メンション**: `ProjectMessage` から直接通知

### Google Drive

- **方式**: API + rclone同期
- **サービス**: `GoogleDriveService` / `GoogleDriveRcloneService`
- **機能**: 案件フォルダ自動作成、バックアップ同期

### n8n

- **方式**: Webhook（Platform → n8n → LINE WORKS）
- **エンドポイント**: `/api/v1/webhooks/*`（5種）

---

## 参考リンク

- [CLAUDE.md](./CLAUDE.md) - 開発クイックリファレンス
- [CONTRIBUTING.md](./CONTRIBUTING.md) - 開発規約
- [要件定義書](./docs/SANYU-DX-REQUIREMENTS.md) - 機能要件詳細
- [docs/adr/](./docs/adr/) - 設計判断記録

---

**Document Version**: 2.0.0
**Last Updated**: 2026-02-12
