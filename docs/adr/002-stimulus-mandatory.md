# ADR-002: JavaScriptはStimulus必須、インラインスクリプト禁止

## ステータス

採用（Accepted）

## 日付

2025-02-02

## コンテキスト

### 発生した問題

2025年2月、見積もり編集画面でタブ切り替えボタンが反応しなくなった。

### 原因

Content Security Policy (CSP) の nonce 設定により、インラインスクリプトがブロックされた。

```
1. CSP設定でnonce_directivesが有効だった
2. インラインの<script>タグにはnonce属性が必須になった
3. _form.html.erb等のインラインスクリプトにnonceがなかった
4. ブラウザがスクリプトをすべてブロック
5. タブ切り替えのJavaScriptが実行されず、ボタンが反応しなかった
```

### 技術スタックとの矛盾

- 本プロジェクトはRails 8 + Hotwire (Turbo + Stimulus) を採用
- Stimulusはインラインスクリプトを排除し、外部JSファイルで管理する設計思想
- にもかかわらず、一部画面でインラインスクリプトが残っていた

## 検討した選択肢

### 選択肢A：nonceヘルパーを使う

```erb
<%= javascript_tag nonce: true do %>
  // インラインスクリプト
<% end %>
```

**メリット**
- 作業量が少ない
- インラインスクリプトをそのまま使える

**デメリット**
- Stimulusの設計思想に反する
- インラインスクリプトがビューに散らばったまま
- テストしにくい
- 今後も同じ問題が発生しうる

### 選択肢B：Stimulusコントローラーに移行

**メリット**
- Stimulusの設計思想に沿う
- CSP問題が根本解決（nonce不要、unsafe-inline不要）
- JSが1箇所に集約され保守性向上
- テスト可能
- 将来の拡張に強い

**デメリット**
- 作業量がやや多い
- 全インラインスクリプトの洗い出しが必要

## 決定

**選択肢B：全インラインスクリプトをStimulusに移行し、今後はStimulus必須とする**

## 実施した対応

### 移行したファイル

| ファイル | 変更内容 |
|----------|----------|
| `estimates/_form.html.erb` | タブ切り替え → tabs_controller |
| `estimates/_form_items.html.erb` | 明細CRUD・計算 → estimate_items_controller |
| `estimates/_form_budget.html.erb` | 予算計算 → estimate_budget_controller |
| `estimates/_form_conditions.html.erb` | テンプレート挿入 → template_select_controller |
| `accounting/expenses/_cash_tab.html.erb` | 一括選択 → select_all_controller |
| `accounting/expenses/_card_tab.html.erb` | 一括選択 → select_all_controller |
| `expense_reports/new.html.erb` | 条件表示切替 → conditional_field_controller |
| `expense_reports/edit.html.erb` | 条件表示切替 → conditional_field_controller |
| `master/payment_terms/_form.html.erb` | 条件表示切替 → conditional_field_controller |
| `all_invoices/index.html.erb` | 選択後リダイレクト → redirect_select_controller |
| `master/company_holidays/index.html.erb` | 行事フォーム表示 → toggle_controller |
| `offsets/_form.html.erb` | 集計値反映 → offset_form_controller |

### CSP設定（最終状態）

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.script_src  :self  # unsafe-inline不要
    policy.style_src   :self, :unsafe_inline  # Tailwind CSS用
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
```

## 結果

- インラインスクリプト：0件
- CSPエラー：なし
- 全画面正常動作確認済み

## 今後のルール

### 禁止事項

- `<script>...</script>` のインライン記述
- `onclick`, `onchange`, `onsubmit` 等のイベントハンドラ属性
- `javascript:` URLスキーム

### 必須事項

- JavaScriptは必ずStimulusコントローラーで実装
- `data-controller`, `data-action`, `data-*-target` でビューと接続

### 違反チェック

```bash
# インラインスクリプトの検出
grep -r "<script" app/views/ --include="*.erb" -l
grep -rE "(onclick|onchange|onsubmit|onload)=" app/views/ --include="*.erb" -l
```

## 参考資料

- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Rails CSP Guide](https://guides.rubyonrails.org/security.html#content-security-policy)
- [Content Security Policy (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
