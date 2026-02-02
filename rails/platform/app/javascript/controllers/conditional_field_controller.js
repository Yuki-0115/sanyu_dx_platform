import { Controller } from "@hotwired/stimulus"

// 条件付きフィールド表示コントローラー
// セレクトや入力値に応じてフィールドの表示/非表示を切り替え
// 使用例:
// <div data-controller="conditional-field">
//   <select data-conditional-field-target="trigger" data-action="change->conditional-field#update">
//     <option value="a">A</option>
//     <option value="b">B</option>
//   </select>
//   <div data-conditional-field-target="field" data-show-when="a">Aの時だけ表示</div>
//   <div data-conditional-field-target="field" data-show-when="b">Bの時だけ表示</div>
// </div>

export default class extends Controller {
  static targets = ["trigger", "field"]
  static values = {
    hiddenClass: { type: String, default: "hidden" }
  }

  connect() {
    this.update()
  }

  update() {
    const value = this.triggerTarget.value

    this.fieldTargets.forEach(field => {
      const showWhen = field.dataset.showWhen
      const hideWhen = field.dataset.hideWhen

      let shouldShow = true

      if (showWhen) {
        // showWhenが設定されている場合、値が一致する時のみ表示
        const showValues = showWhen.split(",").map(v => v.trim())
        shouldShow = showValues.includes(value)
      }

      if (hideWhen) {
        // hideWhenが設定されている場合、値が一致する時は非表示
        const hideValues = hideWhen.split(",").map(v => v.trim())
        if (hideValues.includes(value)) {
          shouldShow = false
        }
      }

      if (shouldShow) {
        field.classList.remove(this.hiddenClassValue)
        // フィールド内のinput/selectを有効化
        field.querySelectorAll("input, select, textarea").forEach(input => {
          input.disabled = false
        })
      } else {
        field.classList.add(this.hiddenClassValue)
        // フィールド内のinput/selectを無効化
        field.querySelectorAll("input, select, textarea").forEach(input => {
          input.disabled = true
        })
      }
    })
  }
}
