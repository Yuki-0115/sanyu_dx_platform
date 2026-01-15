# 未処理Issue一覧

GitHub remote設定後に `gh issue create` で登録してください。

---

## Issue #1: 実行予算作成時に見積データを取り込む機能 ✅ 完了

### 概要
現在の実行予算は手入力のみだが、見積書データを取り込んで実行予算のベースとして使用できるようにしたい。

### 対応完了（2026-01-15）
- Estimateモデル新規作成（原価・売価・利益率管理）
- EstimatesController新規作成（CRUD + 承認機能）
- BudgetsControllerにimport_from_estimate アクション追加
- 予算フォームに「見積から取り込み」ボタン追加
- 案件詳細ページに見積書セクション追加
- commit: 3b8e81e

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

## Issue #4: 請求書機能の詳細化

### 概要
現在の請求書機能はシンプルな構成だが、実務に合わせてより詳細な項目・機能が必要。

### 対応内容（未着手）
- [ ] 請求明細行（品名、数量、単価、金額）の追加
- [ ] 振込先情報の設定
- [ ] 請求書番号の自動採番
- [ ] PDF出力機能
- [ ] 請求書テンプレート対応

### 影響範囲
- `Invoice` モデル
- `InvoiceItem` モデル（新規）
- 請求書フォーム・ビュー

---

## Issue #5: 案件の請求・入金状況表示

### 概要
請求書を発行した案件について、既支払額（入金済み金額）と契約残高（受注金額 - 入金済み金額）を確認できるようにする。

### 対応内容（未着手）
- [ ] 案件詳細ページに請求・入金サマリーを追加
  - 受注金額
  - 請求済み金額（発行済み請求書の合計）
  - 入金済み金額
  - 契約残高（受注金額 - 入金済み）
- [ ] 案件一覧に入金状況列を追加（オプション）
- [ ] Projectモデルに計算メソッド追加

### 影響範囲
- `Project` モデル
- `app/views/projects/show.html.erb`
- `app/views/projects/index.html.erb`

---

**Last Updated**: 2026-01-15
