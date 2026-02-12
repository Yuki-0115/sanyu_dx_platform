# SanyuTech DX Platform

建設会社の数字を一本で繋ぎ、属人化を排除して粗利をリアルタイムで見える化するDXツール

[![Rails](https://img.shields.io/badge/Rails-8.0-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-Proprietary-yellow)](#ライセンス)

---

## 運用方針

### 現在
- **シングルテナント運用**（株式会社サンユウテック専用）
- 社内サーバー（ミニPC）+ Cloudflare Tunnel で外部公開
- 現場からスマホでアクセス可能

### 将来構想
- マルチテナント化の可能性あり（他社展開時）
- freee会計との連携

---

## 主な機能

### Platform（基幹アプリ）

**営業・工務**
- 案件管理（登録・編集・4点チェック・着工前ゲート）
- 見積管理（見積書作成・テンプレート・PDF出力）
- 実行予算（見積取込・原価管理）
- 段取り表（週間スケジュール・人員配置・外注配置・一括配置）
- 日報入力（職長一括、出面・経費・燃料・高速）
- 常用日報（外部現場向け）
- 原価管理（労務・材料・外注・機械・経費）
- 単価テンプレート（基本単価・案件別単価・職長参照用）
- 現場台帳（予算対比・粗利管理）
- 出来高管理（月次出来高入力）
- 請求管理（請求書発行・入金管理）
- 案件内メッセージ（@メンション・通知連携）
- 書類ファイリング（案件別ドキュメント管理）

**経理**
- 月次損益計算書（3層構造：会計形式・工事部門・現場台帳）
- 月次確定給与・確定外注費
- 経費処理（掛け払い・カード・立替）
- 仮経費確定（ガソリン・ETC・レシート写真添付）
- 立替精算
- 受領請求書確認（3段階承認：経理→営業→工務）
- 販管費管理
- 資金繰り表（カレンダー形式・予実管理）
- 月次固定費（現場別）
- 月次帳票出力（CSV：原価・損益・経費レポート）
- 経費報告（日報外経費）

**事務**
- 仮社員相殺
- 有給管理・有給申請（PDF出力・一括付与）
- 安全書類管理（フォルダ・ファイル・案件別必要書類設定）
- 安全書類ステータストラッキング
- 勤怠管理表（社員別・案件別・CSV出力）

**共通**
- 経営ダッシュボード（粗利一覧・赤字アラート）
- マスタ管理（顧客・協力会社・社員・支払条件・固定費スケジュール）
- 会社カレンダー（休日・イベント管理）
- 権限管理（RBAC：7ロール）
- 監査ログ
- LINE WORKS通知（案件作成・4点チェック・着工・日報等）
- Google Drive連携（案件フォルダ自動作成・バックアップ同期）
- データ取込（Excel一括投入・テンプレートダウンロード）
- テンプレート管理（見積・原価内訳・単位・見積項目）

### Worker Web（作業員向けアプリ）

- 段取り表閲覧（自分の配置確認）
- 日報入力（出面・経費・燃料・高速の報告）
- 有給申請（個人からの申請・ステータス確認）

### 開発予定
- 見積OCR取込（Claude Vision API）
- freee会計連携

---

## 帳票構造（3層）

```
【第1層】月次損益計算書
・会計フォーマット
・正の数字（実際給与）
・freee連携を見据えた構造
│
▼
【第2層】工事部門損益
・総現場売上 - 総工事原価 - 現場固定費
・案件別内訳
│
▼
【第3層】個別現場台帳
・労務費は人工計算（¥18,000基準）
・経費は生の数字
・第2層とは差異あり（当然）
```

---

## 技術スタック

| レイヤー | 技術 |
|----------|------|
| インフラ | Docker Compose |
| DB | PostgreSQL 16 |
| バックエンド | Ruby on Rails 8 |
| フロントエンド | Hotwire (Turbo + Stimulus) |
| CSS | Tailwind CSS 3 |
| アセット | Propshaft + importmap |
| 認証 | Devise |
| PDF生成 | Grover (Puppeteer) |
| 自動化 | n8n |
| 通知 | LINE WORKS Bot API |
| ストレージ | Google Drive (rclone) |
| バックアップ | AES-256-CBC暗号化 + Google Drive同期 |
| OCR | Claude Vision API（予定） |

---

## クイックスタート

```bash
# クローン
git clone https://github.com/Yuki-0115/sanyu_dx_platform.git
cd sanyu_dx_platform

# 環境変数設定
cp .env.local.example .env.local

# 起動
make up
```

### アクセスURL

| サービス | URL |
|----------|-----|
| Platform | http://localhost:3001 |
| Worker Web | http://localhost:3002 |
| n8n | http://localhost:5678 |

### 主なMakeコマンド

```bash
# サービス管理
make up                  # 全サービス起動
make down                # 全サービス停止
make logs                # ログ表示
make status              # 状態確認

# Platform
make platform-shell      # シェル接続
make platform-console    # Railsコンソール
make platform-migrate    # マイグレーション
make platform-seed       # シードデータ
make platform-test       # テスト実行

# Worker Web
make worker-shell        # シェル接続
make worker-console      # Railsコンソール

# バックアップ
make postgres-backup     # DBバックアップ
make backup-gdrive       # Google Drive同期
```

---

## ドキュメント

| ファイル | 内容 |
|----------|------|
| README.md | プロジェクト概要（このファイル） |
| CLAUDE.md | Claude Code向けガイド |
| ARCHITECTURE.md | 技術設計・DB設計 |
| CONTRIBUTING.md | 開発規約 |
| CHANGELOG.md | 変更履歴 |

---

## ライセンス

All rights reserved. (C) 株式会社サンユウテック
