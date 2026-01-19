import { Controller } from "@hotwired/stimulus"

// 出面入力で社員選択 or 協力会社作業員名入力を切り替える
export default class extends Controller {
  static targets = ["select", "input"]

  connect() {
    this.toggleInput()
  }

  toggleInput() {
    const hasEmployee = this.selectTarget.value !== ""
    this.inputTarget.style.display = hasEmployee ? "none" : "block"

    // 社員が選択された場合は手入力フィールドをクリア
    if (hasEmployee) {
      this.inputTarget.value = ""
    }
  }
}
