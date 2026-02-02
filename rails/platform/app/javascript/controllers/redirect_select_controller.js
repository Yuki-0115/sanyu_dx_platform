import { Controller } from "@hotwired/stimulus"

// 選択→リダイレクトコントローラー
// セレクトボックスの値を使ってURLを構築しリダイレクト
// 使用例:
// <div data-controller="redirect-select" data-redirect-select-url-template-value="/projects/:id/invoices/new">
//   <select data-redirect-select-target="select">
//     <option value="">選択してください</option>
//     <option value="1">Project 1</option>
//   </select>
//   <button data-action="click->redirect-select#redirect">作成</button>
// </div>

export default class extends Controller {
  static targets = ["select"]
  static values = {
    urlTemplate: String,
    alertMessage: { type: String, default: "選択してください" }
  }

  redirect(event) {
    event.preventDefault()

    const value = this.selectTarget.value

    if (!value) {
      alert(this.alertMessageValue)
      return
    }

    const url = this.urlTemplateValue.replace(":id", value)
    window.location.href = url
  }
}
