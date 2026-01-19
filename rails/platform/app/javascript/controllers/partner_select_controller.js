import { Controller } from "@hotwired/stimulus"

// 協力会社選択時に手入力欄の表示/非表示を切り替える
export default class extends Controller {
  static targets = ["select", "input"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (this.hasSelectTarget && this.hasInputTarget) {
      const isManual = this.selectTarget.value === ""
      this.inputTarget.style.display = isManual ? "block" : "none"
      if (!isManual) {
        this.inputTarget.value = ""
      }
    }
  }
}
