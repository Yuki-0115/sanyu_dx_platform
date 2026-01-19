import { Controller } from "@hotwired/stimulus"

// アコーディオン開閉コントローラー
export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // 初期状態は開いた状態
    this.isOpen = true
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
