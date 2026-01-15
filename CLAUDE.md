# CLAUDE.md - Claude Code 向けクイックリファレンス

このドキュメントは、Claude Code がこのプロジェクトを素早く理解し、適切な開発支援を行うためのガイドです。

---

## 開発ルール（DEV-RULES v2.6 統合）

### 基本姿勢

- 説明より動くコードを優先
- コードは省略せず完全な形で出す
- 判断に迷ったら選択肢を1つに絞って提案
- **9割完成を目指す**（完璧は目指さない、でも中途半端もNG）
- 不足・違和感はIssue化して後回し

### ファイル分割ルール

- 原則：1機能 = 1ファイル
- 例外：UI・API・モデルなど責務が分かれる場合のみ最大3ファイル
- 3ファイル超えそうならIssue化して分割

### 現在のフェーズ

```
【プロダクト名】SanyuTech DX Platform

【現在のPhase】Phase 3（開発）

【完了】
- Phase 1: 要件定義 ✅
- Phase 2: 設計 ✅

【進行中】
- Phase 3: 開発
  - [ ] Docker環境構築
  - [ ] DB・モデル作成（RLS設定含む）
  - [ ] 認証機能（Devise）
  - [ ] 認可機能（RBAC）
  - [ ] 案件管理＋4点チェック
  - [ ] 実行予算＋原価
  - [ ] 日報（職長一括入力）
  - [ ] 経営ダッシュボード
  - [ ] 仮社員相殺
  - [ ] n8n連携＋LINE WORKS通知
  - [ ] 作業員Web（Worker Web）
```

---

## 開発フロー

### Done条件（全機能共通）

各機能は以下を満たしたら完了：

- [ ] 主要ユースケース1本が通る
- [ ] 入力バリデーション（最低限）あり
- [ ] エラー時に落ちずにメッセージを返す
- [ ] 手動確認手順を `/docs/manual-tests.md` に追記
- [ ] 動作確認は必ずブラウザで人間が1回触る
- [ ] tenant_idによるデータ分離が機能している
- [ ] commit & push済み

### 進行例

```
Docker環境構築 → commit
DB・モデル作成（RLS設定含む） → commit
認証機能 → commit
認可機能（ロール・権限） → commit
案件管理＋4点チェック → commit
実行予算＋原価入力 → commit
日報（職長一括入力） → commit
経営ダッシュボード → commit
仮社員相殺 → commit
n8n連携 → commit
作業員Web → commit
UI調整 → commit
```

---

## セキュリティチェックリスト

### 開発前チェック（必須）

- [ ] .envファイルで秘密情報を管理
- [ ] .gitignoreに.envが含まれている
- [ ] ログにトークン・パスワード・個人情報を出力しない
- [ ] tenant_id によるテナント分離がDB層で強制
- [ ] 認証なしで叩けるエンドポイントを一覧化

### AI生成コードの注意点

| AIの傾向 | 対策 |
|----------|------|
| 全アクセス許可を提案しがち | 最小権限の原則で修正 |
| 認証・認可を省略しがち | 全エンドポイントに認証必須か確認 |
| APIキーをハードコードしがち | 環境変数 + .gitignore確認 |
| DBのテナント分離を忘れがち | tenant_id必須ルール徹底 |
| 入力値を信頼しがち | サーバーサイドバリデーション必須 |

### 危険シグナル（見つけたら即修正）

- `*` を含むCORS設定
- `public: true` や `anon` キーでの全データアクセス
- WHERE句に tenant_id がないクエリ
- try-catchのないAPI呼び出し
- ハードコードされたAPIキー・パスワード
- `console.log` / `Rails.logger` に含まれるユーザー情報

### リリース前スキャン

```bash
# 依存関係の脆弱性
bundle audit

# シークレット漏洩チェック
gitleaks detect

# 静的解析（SAST）
brakeman -A
```

---

## Git運用

### commitタイミング

| タイミング | 種別 | 例 |
|-----------|------|-----|
| 1機能完成時 | feat | `feat: ログイン機能追加` |
| バグ修正後 | fix | `fix: 認証エラー修正` |
| 大きな変更前 | wip | `wip: リファクタ前の状態` |
| 1日の終了時 | wip | `wip: 本日の作業` |
| セキュリティ修正後 | security | `security: RLS設定追加` |

