import { Controller } from "@hotwired/stimulus"

// トグル（表示切り替え）コントローラー
// 要素の表示/非表示を切り替え
// 使用例:
// <div data-controller="toggle">
//   <button data-action="click->toggle#toggle">切り替え</button>
//   <div data-toggle-target="content" class="hidden">表示/非表示される内容</div>
// </div>

export default class extends Controller {
  static targets = ["content"]
  static values = {
    hiddenClass: { type: String, default: "hidden" }
  }

  toggle(event) {
    event.preventDefault()
    this.contentTargets.forEach(content => {
      content.classList.toggle(this.hiddenClassValue)
    })
  }

  show(event) {
    event.preventDefault()
    this.contentTargets.forEach(content => {
      content.classList.remove(this.hiddenClassValue)
    })
  }

  hide(event) {
    event.preventDefault()
    this.contentTargets.forEach(content => {
      content.classList.add(this.hiddenClassValue)
    })
  }
}
