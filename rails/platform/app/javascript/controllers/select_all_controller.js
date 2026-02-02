import { Controller } from "@hotwired/stimulus"

// チェックボックス全選択コントローラー
// 使用例:
// <div data-controller="select-all">
//   <input type="checkbox" data-select-all-target="all" data-action="change->select-all#toggle">
//   <input type="checkbox" data-select-all-target="checkbox">
//   <input type="checkbox" data-select-all-target="checkbox">
// </div>

export default class extends Controller {
  static targets = ["all", "checkbox"]

  toggle(event) {
    const isChecked = event.currentTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })
  }

  // 個別チェックボックスの変更時に全選択の状態を更新
  updateAll() {
    if (!this.hasAllTarget) return

    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    const someChecked = this.checkboxTargets.some(checkbox => checkbox.checked)

    this.allTarget.checked = allChecked
    this.allTarget.indeterminate = someChecked && !allChecked
  }
}
