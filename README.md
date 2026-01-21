# SanyuTech DX Platform

**建設会社の数字を一本で繋ぎ、属人化を排除して粗利をリアルタイムで見える化するDXツール**

[![Rails](https://img.shields.io/badge/Rails-8.0-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791)](https://www.postgresql.org/)
[![n8n](https://img.shields.io/badge/n8n-2.1.1-6e1e78)](https://n8n.io/)
[![License](https://img.shields.io/badge/License-Proprietary-yellow)](#ライセンス)

---

## 📋 目次

- [概要](#概要)
- [主な特徴](#主な特徴)
- [クイックスタート](#クイックスタート)
- [プロジェクト構成](#プロジェクト構成)
- [技術スタック](#技術スタック)
- [ドキュメント](#ドキュメント)

---

## 概要

SanyuTech DX Platform は、建設会社の業務を一気通貫でデジタル化するプラットフォームです。

### ビジョン

> 「数字が見える、壊れない、代わりが効く、成長できる」会社を作る

### 解決する課題

- 売上・原価の数字が曖昧
- 各領域が属人化し、ブラックボックス化
- 担当者が休む・辞めると業務が止まる
- 問題発覚時に原因追跡が困難

---

## 主な特徴

- 📊 **直列型プロセス管理**: 案件→見積→受注→予算→日報→請求→入金を一本で繋ぐ
- 👷 **職長一括日報入力**: 3分で全員分の日報を入力完了
- 💰 **リアルタイム粗利管理**: 案件別の粗利をダッシュボードで即確認
- 🔄 **仮社員相殺自動化**: 給与＋社保を出来高から自動計算
- 🔒 **監査ログ完備**: 誰が・いつ・何を変えたか全記録
- 📱 **現場対応UI**: スマホで日報入力・多言語対応（JP/VN/MM）

---

## 運用方針

### 現在
- **シングルテナント運用**（株式会社サンユウテック専用）
- 社内ミニPCでローカル運用
- 外部公開なし

### 将来構想
- マルチテナント化の可能性あり（他社への展開時）
- その際は tenant_id によるデータ分離を追加予定
- 現在の設計はマルチテナント化を考慮した構造を維持

---

## クイックスタート

### 必要な環境

- Docker 20.10+
- Docker Compose 2.0+
- Git 2.30+
- Make

### セットアップ手順

```bash
# 1. リポジトリクローン
git clone https://github.com/sanyu-tech/sanyu_dx_platform.git
cd sanyu_dx_platform

# 2. 初期セットアップ
make setup

# 3. 環境変数設定
cp .env.local.example .env.local
# .env.local を編集

# 4. Railsアプリ作成（初回のみ）
make platform-new

# 5. サービス起動
make up
```

### アクセスURL

| サービス | URL | 用途 |
|----------|-----|------|
| Platform | http://localhost:3001 | 基幹アプリ（経営/営業/工務/経理） |
| Worker Web | http://localhost:3002 | 作業員向け（日報入力） |
| n8n | http://localhost:5678 | ワークフロー自動化 |

### よく使うコマンド

```bash
# サービス管理
make up                  # 全サービス起動
make down                # 全サービス停止
make logs                # ログ表示
make status              # 状態確認

# Platform
make platform-console    # Railsコンソール
make platform-migrate    # マイグレーション
make platform-shell      # シェル接続

# データベース
make postgres-shell      # PostgreSQL接続
make postgres-backup     # バックアップ作成
```

---

## プロジェクト構成

```
sanyu_dx_platform/
├── config/                    # 設定ファイル
├── docs/
│   ├── adr/                   # Architecture Decision Records
│   └── guides/                # セットアップガイド
├── n8n/
│   └── workflows/             # n8nワークフローテンプレート
├── rails/
│   ├── platform/              # 基幹アプリ（経営/営業/工務/経理）
│   ├── worker_web/            # 作業員向けWeb（日報入力）
│   └── Dockerfile             # Rails用Dockerfile
├── .env                       # 環境変数（公開可）
├── .env.local.example         # 機密情報テンプレート
├── compose.yaml               # Docker Compose定義
├── Makefile                   # 開発コマンド
├── README.md                  # このファイル
├── CLAUDE.md                  # Claude Code向けガイド
├── CONTRIBUTING.md            # 開発規約
└── ARCHITECTURE.md            # 技術設計詳細
```

---

## 技術スタック

| レイヤー | 技術 | バージョン |
|----------|------|------------|
| インフラ | Docker Compose | 2.0+ |
| DB | PostgreSQL | 16-alpine |
| バックエンド | Ruby on Rails | 8.0 |
| フロントエンド | Hotwire (Turbo + Stimulus) | - |
| CSS | Tailwind CSS | 3.0 |
| 認証 | Devise | 4.9+ |
| 自動化 | n8n | 2.1.1 |
| 通知 | LINE WORKS Webhook | - |
| ストレージ | Google Drive API | - |

---

## ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [README.md](./README.md) | プロジェクト概要（このファイル） |
| [CLAUDE.md](./CLAUDE.md) | Claude Code向けクイックリファレンス |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | 開発規約・コミットルール |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 技術設計・DB設計・API設計 |
| [docs/adr/](./docs/adr/) | 設計判断記録 |

---

## ライセンス

All rights reserved. © 株式会社サンユウテック

---

**Last Updated**: 2025-01-15
**Version**: 0.1.0
