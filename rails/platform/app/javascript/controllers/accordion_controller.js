import { Controller } from "@hotwired/stimulus"

// アコーディオン開閉コントローラー
export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // 初期状態をDOMから判断（hiddenクラスがあれば閉じた状態）
    if (this.hasContentTarget) {
      this.isOpen = !this.contentTarget.classList.contains("hidden")
    } else {
      this.isOpen = true
    }
  }

  toggle() {
    this.isOpen = !this.isOpen

    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.isOpen)
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("rotate-180", !this.isOpen)
    }
  }
}