### commitメッセージ形式

```
feat:     新機能追加
fix:      バグ修正
refactor: リファクタリング
docs:     ドキュメント更新
style:    コード整形
security: セキュリティ修正
wip:      作業中（途中保存）
```

### commitコマンド

```bash
git add .
git commit -m "種別: 変更内容"
git push origin main
```

---

## 合言葉一覧

| 言葉 | AIがやること |
|------|-------------|
| 保存 / commit | git add → commit → push コマンドを出す |
| エラー | 原因と解決策をセットで出す |
| issue | バグ・修正内容をIssue形式で出す |
| done確認 | 現在の機能がDone条件を満たしているかチェック |
| セキュリティスキャン | brakeman / gitleaks のコマンドを出す |
| 権限チェック | 全エンドポイントの認証・認可状態を一覧化 |

---

## Issue形式

「issue」と言ったらこの形式で出力：

```
タイトル
（簡潔にエラー・改善内容）

概要
（何が起きているか / 何をしたいか）

原因 / 背景
（なぜ起きたか / なぜ必要か）

解決策 / 対応内容
（どう直したか / どう実装するか）

影響範囲
（どのファイル・機能に影響するか）

セキュリティ影響（該当する場合）
（認証・認可・データ漏洩リスクの有無）
```

---

## 禁止事項

- 一度に全部作ろうとしない
- 「全部」「いい感じに」「最適化して」は使わない
- 説明だけで終わらない（必ずコードを出す）
- 秘密情報をコードにハードコードしない
- 秘密情報をログに出力しない
- AIが生成したコードをレビューなしで本番デプロイしない

---

## ドキュメント役割分担

| ドキュメント | 役割 |
|--------------|------|
| **README.md** | プロジェクト概要、クイックスタート |
| **CLAUDE.md** | AI向けクイックリファレンス + 開発ルール（このファイル） |
| **CONTRIBUTING.md** | 開発規約（Issue、Git、コミット） |
| **ARCHITECTURE.md** | 技術設計詳細、DB設計、API設計 |
| **docs/SANYU-DX-REQUIREMENTS.md** | 機能要件詳細 |
| **docs/manual-tests.md** | 手動テスト手順 |

---

## プロジェクト概要

**SanyuTech DX Platform** - 建設会社向け業務DXプラットフォーム

### アーキテクチャ概要

```
┌─────────────────────────────────────────────────────┐
│                  社内サーバー                        │
│  ┌───────────────────────────────────────────────┐ │
│  │ SanyuTech DX Platform (Docker Compose)       │ │
│  │                                               │ │
│  │ ┌─────────────┐ ┌─────────────┐ ┌──────────┐ │ │
│  │ │ Platform    │ │ Worker Web  │ │   n8n    │ │ │
│  │ │ (Rails 8)   │ │ (Rails 8)   │ │ (自動化) │ │ │
│  │ │ :3001       │ │ :3002       │ │ :5678    │ │ │
│  │ └──────┬──────┘ └──────┬──────┘ └────┬─────┘ │ │
│  │        │               │              │       │ │
│  │        └───────────────┼──────────────┘       │ │
│  │                        ▼                      │ │
│  │               ┌─────────────┐                │ │
│  │               │ PostgreSQL  │                │ │
│  │               │    :5432    │                │ │
│  │               └─────────────┘                │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
        │
        │ Tailscale VPN
        ▼
┌─────────────────┐
│ 職長スマホ      │
│ 経営層PC        │
└─────────────────┘
```

### 技術スタック

- **Rails 8.0** + **PostgreSQL 16**
- **Hotwire** (Turbo + Stimulus)
- **Tailwind CSS**
- **Devise** (認証)
- **n8n** (ワークフロー自動化)

---

## よく使うコマンド

### サービス管理

```bash
make up                  # 全サービス起動
make down                # 全サービス停止
make logs                # ログ表示
make status              # 状態確認
make clean               # 完全クリーンアップ（注意）
```

### Platform（基幹アプリ）

