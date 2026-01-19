import { Controller } from "@hotwired/stimulus"

// 受注フローの切り替えに応じて口頭受注セクションの表示/非表示を制御
export default class extends Controller {
  static targets = ["select", "oralSection"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selectedFlow = this.selectTarget.value

    if (selectedFlow === "oral_first") {
      this.oralSectionTarget.classList.remove("hidden")
    } else {
      this.oralSectionTarget.classList.add("hidden")
    }
  }
}
