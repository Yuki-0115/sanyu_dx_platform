import { Controller } from "@hotwired/stimulus"

// 自動入力コントローラー
// ボタンクリックで指定された値をフィールドに自動入力
// 使用例:
// <div data-controller="auto-fill">
//   <input data-auto-fill-target="field" data-field-name="salary">
//   <input data-auto-fill-target="field" data-field-name="insurance">
//   <button data-action="click->auto-fill#fill"
//           data-auto-fill-salary-param="100000"
//           data-auto-fill-insurance-param="15000">
//     自動入力
//   </button>
// </div>

export default class extends Controller {
  static targets = ["field"]

  fill(event) {
    event.preventDefault()

    this.fieldTargets.forEach(field => {
      const fieldName = field.dataset.fieldName
      if (fieldName) {
        // パラメータ名は data-auto-fill-{fieldName}-param
        const paramValue = event.params[fieldName]
        if (paramValue !== undefined) {
          field.value = paramValue
          // changeイベントを発火（他のコントローラーとの連携用）
          field.dispatchEvent(new Event("change", { bubbles: true }))
        }
      }
    })
  }
}
