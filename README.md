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

### 実装済み

**営業・工務**
- 案件管理（登録・編集・4点チェック・着工前ゲート）
- 見積管理（見積書作成・テンプレート・PDF出力）
- 実行予算（見積取込・原価管理）
- 段取り表（週間スケジュール・人員配置・外注配置）
- 日報入力（職長一括、3分で完了）
- 原価管理（労務・材料・外注・機械・経費）
- 単価テンプレート（案件別単価表・職長参照用）
- 現場台帳（予算対比・粗利管理）
- 出来高管理（月次出来高入力）
- 請求管理（請求書発行・入金管理）

**経理**
- 月次損益計算書（3層構造）
- 月次確定給与・確定外注費
- 経費処理（掛け払い・カード・立替）
- 仮経費確定（ガソリン・ETC）
- 立替精算
- 受領請求書確認（3段階承認）
- 販管費管理
- 資金繰り表

**事務**
- 仮社員相殺
- 有給管理・有給申請
- 安全書類管理

**共通**
- 経営ダッシュボード（粗利一覧・赤字アラート）
- マスタ管理（顧客・協力会社・社員）
- 権限管理（RBAC）
- 監査ログ

### 開発予定
- 見積OCR取込
- LINE WORKS通知連携
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
| 認証 | Devise |
| 自動化 | n8n |
| 通知 | LINE WORKS |
| ストレージ | Google Drive |
| OCR | Claude Vision API |

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
