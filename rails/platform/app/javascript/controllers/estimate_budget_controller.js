import { Controller } from "@hotwired/stimulus"

// 見積もり予算明細コントローラー
// 予算計算、セクションの展開/折りたたみを管理

export default class extends Controller {
  static targets = [
    "categorySection",
    "directCost",
    "budgetTotal",
    "grossProfit",
    "profitRate"
  ]

  connect() {
    this.calculateTotals()

    // 内訳明細タブからの更新イベントをリッスン
    window.addEventListener("estimate-items:calculated", this.handleEstimateUpdate.bind(this))
  }

  disconnect() {
    window.removeEventListener("estimate-items:calculated", this.handleEstimateUpdate.bind(this))
  }

  handleEstimateUpdate(event) {
    if (this.hasDirectCostTarget && event.detail.subtotal !== undefined) {
      this.directCostTarget.textContent = this.formatCurrency(event.detail.subtotal)
      this.calculateTotals()
    }
  }

  // セクションの展開/折りたたみ
  toggleCategory(event) {
    const header = event.currentTarget
    const section = header.closest(".budget-category-section")
    const content = section.querySelector(".budget-category-content")
    const chevron = header.querySelector(".budget-chevron")

    if (content.style.display === "none") {
      content.style.display = "block"
      chevron.style.transform = "rotate(0deg)"
    } else {
      content.style.display = "none"
      chevron.style.transform = "rotate(-90deg)"
    }
  }

  // 予算単価変更時の計算（後方互換性のため残す）
  calculateRow(event) {
    // budget-item コントローラーが処理するため、ここでは何もしない
  }

  // 内訳明細タブへ切り替え
  goToItems(event) {
    event.preventDefault()
    const tabsController = this.element.closest("[data-controller*='tabs']")
    if (tabsController) {
      const itemsTab = tabsController.querySelector("[data-tab-name='items']")
      if (itemsTab) itemsTab.click()
    }
  }

  formatCurrency(amount) {
    return "¥" + Math.round(amount).toLocaleString()
  }
}
