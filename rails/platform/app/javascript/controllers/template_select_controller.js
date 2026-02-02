import { Controller } from "@hotwired/stimulus"

// テンプレート選択コントローラー
// セレクトボックスで選択したテンプレートをテキストエリアに挿入

export default class extends Controller {
  static targets = ["select", "textarea"]
  static values = {
    templates: Object,
    confirmMessage: { type: String, default: "現在の内容を上書きしますか？" }
  }

  insert(event) {
    const templateName = this.selectTarget.value
    if (!templateName) return

    const template = this.templatesValue[templateName]
    if (!template) return

    const textarea = this.textareaTarget

    if (textarea.value.trim() === "" || confirm(this.confirmMessageValue)) {
      textarea.value = template
    }

    // セレクトをリセット
    this.selectTarget.value = ""
  }
}
