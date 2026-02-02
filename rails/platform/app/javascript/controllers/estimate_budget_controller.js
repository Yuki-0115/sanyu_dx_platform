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

  // 予算単価変更時の計算
  calculateRow(event) {
    this.calculateTotals()
  }

  // 全体の予算を計算
  calculateTotals() {
    let budgetTotal = 0

    // 各カテゴリの小計を計算
    this.element.querySelectorAll(".budget-category-section").forEach(section => {
      let categoryTotal = 0

      section.querySelectorAll(".budget-item-row").forEach(row => {
        if (row.style.display !== "none") {
          const qty = parseFloat(row.dataset.estimateQty) || 0
          const price = parseFloat(row.querySelector(".budget-price")?.value) || 0
          const amount = Math.round(qty * price)
          categoryTotal += amount

          const amountCell = row.querySelector(".budget-amount")
          if (amountCell) {
            amountCell.textContent = amount > 0 ? this.formatCurrency(amount) : "-"
          }
        }
      })

      // カテゴリヘッダーの予算表示を更新
      const categoryTotalEl = section.querySelector(".budget-category-total")
      if (categoryTotalEl) {
        categoryTotalEl.textContent = "予算: " + this.formatCurrency(categoryTotal)
      }

      // カテゴリフッターの小計を更新
      const categorySubtotalEl = section.querySelector(".budget-category-subtotal")
      if (categorySubtotalEl) {
        categorySubtotalEl.textContent = this.formatCurrency(categoryTotal)
      }

      budgetTotal += categoryTotal
    })

    // 全体の予算表示を更新
    if (this.hasBudgetTotalTarget) {
      this.budgetTotalTarget.textContent = this.formatCurrency(budgetTotal)
    }

    // 見積金額を取得
    const directCost = this.hasDirectCostTarget
      ? parseInt(this.directCostTarget.textContent.replace(/[¥,]/g, "")) || 0
      : 0

    // 粗利計算
    const grossProfit = directCost - budgetTotal
    const profitRate = directCost > 0 ? (grossProfit / directCost * 100).toFixed(1) : 0

    if (this.hasGrossProfitTarget) {
      this.grossProfitTarget.textContent = this.formatCurrency(grossProfit)
      this.grossProfitTarget.className = "text-xl font-bold " + (grossProfit >= 0 ? "text-green-600" : "text-red-600")
    }

    if (this.hasProfitRateTarget) {
      this.profitRateTarget.textContent = profitRate + "%"
      this.profitRateTarget.className = "text-xl font-bold " + (grossProfit >= 0 ? "text-green-600" : "text-red-600")
    }

    // 表紙タブの予算情報も更新
    const coverBudgetTotal = document.getElementById("cover-budget-total")
    if (coverBudgetTotal) {
      coverBudgetTotal.textContent = this.formatCurrency(budgetTotal)
    }
    const coverGrossProfit = document.getElementById("cover-gross-profit")
    if (coverGrossProfit) {
      coverGrossProfit.textContent = this.formatCurrency(grossProfit) + "（" + profitRate + "%）"
      coverGrossProfit.className = "font-medium " + (grossProfit >= 0 ? "text-green-600" : "text-red-600")
    }
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
