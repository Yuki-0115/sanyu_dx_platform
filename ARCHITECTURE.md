# アーキテクチャ設計書

SanyuTech DX Platform の技術設計詳細

**最終更新**: 2025-01-15
**バージョン**: 0.1.0

---

## 目次

- [システム概要](#システム概要)
- [システム構成](#システム構成)
- [データベース設計](#データベース設計)
- [API設計](#api設計)
- [認証・認可設計](#認証認可設計)
- [セキュリティ設計](#セキュリティ設計)

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
│  │  │ ・経営管理  │  │ ・日報入力  │  │ ・通知     │   │ │
│  │  │ ・営業管理  │  │ ・工程確認  │  │ ・バック   │   │ │
│  │  │ ・工務管理  │  │ ・多言語    │  │   アップ   │   │ │
│  │  │ ・経理管理  │  │             │  │             │   │ │
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
        │ Tailscale VPN            │ バックアップ
        ▼                           ▼
┌───────────────┐           ┌───────────────┐
│ 職長スマホ    │           │ Google Drive  │
│ 経営層PC      │           │               │
└───────────────┘           └───────────────┘
```

### コンポーネント詳細

| コンポーネント | ポート | 技術 | 責務 |
|---------------|--------|------|------|
| Platform | 3001 | Rails 8 | 基幹業務（経営/営業/工務/経理） |
| Worker Web | 3002 | Rails 8 | 作業員向け（日報入力/工程確認） |
| n8n | 5678 | n8n 2.1.1 | ワークフロー自動化・通知 |
| PostgreSQL | 5432 | PostgreSQL 16 | データベース |

---

## データベース設計

### ER図（主要テーブル）

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   clients   │────<│  projects   │>────│   budgets   │
│  (顧客)     │     │  (案件)     │     │ (実行予算)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  estimates  │   │daily_reports│   │  invoices   │
│   (見積)    │   │   (日報)    │   │   (請求)    │
└─────────────┘   └──────┬──────┘   └──────┬──────┘
                         │                 │
              ┌──────────┴──────────┐      │
              │                     │      │
              ▼                     ▼      ▼
        ┌───────────┐        ┌───────────┐ ┌───────────┐
        │attendances│        │ expenses  │ │ payments  │
        │  (出面)   │        │  (経費)   │ │  (入金)   │
        └───────────┘        └───────────┘ └───────────┘
```

### 主要テーブル定義

#### clients（顧客マスタ）

```sql
CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,     -- 顧客コード
  name VARCHAR(255) NOT NULL,           -- 顧客名
  name_kana VARCHAR(255),               -- フリガナ
  postal_code VARCHAR(10),              -- 郵便番号
  address TEXT,                         -- 住所
  phone VARCHAR(20),                    -- 電話番号
  contact_name VARCHAR(100),            -- 担当者名
  contact_email VARCHAR(255),           -- 担当者メール
  payment_terms VARCHAR(50),            -- 支払条件
  notes TEXT,                           -- 備考
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### projects（案件マスタ）

```sql
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,     -- 案件コード
  name VARCHAR(255) NOT NULL,           -- 案件名
  client_id INTEGER REFERENCES clients(id),
  site_address TEXT,                    -- 現場住所
  site_lat DECIMAL(10,7),               -- 緯度
  site_lng DECIMAL(10,7),               -- 経度
  
  -- 4点チェック
  has_contract BOOLEAN DEFAULT FALSE,   -- 契約書あり
  has_order BOOLEAN DEFAULT FALSE,      -- 発注書あり
  has_payment_terms BOOLEAN DEFAULT FALSE, -- 入金条件明記
  has_customer_approval BOOLEAN DEFAULT FALSE, -- 顧客承認
  four_point_completed_at TIMESTAMP,    -- 4点完了日時
  
  -- 着工前ゲート
  pre_construction_check JSONB,         -- 着工前チェック項目
  pre_construction_approved_at TIMESTAMP,
  
  -- 金額
  estimated_amount DECIMAL(15,2),       -- 見積金額
  order_amount DECIMAL(15,2),           -- 受注金額
  budget_amount DECIMAL(15,2),          -- 予算金額
  actual_cost DECIMAL(15,2),            -- 実績原価
  
  -- ステータス
  status VARCHAR(50) DEFAULT 'draft',   -- ステータス
  
  -- 担当
  sales_user_id INTEGER,                -- 営業担当
  engineering_user_id INTEGER,          -- 工務担当
  construction_user_id INTEGER,         -- 工事担当
  
  -- Google Drive
  drive_folder_url TEXT,                -- フォルダURL
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- ステータス: draft, estimating, ordered, preparing, 
--            in_progress, completed, invoiced, paid, closed
```

#### employees（社員マスタ）

```sql
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,     -- 社員コード
  name VARCHAR(100) NOT NULL,           -- 氏名
  name_kana VARCHAR(100),               -- フリガナ
  email VARCHAR(255),                   -- メール
  phone VARCHAR(20),                    -- 電話番号
  
  -- 雇用情報
  employment_type VARCHAR(20) NOT NULL, -- 正社員/仮社員
  partner_id INTEGER,                   -- 紐づけ協力会社（仮社員）
  hire_date DATE,                       -- 入社日
  
  -- 権限
  role VARCHAR(50) NOT NULL,            -- 権限グループ
  
  -- 認証
  encrypted_password VARCHAR(255),
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- employment_type: regular（正社員）, temporary（仮社員）
-- role: admin, management, accounting, sales, engineering, construction, worker
```

#### paid_leave_grants（有給付与）

```sql
CREATE TABLE paid_leave_grants (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER REFERENCES employees(id) NOT NULL,

  grant_type VARCHAR(20) NOT NULL,       -- auto/manual/special
  grant_date DATE NOT NULL,              -- 付与日
  expiry_date DATE NOT NULL,             -- 失効日（付与日+2年）

  granted_days DECIMAL(3,1) NOT NULL,    -- 付与日数
  used_days DECIMAL(3,1) DEFAULT 0,      -- 消化済み日数
  remaining_days DECIMAL(3,1) NOT NULL,  -- 残日数

  reason TEXT,                           -- 付与理由（特別付与時）
  granted_by_id INTEGER REFERENCES employees(id), -- 付与者

  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_paid_leave_grants_employee ON paid_leave_grants(employee_id);
CREATE INDEX idx_paid_leave_grants_active ON paid_leave_grants(expiry_date) WHERE remaining_days > 0;

-- grant_type: auto（自動付与）, manual（手動調整）, special（特別付与）
-- FIFO消化: 古い付与分（grant_date順）から消化
```

#### paid_leave_requests（有給申請）

```sql
CREATE TABLE paid_leave_requests (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER REFERENCES employees(id) NOT NULL,
  paid_leave_grant_id INTEGER REFERENCES paid_leave_grants(id), -- 消化対象付与

  leave_date DATE NOT NULL,              -- 取得日
  leave_type VARCHAR(10) NOT NULL,       -- full/half_am/half_pm
  consumed_days DECIMAL(2,1) NOT NULL,   -- 消化日数（1.0 or 0.5）

  reason TEXT,                           -- 申請理由
  status VARCHAR(20) DEFAULT 'pending',  -- pending/approved/rejected/cancelled

  approved_by_id INTEGER REFERENCES employees(id),
  approved_at TIMESTAMP,
  rejection_reason TEXT,                 -- 却下理由

  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,

  UNIQUE(employee_id, leave_date)        -- 1社員1日1申請
);

CREATE INDEX idx_paid_leave_requests_employee ON paid_leave_requests(employee_id);
CREATE INDEX idx_paid_leave_requests_status ON paid_leave_requests(status);
CREATE INDEX idx_paid_leave_requests_leave_date ON paid_leave_requests(leave_date);

-- leave_type: full（全日）, half_am（午前半休）, half_pm（午後半休）
-- status: pending（承認待ち）, approved（承認）, rejected（却下）, cancelled（取消）
```

#### partners（協力会社マスタ）

```sql
CREATE TABLE partners (
  id SERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,     -- 協力会社コード
  name VARCHAR(255) NOT NULL,           -- 会社名
  
  -- 仮社員関連
  has_temporary_employees BOOLEAN DEFAULT FALSE,
  offset_rule VARCHAR(50),              -- 相殺ルール
  closing_day INTEGER,                  -- 締日
  carryover_balance DECIMAL(15,2) DEFAULT 0, -- 繰越残高
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### daily_reports（日報）

```sql
CREATE TABLE daily_reports (
  id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects(id),
  report_date DATE NOT NULL,            -- 日報日付
  foreman_id INTEGER REFERENCES employees(id), -- 入力者（職長）
  
  -- 天気
  weather VARCHAR(20),                  -- 天気
  temperature_high INTEGER,             -- 最高気温
  temperature_low INTEGER,              -- 最低気温
  
  -- 作業内容
  work_content TEXT,                    -- 作業内容
  notes TEXT,                           -- 備考
  
  -- ステータス
  status VARCHAR(20) DEFAULT 'draft',   -- draft/confirmed/revised
  confirmed_at TIMESTAMP,               -- 確定日時
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  UNIQUE(project_id, report_date)       -- 1案件1日1レコード
);
```

#### attendances（出面）

```sql
CREATE TABLE attendances (
  id SERIAL PRIMARY KEY,
  daily_report_id INTEGER REFERENCES daily_reports(id),
  employee_id INTEGER REFERENCES employees(id),
  
  attendance_type VARCHAR(20) NOT NULL, -- 出勤/半日/休み
  start_time TIME,                      -- 開始時刻
  end_time TIME,                        -- 終了時刻
  travel_distance INTEGER,              -- 移動距離（km）※50km以上のみ
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  UNIQUE(daily_report_id, employee_id)  -- 重複防止
);
```

#### expenses（経費）

```sql
CREATE TABLE expenses (
  id SERIAL PRIMARY KEY,
  daily_report_id INTEGER,              -- 日報経費の場合
  expense_type VARCHAR(50) NOT NULL,    -- 経費区分
  
  category VARCHAR(50) NOT NULL,        -- 材料/交通/重機レンタル等
  description TEXT,                     -- 内容
  amount DECIMAL(15,2) NOT NULL,        -- 金額
  
  payer_id INTEGER REFERENCES employees(id), -- 支払者
  payment_method VARCHAR(20),           -- 現金/会社カード/立替/掛け
  
  -- 承認
  status VARCHAR(20) DEFAULT 'pending', -- pending/approved/rejected
  approved_by INTEGER,
  approved_at TIMESTAMP,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- expense_type: site（現場経費）, sales（営業経費）, admin（販管費）
```

#### invoices（請求）

```sql
CREATE TABLE invoices (
  id SERIAL PRIMARY KEY,
  project_id INTEGER REFERENCES projects(id),
  invoice_number VARCHAR(50) UNIQUE,    -- 請求書番号
  
  amount DECIMAL(15,2) NOT NULL,        -- 請求金額
  tax_amount DECIMAL(15,2),             -- 消費税
  total_amount DECIMAL(15,2),           -- 合計
  
  issued_date DATE,                     -- 発行日
  due_date DATE,                        -- 支払期日
  
  -- ステータス
  status VARCHAR(20) DEFAULT 'draft',   -- draft/issued/waiting/paid/overdue
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### offsets（仮社員相殺）

```sql
CREATE TABLE offsets (
  id SERIAL PRIMARY KEY,
  partner_id INTEGER REFERENCES partners(id),
  year_month VARCHAR(7) NOT NULL,       -- 2025-01
  
  -- 計算結果
  total_salary DECIMAL(15,2),           -- 給与総額
  social_insurance DECIMAL(15,2),       -- 社保会社負担
  offset_amount DECIMAL(15,2),          -- 相殺対象額（A）
  revenue_amount DECIMAL(15,2),         -- 出来高（B）
  balance DECIMAL(15,2),                -- 差額（B-A）
  
  -- ステータス
  status VARCHAR(20) DEFAULT 'draft',   -- draft/confirmed
  confirmed_by INTEGER,
  confirmed_at TIMESTAMP,
  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  
  UNIQUE(partner_id, year_month)
);
```

#### audit_logs（監査ログ）

```sql
CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  auditable_type VARCHAR(100) NOT NULL, -- モデル名
  auditable_id INTEGER NOT NULL,        -- レコードID
  
  user_id INTEGER REFERENCES employees(id), -- 操作者
  action VARCHAR(20) NOT NULL,          -- create/update/delete
  changes JSONB,                        -- 変更内容
  
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_logs_auditable ON audit_logs(auditable_type, auditable_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);
```

---

## API設計

### RESTful API

```
# 案件
GET    /api/v1/projects           # 一覧
POST   /api/v1/projects           # 作成
GET    /api/v1/projects/:id       # 詳細
PATCH  /api/v1/projects/:id       # 更新
DELETE /api/v1/projects/:id       # 削除

# 4点チェック
POST   /api/v1/projects/:id/four_point_check  # 4点チェック完了

# 日報
GET    /api/v1/daily_reports      # 一覧
POST   /api/v1/daily_reports      # 作成
GET    /api/v1/daily_reports/:id  # 詳細
PATCH  /api/v1/daily_reports/:id  # 更新
POST   /api/v1/daily_reports/:id/confirm  # 確定

# ダッシュボード
GET    /api/v1/dashboard/summary  # サマリ
GET    /api/v1/dashboard/profit_ranking  # 粗利ランキング
GET    /api/v1/dashboard/alerts   # アラート
```

---

## 認証・認可設計

### 認証（Devise）

```ruby
# config/routes.rb
devise_for :employees, path: 'auth', path_names: {
  sign_in: 'login',
  sign_out: 'logout'
}
```

### 認可（RBAC）

```ruby
# app/models/employee.rb
class Employee < ApplicationRecord
  ROLES = %w[
    admin        # 管理者（全権限）
    management   # 経営層（全閲覧＋承認）
    accounting   # 経理（会計・請求・相殺）
    sales        # 営業（案件・見積・契約）
    engineering  # 工務（予算・原価・着工）
    construction # 工事（日報・配置・追加工事）
    worker       # 作業員（閲覧のみ）
  ]
  
  def can_access?(resource, action)
    PERMISSIONS[role.to_sym][resource.to_sym]&.include?(action.to_sym)
  end
end
```

### 権限マトリクス

| 機能 | admin | management | accounting | sales | engineering | construction |
|------|-------|------------|------------|-------|-------------|--------------|
| ダッシュボード | ◎ | ◎ | ○ | ○ | ○ | - |
| 案件管理 | ◎ | ○ | - | ◎ | ○ | ○ |
| 見積・契約 | ◎ | ○ | - | ◎ | - | - |
| 実行予算 | ◎ | ○ | - | - | ◎ | ○ |
| 日報入力 | ◎ | - | - | - | - | ◎ |
| 請求・入金 | ◎ | ○ | ◎ | - | - | - |
| 相殺処理 | ◎ | ○ | ◎ | - | - | - |
| ユーザー管理 | ◎ | - | - | - | - | - |

◎: 全権限 ○: 閲覧+一部編集 -: アクセス不可

---

## セキュリティ設計

### ネットワーク

- **Tailscale VPN**: 認証済み端末のみアクセス可能
- **インターネット直接公開なし**: 攻撃対象にならない

### アプリケーション

| 対策 | 実装 |
|------|------|
| 認証 | Devise + セッション管理 |
| 認可 | RBAC + before_action |
| SQLインジェクション | パラメータバインディング |
| XSS | ERB自動エスケープ + CSP |
| CSRF | Rails標準トークン |
| 監査 | 全変更ログ記録 |

### バックアップ

- **日次**: PostgreSQL → Google Drive
- **保持期間**: 7日間
- **暗号化**: gzip圧縮

---

## 参考リンク

- [CLAUDE.md](./CLAUDE.md) - 開発クイックリファレンス
- [CONTRIBUTING.md](./CONTRIBUTING.md) - 開発規約
- [要件定義書](./docs/SANYU-DX-REQUIREMENTS.md) - 機能要件詳細

---

**Document Version**: 0.1.0
**Last Updated**: 2025-01-15
