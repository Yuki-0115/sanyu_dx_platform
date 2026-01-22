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
- 案件管理（登録・編集・4点チェック）
- 日報入力（職長一括、3分で完了）
- 原価管理（労務・材料・外注・経費）
- 段取り表（週間スケジュール）
- 月間カレンダー（休日・行事）
- 請求管理
- 仮社員相殺
- 経営ダッシュボード（粗利一覧・赤字アラート）
- 権限管理（RBAC）
- 監査ログ

### 開発予定
- **Phase 1**: 見積OCR取込 → 実行予算連携
- **Phase 2**: 案件登録強化（事務連絡メモ + LINE通知）
- **Phase 3**: 現場台帳（3層構造）+ 労務単価編集
- **Phase 4**: 経費申請（承認フロー → 原価自動反映）
- **Phase 5**: 経理強化（請求書OCR + Google Drive連携）
- **Phase 6**: 外注請負（出来高精算）
- **Phase 7**: 月次帳票（損益計算書 → 工事部門 → 現場台帳）
- **Phase 8**: freee連携（将来）

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
