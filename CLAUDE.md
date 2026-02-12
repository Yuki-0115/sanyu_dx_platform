# CLAUDE.md - Claude Code 向けクイックリファレンス

このドキュメントは、Claude Code がこのプロジェクトを素早く理解し、適切な開発支援を行うためのガイドです。

---

## 重要：運用方針

### 現在の状態
- **シングルテナント**（自社専用システム）
- tenant_id によるデータ分離は**未実装**
- 全データは1社（サンユウテック）のもの

### 将来の拡張
- マルチテナント化の可能性あり
- 追加時は以下を実装：
  - 全テーブルに tenant_id カラム追加
  - TenantScoped Concern で自動フィルタ
  - ログイン時にテナント判定

### 開発時の注意
- 現時点では tenant_id を意識しなくてOK
- ただし、ハードコードされた会社固有値は避ける
- 将来の分離を妨げない設計を心がける

---

## 機能状態

### 実装済み
- 案件管理（4点チェック・着工前ゲート）、見積管理（PDF出力）、実行予算
- 日報入力（職長一括・燃料/高速レシート添付）、常用日報、原価管理
- 段取り表（人員配置・外注配置・一括配置）、勤怠管理表
- 現場台帳（3層構造：会計形式・工事部門・現場台帳）
- 月次損益計算書・月次確定給与/外注費・月次出来高・販管費・月次固定費
- 月次帳票出力（CSV）
- 請求管理・入金管理・受領請求書（3段階承認）
- 経費処理（掛け/カード/立替）・仮経費確定・立替精算・経費報告
- 資金繰り表（カレンダー形式）
- 仮社員相殺、有給管理（PDF出力・一括付与・FIFO消化）
- 安全書類管理（フォルダ・ファイル・案件別必要書類）
- 経営ダッシュボード（粗利一覧・赤字アラート）
- マスタ管理（顧客・協力会社・社員・支払条件・固定費・休日・イベント）
- テンプレート管理（見積・原価内訳・単位・基本単価・案件別単価）
- 権限管理（RBAC 7ロール）、監査ログ
- LINE WORKS通知連携（Bot API）
- Google Drive連携（案件フォルダ自動作成・バックアップ同期）
- バックアップ暗号化（AES-256-CBC・20世代管理）
- データ移行ツール（Excel一括取込・簡易案件登録）
- Worker Web（段取り表閲覧・日報入力・有給申請）
- 案件内メッセージ（@メンション・通知連携）

### 開発予定
- 見積OCR取込（Claude Vision API）
- freee会計連携

---

## 帳票の差異について

| 項目 | 第3層（現場台帳） | 第2層（工事部門） |
|------|------------------|------------------|
| 労務費 | ¥18,000×人工 | 実際給与 |
| 経費 | 生の数字 | 生の数字 |

**→ 差異は当然発生（管理目的が違う）**

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

### 変更履歴ルール

**必須：変更時は CHANGELOG.md を更新**

以下の変更時は必ず記録：
- 機能追加（Added）
- 仕様変更（Changed）
- 機能削除（Removed）
- バグ修正（Fixed）

コミット時の流れ：
1. コード変更
2. CHANGELOG.md に追記
3. git add -A
4. git commit
5. git push

### 現在のフェーズ

```
【プロダクト名】SanyuTech DX Platform

【現在のPhase】Phase 3（開発・運用中）

【完了】
- Phase 1: 要件定義 ✅
- Phase 2: 設計 ✅

【進行中】
- Phase 3: 開発
  - [x] Docker環境構築
  - [x] DB・モデル作成
  - [x] 認証機能（Devise）
  - [x] 認可機能（RBAC）
  - [x] 案件管理＋4点チェック
  - [x] 実行予算＋原価
  - [x] 日報（職長一括入力）
  - [x] 経営ダッシュボード
  - [x] 仮社員相殺
  - [x] 見積管理＋テンプレート
  - [x] 段取り表＋人員配置
  - [x] 現場台帳（3層構造）
  - [x] 月次損益計算書＋帳票
  - [x] 経費処理＋立替精算
  - [x] 安全書類管理
  - [x] 有給管理
  - [x] 請求・入金管理
  - [x] 資金繰り表
  - [x] n8n連携＋LINE WORKS通知
  - [x] Google Drive連携＋バックアップ暗号化
  - [x] 作業員Web（Worker Web）
  - [x] データ移行ツール
  - [ ] 見積OCR取込
  - [ ] freee会計連携
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
- [ ] 認証なしで叩けるエンドポイントを一覧化

### AI生成コードの注意点

| AIの傾向 | 対策 |
|----------|------|
| 全アクセス許可を提案しがち | 最小権限の原則で修正 |
| 認証・認可を省略しがち | 全エンドポイントに認証必須か確認 |
| APIキーをハードコードしがち | 環境変数 + .gitignore確認 |
| 入力値を信頼しがち | サーバーサイドバリデーション必須 |

### 危険シグナル（見つけたら即修正）

- `*` を含むCORS設定
- `public: true` や `anon` キーでの全データアクセス
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

## JavaScript開発ルール

### 絶対ルール：インラインスクリプト禁止

以下は**全て禁止**：

```erb
<!-- ❌ 禁止：インラインスクリプト -->
<script>
  document.querySelector('.btn').addEventListener('click', ...);
</script>

<!-- ❌ 禁止：onclickなどのイベントハンドラ属性 -->
<button onclick="doSomething()">実行</button>

<!-- ❌ 禁止：onchange, onsubmit, onload等も全て -->
<form onsubmit="return validate()">
```

### 正しい書き方：Stimulusコントローラー

```bash
# コントローラー生成
bin/rails generate stimulus example
```

```javascript
// app/javascript/controllers/example_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  greet() {
    this.outputTarget.textContent = "Hello!"
  }
}
```

```erb
<%# ビューでの使用 %>
<div data-controller="example">
  <button data-action="click->example#greet">挨拶</button>
  <span data-example-target="output"></span>
</div>
```

### 理由

- CSP（Content Security Policy）でインラインスクリプトをブロックしている
- セキュリティ強化のため`unsafe-inline`は使用しない
- Hotwire/Stimulus採用プロジェクトの標準アプローチ

### 参考

- 詳細な経緯：`docs/adr/002-stimulus-mandatory.md`

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

**Last Updated**: 2025-01-22