```bash
make platform-shell      # シェル接続
make platform-console    # Railsコンソール
make platform-migrate    # マイグレーション
make platform-seed       # シードデータ
make platform-test       # テスト実行
make platform-routes     # ルーティング確認
```

### Worker Web（作業員向け）

```bash
make worker-shell        # シェル接続
make worker-console      # Railsコンソール
```

### PostgreSQL

```bash
make postgres-shell      # psql接続
make postgres-backup     # バックアップ作成
```

---

## 開発ワークフロー

### 1. Issue作成 → ブランチ作成 → 実装 → PR

```bash
# 1. mainを最新化
git checkout main && git pull origin main

# 2. ブランチ作成
git checkout -b feature/XX-description

# 3. 実装
# ...

# 4. コミット
git add .
git commit -m "feat(platform): 機能説明 (issue#XX)"

# 5. PR作成
gh pr create --title "タイトル" --body "Closes #XX"
```

### コミット規約

```
<type>(<scope>): <subject> (issue#XX)

# type: feat, fix, docs, refactor, test, chore
# scope: platform, worker, n8n, db, docs
```

**例**:
```bash
feat(platform): 案件登録APIを実装 (issue#1)
fix(worker): 日報入力のバリデーションを修正 (issue#5)
docs: ARCHITECTURE.mdを更新 (issue#10)
```

---

## 重要な設計原則

### 1. 直列型プロセス

```
案件ID → 見積 → 受注(4点) → 実行予算 → 日報 → 請求 → 入金
```

**すべてのデータは案件IDで紐付く**

### 2. 権限設計（RBAC）

```ruby
# 権限グループ
ROLES = %w[admin management accounting sales engineering construction worker]

# 例: 経営層のみダッシュボード閲覧可能
before_action :require_management!, only: [:dashboard]
```

### 3. 監査ログ

```ruby
# 重要なモデルには必ず監査ログを追加
class Project < ApplicationRecord
  include Auditable  # 誰が・いつ・何を変えたか記録
end
```

### 4. 日報は職長一括入力

```ruby
# 作業員は直接入力しない
# 職長が全員分をまとめて入力
class DailyReport < ApplicationRecord
  belongs_to :foreman  # 入力者（職長）
  has_many :attendances  # 出面（サブテーブル）
  has_many :expenses     # 経費（サブテーブル）
end
```

---

## DB設計の基本

### 主要テーブル

```
clients          # 顧客マスタ
projects         # 案件マスタ（中心）
partners         # 協力会社マスタ
employees        # 社員マスタ
estimates        # 見積
orders           # 受注（4点チェック）
budgets          # 実行予算
daily_reports    # 日報
attendances      # 出面
expenses         # 経費
invoices         # 請求
payments         # 入金
offsets          # 仮社員相殺
```

### 案件ステータス

```ruby
PROJECT_STATUSES = %w[
  draft           # 下書き
  estimating      # 見積中
  ordered         # 受注済（4点チェック完了）
  preparing       # 着工準備中
  in_progress     # 施工中
  completed       # 完工
  invoiced        # 請求済
  paid            # 入金済
  closed          # クローズ
]
```

---

## セキュリティチェック

```ruby
# 1. SQLインジェクション対策
Project.where("name LIKE ?", "%#{query}%")  # ✅
Project.where("name LIKE '%#{query}%'")     # ❌

# 2. Strong Parameters
params.require(:project).permit(:name, :client_id, :amount)

# 3. 認可チェック
before_action :authenticate_user!
before_action :authorize_project_access!
```

---

## トラブルシューティング

### コンテナが起動しない

```bash
make clean && make up
```

### マイグレーションエラー

```bash
make platform-shell
bin/rails db:rollback
bin/rails db:migrate
```

### ポート競合

```bash
# .env でポート変更
PLATFORM_PORT=3003
```

---

## 関連リンク

- [README.md](./README.md) - プロジェクト概要
- [CONTRIBUTING.md](./CONTRIBUTING.md) - 開発規約
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 技術設計詳細
- [docs/adr/](./docs/adr/) - 設計判断記録
- [要件定義書](./docs/SANYU-DX-REQUIREMENTS.md) - 機能要件

---

**Last Updated**: 2025-01-15
