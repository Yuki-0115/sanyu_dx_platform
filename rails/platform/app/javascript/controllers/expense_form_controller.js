import { Controller } from "@hotwired/stimulus"

// 経費入力の動的追加・削除を管理
export default class extends Controller {
  static targets = ["template", "container", "item", "destroyField"]

  // 掛け払い対象のカテゴリ（仕入先必須）
  static creditCategories = ["material", "machinery_rental"]

  add(event) {
    event.preventDefault()

    const template = this.templateTarget.innerHTML
    const newIndex = new Date().getTime()
    const newRow = template.replace(/NEW_RECORD/g, newIndex)

    this.containerTarget.insertAdjacentHTML("beforeend", newRow)

    // 追加した項目のフィールド表示を更新
    const items = this.containerTarget.querySelectorAll("[data-expense-form-target='item']")
    const lastItem = items[items.length - 1]
    if (lastItem) {
      this.updateFieldVisibility(lastItem)
    }
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest("[data-expense-form-target='item']")

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

  // カテゴリ変更時
  categoryChanged(event) {
    const item = event.target.closest("[data-expense-form-target='item']")
    if (!item) return

    const category = event.target.value
    const paymentMethodSelect = item.querySelector(".expense-payment-method")

    // 材料費・機械レンタルは掛け払いをデフォルトに
    if (this.constructor.creditCategories.includes(category)) {
      if (paymentMethodSelect) {
        paymentMethodSelect.value = "credit"
      }
    }

    this.updateFieldVisibility(item)
  }

  // 支払方法変更時
  paymentMethodChanged(event) {
    const item = event.target.closest("[data-expense-form-target='item']")
    if (item) {
      this.updateFieldVisibility(item)
    }
  }

  // フィールド表示の更新
  updateFieldVisibility(item) {
    const categorySelect = item.querySelector(".expense-category")
    const paymentMethodSelect = item.querySelector(".expense-payment-method")
    const supplierField = item.querySelector(".expense-supplier-field")
    const payeeField = item.querySelector(".expense-payee-field")

    if (!categorySelect || !paymentMethodSelect) return

    const category = categorySelect.value
    const paymentMethod = paymentMethodSelect.value

    // 掛け払い、または材料費・機械レンタルの場合は仕入先を表示
    const showSupplier = paymentMethod === "credit" || this.constructor.creditCategories.includes(category)

    if (supplierField) {
      supplierField.classList.toggle("hidden", !showSupplier)
    }
    if (payeeField) {
      payeeField.classList.toggle("hidden", showSupplier)
    }
  }
}
