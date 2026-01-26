import { Controller } from "@hotwired/stimulus"

// 人工/請負の切り替えで表示を切り替えるコントローラー
export default class extends Controller {
  static targets = ["select", "manDaysFields", "contractFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isContract = this.selectTarget.value === "contract"

    this.manDaysFieldsTargets.forEach(el => {
      el.classList.toggle("hidden", isContract)
    })

    this.contractFieldsTargets.forEach(el => {
      el.classList.toggle("hidden", !isContract)
    })
  }
}
