# 変更履歴（CHANGELOG）

すべての重要な変更はこのファイルに記録する。

フォーマット: [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/)

---

## [Unreleased]

### Added

### Changed

### Removed

### Fixed

---

## [0.2.0] - 2025-01-21

### Changed
- シングルテナント運用に変更（マルチテナント機能を削除）
- Docker構成を整理（プロジェクト名: sanyu-dx、コンテナ名統一）

### Removed
- tenant_id 関連のバリデーション・Concern・コントローラー処理

---

## [0.1.0] - 2025-01-15

### Added
- 初期リリース
- 案件管理、日報入力、原価管理、ダッシュボード
- 段取り表、カレンダー、休日・行事管理
- Docker Compose 環境構築
- Worker Web（作業員向け日報入力）
