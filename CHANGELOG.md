# 変更履歴（CHANGELOG）

フォーマット: [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/)

---

## [Unreleased]

### Security
- VPS公開前セキュリティ強化
  - Devise Lockable有効化（5回失敗で1時間ロック）
  - Devise Timeoutable有効化（8時間無操作でセッション切れ）
  - パスワード最小文字数を8文字に強化
  - rack-attack導入（レート制限: ログイン5回/5分、API 60回/分）
  - XSS対策: project_messageのメンション表示をエスケープ
  - hosts設定追加（ALLOWED_HOST環境変数で制御）
  - bundler-audit導入（依存関係の脆弱性チェック）
  - バックアップ失敗時のWebhook通知機能追加
- バックアップ暗号化 + Google Drive連携
  - openssl AES-256-CBC暗号化対応（ENCRYPT_BACKUP=true）
  - rcloneによるGoogle Drive自動同期（GDRIVE_SYNC=true）
  - restore.shの暗号化ファイル対応
  - 環境変数でオン/オフ切り替え可能

### Added
- 案件チャット機能（ProjectMessage）
  - 営業・工務・事務・経理が案件ごとにやり取りできるチャット
  - 案件詳細ページの右カラム上部に折りたたみ式で表示
  - Turbo Frameによるメッセージ送信・リアルタイム追加
  - 送信者名・役職・日時を表示
  - @メンション機能（オートコンプリート対応）
  - メンションされた社員にLINE WORKS通知
  - サイドバーに未読メンションバッジ表示
  - メッセージ削除機能（自分のメッセージのみ、管理者は全て削除可能）
- 案件別単価テンプレート機能（ProjectCostTemplate）
  - 営業・工務が案件ごとに材料費・外注費・機械費・その他の単価表を登録可能
  - カテゴリ別（材料費/外注費/機械費/その他）に品目名・単位・単価・業者名・備考を設定
  - 案件詳細画面から「単価テンプレート管理」にアクセス
  - 日報フォームに「単価参照」セクションを追加（職長が経費入力時に参照可能）
- 日報・予算に機械費（自社・レンタル）を追加
  - daily_reportsテーブル: machinery_own_cost, machinery_rental_costカラム追加
  - budgetsテーブル: machinery_own_cost, machinery_rental_costカラム追加
  - 日報フォーム・詳細画面に機械費入力欄追加
  - 外部日報フォームにも機械費入力欄追加
  - 現場台帳に機械費（自社・レンタル）の予算対比表示追加
  - 予算フォームに全原価項目入力欄追加（労務費・材料費・外注費・機械自社・機械レンタル・経費）
- 日報経費カテゴリに「機械（自社）」「機械（レンタル）」を追加
- 受領請求書確認機能（経理・営業・工務セクション）
  - ReceivedInvoiceモデル新規作成（3段階確認ワークフロー）
  - 発行元: 協力会社/顧客から選択、または直接入力
  - 請求書ファイル添付（Active Storage）
  - 3段階確認: 経理OK / 営業OK / 工務OK（全員確認で完了）
  - 却下機能（却下時は理由入力必須）
  - サイドバーの経理・営業工務両方に確認待ちバッジ表示
- 段取り表の外注管理を協力会社ベースに変更
  - OutsourcingScheduleモデル新規作成（協力会社×人数または請負）
  - 正社員・仮社員はチェックボックス形式、外注は会社選択＋人数入力
  - 請負の場合は人数非表示、会社名のみ表示
  - セル表示に外注情報を追加（紫色背景で区別）
- 安全書類ファイルプレビュー・差し替え機能
  - file_preview_controller（Stimulus）でPDF・画像のインラインプレビュー
  - モーダル表示でファイル内容を確認可能
  - 個別添付ファイル削除（purge_attachment）で差し替え対応
  - ESCキーまたは背景クリックでモーダルを閉じる
- 原価内訳テンプレート管理機能
  - CostBreakdownTemplateモデル追加（CRUD対応）
  - カテゴリ別テンプレート（材料費、労務費、外注費、経費、その他）
  - 単位選択（式、m、m²、m³、t、kg、本、個、台、人工、日、回、箇所、セット）
  - 全社共有テンプレート + 個人テンプレートの両方に対応
  - /cost_breakdown_templates でテンプレート一覧・作成・編集・削除
  - 見積の予算明細でテンプレートから原価内訳をクイック追加
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
  - 年次有給休暇管理簿PDF出力機能（grover/Puppeteer使用、A4横）
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
  - mention_autocomplete_controller（@メンション候補表示）
  - chat_controller（チャット折りたたみ）
  - chat_form_controller（チャットフォーム制御）
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
