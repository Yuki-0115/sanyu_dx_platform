# 開発ガイド

SanyuTech DX Platform の開発規約です。

---

## 目次

- [Git ワークフロー](#git-ワークフロー)
- [コミット規約](#コミット規約)
- [コーディング規約](#コーディング規約)
- [テスト方針](#テスト方針)

---

## Git ワークフロー

### GitHub Flow 採用

```
1. Issue作成 → 2. ブランチ作成 → 3. 実装 → 4. PR作成 → 5. レビュー → 6. マージ
```

### ブランチ命名規則

```
<type>/<issue番号>-<機能名>

例:
feature/1-project-crud
bugfix/5-daily-report-validation
hotfix/10-security-patch
refactor/15-cleanup-models
docs/20-update-readme
```

### 重要ルール

- ❌ main ブランチへの直接プッシュ禁止
- ❌ Issue 番号なしのコミット禁止
- ✅ 必ずブランチを作成してから作業

---

## コミット規約

### Conventional Commits 準拠

```
<type>(<scope>): <subject> (issue#<番号>)

<body>（オプション）
```

### Type 一覧

| Type | 説明 | 例 |
|------|------|-----|
| `feat` | 新機能 | feat(platform): 案件登録APIを実装 |
| `fix` | バグ修正 | fix(worker): 日報入力エラーを修正 |
| `docs` | ドキュメント | docs: READMEを更新 |
| `refactor` | リファクタリング | refactor(platform): モデル構造を整理 |
| `test` | テスト | test(platform): 案件モデルのテスト追加 |
| `chore` | ビルド・設定 | chore: Dockerfileを更新 |

### Scope 一覧

- `platform` - 基幹アプリ
- `worker` - 作業員向けWeb
- `n8n` - ワークフロー
- `db` - データベース
- `docs` - ドキュメント

### 例

```bash
# ✅ 良い例
feat(platform): 4点チェック機能を実装 (issue#1)
fix(worker): 日報の出面入力バリデーションを修正 (issue#5)
docs: ARCHITECTUREにDB設計を追加 (issue#10)

# ❌ 悪い例
update
fix bug
WIP
機能追加
```

---

## コーディング規約

### Rails

#### 1. 早期リターン

```ruby
# ✅ 良い例
def process(project)
  return if project.nil?
  return unless project.valid?
  
  project.save
end

# ❌ 悪い例
def process(project)
  if project.present?
    if project.valid?
      project.save
    end
  end
end
```

#### 2. Service Object

複雑なビジネスロジックはService Objectに抽出：

```ruby
# app/services/project_order_service.rb
class ProjectOrderService
  def initialize(project:, user:)
    @project = project
    @user = user
  end

  def call
    return failure("4点チェック未完了") unless four_point_check_completed?
    
    ActiveRecord::Base.transaction do
      @project.update!(status: :ordered)
      create_handover_checklist
      notify_engineering
    end
    
    success
  end
end
```

#### 3. Concern で共通処理

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable
    after_save :create_audit_log
  end
end

# 使用
class Project < ApplicationRecord
  include Auditable
end
```

### JavaScript (Stimulus)

```javascript
// app/javascript/controllers/daily_report_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["attendanceList", "total"]

  addAttendance() {
    // ...
  }

  calculateTotal() {
    // ...
  }
}
```

### データベース

#### マイグレーション命名

```ruby
# タイムスタンプ_動詞_対象.rb
20250115_create_projects.rb
20250115_add_status_to_projects.rb
20250115_add_index_to_projects_client_id.rb
```

#### カラムコメント必須

```ruby
add_column :projects, :status, :string, comment: "案件ステータス"
add_column :projects, :amount, :decimal, comment: "受注金額（税抜）"
```

---

## テスト方針

### RSpec 必須

```ruby
# spec/models/project_spec.rb
require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:client_id) }
  end

  describe '#four_point_check_completed?' do
    context '4点すべて完了している場合' do
      it 'trueを返す' do
        project = build(:project, :with_all_checks)
        expect(project.four_point_check_completed?).to be true
      end
    end
  end
end
```

### テスト実行

```bash
make platform-test
```

---

## PRチェックリスト

- [ ] Issue番号がコミットに含まれている
- [ ] テストが追加されている
- [ ] RuboCop違反がない
- [ ] マイグレーションがロールバック可能
- [ ] ドキュメントが更新されている（必要な場合）

---

**Last Updated**: 2025-01-15
