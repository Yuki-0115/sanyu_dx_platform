# 変更履歴（CHANGELOG）

フォーマット: [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/)

---

## [Unreleased]

### Added
- 見積テンプレート管理機能（条件書・確認書）
  - EstimateTemplateモデル追加（CRUD対応）
  - 全社共有テンプレート + 個人テンプレートの両方に対応
  - /estimate_templates でテンプレート一覧・作成・編集・削除
  - 見積書作成時にDBからテンプレートを取得
- 有給休暇管理機能
  - PaidLeaveGrant: 有給付与管理（自動付与・手動付与・特別付与）
  - PaidLeaveRequest: 有給申請・承認ワークフロー
  - PaidLeaveGrantService: 勤続年数に基づく自動付与計算
  - PaidLeaveReportService: 有給休暇管理簿CSV出力（労働基準法準拠）
  - 年5日取得義務アラート（経営ダッシュボード連携）
  - FIFO消化ロジック（古い付与分から消化）
  - Stimulusコントローラー: paid_leave_form_controller, paid_leave_approval_controller
- ADR-002: JavaScript開発ルール（Stimulus必須）を追加
- Stimulusコントローラー追加
  - tabs_controller（タブ切り替え）
  - estimate_items_controller（見積明細）
  - estimate_budget_controller（予算計算）
  - template_select_controller（テンプレート挿入）
  - select_all_controller（一括選択）
  - conditional_field_controller（条件表示切替）
  - toggle_controller（表示切替）
  - redirect_select_controller（選択後リダイレクト）
- LINE WORKS通知システム（Bot API直接連携）
  - LineWorksNotifier サービス（JWT認証）
  - NotificationJob 非同期ジョブ
- 通知イベント対応
  - 案件作成、4点チェック完了、着工、完工
  - 実行予算確定、請求書発行、入金確認
  - 有給申請・承認・却下
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
- 実行予算画面に見積書の予算明細を表示（読み取り専用）
- CLAUDE.md: JavaScript開発ルールセクションを追加
- CSP設定: unsafe-inline削除、nonce有効化
- 全ビューのインラインスクリプトをStimulusに移行

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
