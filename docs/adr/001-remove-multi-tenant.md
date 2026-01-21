# ADR-001: マルチテナント機能の削除

## ステータス
採用（2026-01-21）

## コンテキスト
当初、将来的な複数会社対応を見据えてマルチテナント設計を採用していた。
しかし、現時点では自社専用システムとして運用するため、不要な複雑性を排除することにした。

## 決定
マルチテナント機能を完全に削除し、シングルテナント運用とする。

## 削除した内容

### モデル・Concern
- `app/models/tenant.rb` - Tenantモデル
- `app/models/concerns/tenant_scoped.rb` - TenantScoped concern

### データベース
以下22テーブルから `tenant_id` カラムを削除:
- attendances, audit_logs, budgets, clients, daily_reports
- daily_schedule_notes, employees, estimates, expenses
- invoice_items, invoices, offsets, outsourcing_entries
- partners, payments, project_assignments, project_documents
- projects, safety_files, safety_folders, work_schedules

`tenants` テーブルを削除。

### コントローラー
- `ApplicationController#set_current_tenant` を削除
- `Api::V1::BaseController#set_tenant_from_code` を削除

### モデル変更
全21モデルから以下を削除:
- `include TenantScoped`
- バリデーションの `scope: :tenant_id`

### Current クラス
- `Current.tenant_id` 属性を削除

## 結果

### メリット
- コードの簡素化（約200行削減）
- クエリのシンプル化（default_scope不要）
- デバッグの容易さ

### デメリット
- 将来マルチテナント化する場合は再実装が必要

## 関連コミット
- `7e8da11` - refactor(platform): テナント分離機能を削除（シングルテナント運用）
- `a281ddb` - docs: テナント分離削除に伴うドキュメント更新
