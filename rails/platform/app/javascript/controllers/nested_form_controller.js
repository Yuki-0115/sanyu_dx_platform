import { Controller } from "@hotwired/stimulus"

// 出面一括入力など、ネストされたフォームの動的追加・削除を管理
export default class extends Controller {
  static targets = ["template", "mobileTemplate", "container", "mobileContainer", "item"]

  add(event) {
    event.preventDefault()

    const isMobile = window.innerWidth < 1024

    // モバイル用テンプレートとコンテナがある場合
    if (isMobile && this.hasMobileTemplateTarget && this.hasMobileContainerTarget) {
      const template = this.mobileTemplateTarget.innerHTML
      const newIndex = new Date().getTime()
      const newRow = template.replace(/NEW_RECORD/g, newIndex)
      this.mobileContainerTarget.insertAdjacentHTML("beforeend", newRow)
    } else {
      // デスクトップ用（従来の動作）
      const template = this.templateTarget.innerHTML
      const newIndex = new Date().getTime()
      const newRow = template.replace(/NEW_RECORD/g, newIndex)
      this.containerTarget.insertAdjacentHTML("beforeend", newRow)
    }
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest("[data-nested-form-target='item']")

    if (item) {
      // hidden field for _destroy があれば設定
      const destroyField = item.querySelector("input[name*='_destroy']")
      if (destroyField) {
        destroyField.value = "1"
        item.style.display = "none"
      } else {
        item.remove()
      }
    }
  }
}
