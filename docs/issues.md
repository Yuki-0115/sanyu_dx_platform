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

## Issue #2: 日報入力内容が案件の実績原価に反映されない ✅ 完了

### 概要
日報で入力した労務費・材料費・外注費・輸送費が、案件（Project）の実績原価（actual_cost）に集計・反映されていない。

### 対応完了（2026-01-15）
- DailyReportに金額フィールド追加（labor_cost, material_cost, outsourcing_cost）
- Project.calculated_actual_costで確定済み日報から動的計算
- 日報フォームに原価金額入力欄を追加（青色ボックス内）
- commit: ebedef6

---

## Issue #3: 常用現場対応（案件に「その他」選択肢追加）✅ 完了

### 概要
常用（日雇い・応援）で他社現場に行く場合、自社案件として登録されていない現場で作業することがある。
日報入力時に「その他」を選択し、現場名を自由入力できるようにしたい。

### 対応完了（2026-01-15）
- DailyReportに is_external, external_site_name フィールド追加
- project_id を nullable に変更
- ExternalDailyReportsController 新規作成（/external_daily_reports）
- ダッシュボードに常用日報へのリンク追加
- commit: e92d09a

---

**Last Updated**: 2026-01-15
