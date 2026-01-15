# 未処理Issue一覧

GitHub remote設定後に `gh issue create` で登録してください。

---

## Issue #1: 実行予算作成時に見積データを取り込む機能

### 概要
現在の実行予算は手入力のみだが、見積書データを取り込んで実行予算のベースとして使用できるようにしたい。

### 原因 / 背景
- 見積と実行予算で同じ項目を二重入力する手間がある
- 見積から実行予算への変換は業務フローとして自然

### 解決策 / 対応内容
- 見積モデル（Estimate）との連携
- 「見積から取り込み」ボタンを実行予算作成画面に追加
- 見積の材料費・外注費・労務費・経費を実行予算にコピー
- 取り込み後に編集可能（実行予算として調整）

### 影響範囲
- `app/controllers/budgets_controller.rb`
- `app/views/budgets/_form.html.erb`
- `app/models/estimate.rb`（必要に応じて作成）

---

## Issue #2: 日報入力内容が案件の実績原価に反映されない

### 概要
日報で入力した労務費・材料費・外注費・輸送費が、案件（Project）の実績原価（actual_cost）に集計・反映されていない。

### 原因 / 背景
- 日報に原価関連フィールド（labor_details, materials_used, outsourcing_details, transportation_cost）は追加済み
- しかしこれらを集計してProjectのactual_costに反映するロジックが未実装

### 解決策 / 対応内容
1. DailyReportに金額フィールドを追加（現在はテキストのみ）
   - `labor_cost` (decimal)
   - `material_cost` (decimal)
   - `outsourcing_cost` (decimal)
   - `transportation_cost` は既存
2. Projectモデルに `calculate_actual_cost` メソッド追加
3. DailyReport確定時にProjectのactual_costを再計算
4. または、`Project#actual_cost` をメソッドとして動的に計算

### 影響範囲
- `app/models/project.rb`
- `app/models/daily_report.rb`
- `db/migrate/` （日報に金額カラム追加）
- `app/views/daily_reports/_form.html.erb`

### セキュリティ影響
なし

---

## Issue #3: 常用現場対応（案件に「その他」選択肢追加）

### 概要
常用（日雇い・応援）で他社現場に行く場合、自社案件として登録されていない現場で作業することがある。
日報入力時に「その他」を選択し、現場名を自由入力できるようにしたい。

### 原因 / 背景
- 現状は自社案件（Project）に紐づく日報しか作成できない
- 常用で他社現場に行く場合の出面管理ができない
- 売上は発生するが案件管理対象外のケース

### 解決策 / 対応内容
1. DailyReportに `is_external` フラグ追加
2. DailyReportに `external_site_name` フィールド追加
3. 日報作成時に案件選択で「その他（常用）」を選択可能に
4. 「その他」選択時は現場名を自由入力
5. project_id を nullable に変更

### 影響範囲
- `app/models/daily_report.rb`
- `app/controllers/daily_reports_controller.rb`
- `app/views/daily_reports/_form.html.erb`
- `db/migrate/` （external関連カラム追加）

### セキュリティ影響
なし

---

**Last Updated**: 2026-01-15
