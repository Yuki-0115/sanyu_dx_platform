# 変更履歴（CHANGELOG）

フォーマット: [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/)

---

## [Unreleased]

### Added
- LINE WORKS通知システム（n8n Webhook連携）
  - LineWorksNotifier サービス（Singletonパターン）
  - NotificationJob 非同期ジョブ
  - n8n ワークフローJSON（lineworks_notifications.json）
- 通知イベント対応
  - 案件作成（project_created）
  - 4点チェック完了（four_point_completed）
  - 着工前ゲート完了（pre_construction_completed）
  - 着工（construction_started）
  - 完工（project_completed）
  - 実行予算確定（budget_confirmed）
  - 請求書発行（invoice_issued）
  - 入金確認（payment_received）

### Changed

### Removed

### Fixed
- 請求書詳細画面：存在しない payment_method カラムを削除

---

## [0.2.0] - 2025-01-22

### Changed
- シングルテナント運用に変更
- Docker構成整理（プロジェクト名: sanyu-dx）
- ドキュメント全面更新（README, CLAUDE.md）

### Removed
- tenant_id 関連のバリデーション・Concern

### Added
- CHANGELOG.md 作成
- 開発フェーズ計画を明記

---

## [0.1.0] - 2025-01-15

### Added
- 初期リリース
- 案件管理、日報、原価管理、ダッシュボード
- Docker Compose 環境構築
