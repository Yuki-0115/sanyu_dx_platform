# 変更履歴（CHANGELOG）

フォーマット: [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/)

---

## [Unreleased]

### Added
- LINE WORKS通知システム（Bot API直接連携）
  - LineWorksNotifier サービス（JWT認証）
  - NotificationJob 非同期ジョブ
- 通知イベント対応
  - 案件作成、4点チェック完了、着工、完工
  - 実行予算確定、請求書発行、入金確認
- Google Drive連携
  - GoogleDriveService（案件フォルダ自動作成）
  - 案件作成時にサブフォルダ自動生成（見積・現場管理・安全・写真・竣工・請求）
  - 書類アップロード時にDriveへ自動同期
  - ProjectDocumentにdrive_file_urlカラム追加
- 月次帳票機能
  - MonthlyReportGenerator サービス
  - 原価集計・案件別利益・経費精算レポート（CSV）
  - 月次帳票画面（/monthly_reports）
  - Google Driveへの自動保存

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
