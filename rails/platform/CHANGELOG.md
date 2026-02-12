# CHANGELOG

## [Unreleased]

### Changed
- README.md を実態に合わせて全面更新（機能一覧・技術スタック・Makeコマンド追記）
- ARCHITECTURE.md を v2.0.0 に刷新（全58テーブル・コントローラー構成・サービス層・外部連携）
- CLAUDE.md の機能状態・フェーズ進捗を実態に同期

### Added
- データ移行機能（簡易案件登録 + Excel一括投入）
  - `admin/quick_projects` — 手入力でざっくり案件登録
  - `admin/data_imports` — Excelからまとめて投入（テンプレートDL対応）
  - 移行時の累計出来高・累計原価を案件に記録（`initial_revenue`, `initial_cost`）
  - 案件別粗利には反映、月次損益には反映しない仕様
  - サイドバーに「データ移行」リンクを追加
  - Excelテンプレート：全項目日本語ヘッダー化 + プルダウン選択式
  - インポートサービス：日本語ヘッダー・日本語選択値を自動変換
