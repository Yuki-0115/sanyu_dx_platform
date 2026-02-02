import { Controller } from "@hotwired/stimulus"

// 見積もり内訳明細コントローラー
// 工種・項目の追加削除、金額計算を管理

export default class extends Controller {
  static targets = [
    "categoriesContainer",
    "categoryTemplate",
    "itemTemplate",
    "noMessage",
    // 全体サマリー
    "directCostDisplay",
    "overheadCostDisplay",
    "welfareCostDisplay",
    "adjustmentInput",
    "adjustmentDisplay",
    "subtotalDisplay",
    "taxDisplay",
    "totalDisplay"
  ]

  static values = {
    itemIndex: Number,
    categoryIndex: Number,
    overheadRate: { type: Number, default: 4.0 },
    welfareRate: { type: Number, default: 3.0 }
  }

  connect() {
    this.calculateAllTotals()
  }

  // 工種追加
  addCategory(event) {
    event.preventDefault()

    if (this.hasNoMessageTarget) {
      this.noMessageTarget.remove()
    }

    const template = this.categoryTemplateTarget.innerHTML
    const html = template.replace(/NEW_CAT_INDEX/g, this.categoryIndexValue)

    this.categoriesContainerTarget.insertAdjacentHTML("beforeend", html)
    this.categoryIndexValue++

    this.updateCategoryNumbers()
    this.calculateAllTotals()
  }

  // 工種削除
  removeCategory(event) {
    event.preventDefault()
    const section = event.currentTarget.closest(".category-section")
    const idInput = section.querySelector("input[name*='[id]']")

    if (idInput && idInput.value) {
      // 既存データの場合は_destroyフラグを設定
      const destroyInput = document.createElement("input")
      destroyInput.type = "hidden"
      destroyInput.name = idInput.name.replace("[id]", "[_destroy]")
      destroyInput.value = "1"
      section.appendChild(destroyInput)
      section.style.display = "none"
    } else {
      section.remove()
    }

    this.updateCategoryNumbers()
    this.calculateAllTotals()
  }

  // 項目追加
  addItem(event) {
    event.preventDefault()
    const section = event.currentTarget.closest(".category-section")
    const tbody = section.querySelector(".category-items-body")
    const catIdInput = section.querySelector("input[name*='[id]']")
    const catId = catIdInput ? catIdInput.value : ""

    const template = this.itemTemplateTarget.innerHTML
    let html = template.replace(/NEW_INDEX/g, this.itemIndexValue)
    html = html.replace(/CAT_ID/g, catId)

    tbody.insertAdjacentHTML("beforeend", html)
    this.itemIndexValue++
  }

  // 項目削除
  removeItem(event) {
    event.preventDefault()
    const row = event.currentTarget.closest("tr")
    const idInput = row.querySelector("input[name*='[id]']")

    if (idInput && idInput.value) {
      const destroyInput = document.createElement("input")
      destroyInput.type = "hidden"
      destroyInput.name = idInput.name.replace("[id]", "[_destroy]")
      destroyInput.value = "1"
      row.appendChild(destroyInput)
      row.style.display = "none"
    } else {
      row.remove()
    }

    this.calculateAllTotals()
  }

  // 数量・単価変更時の計算
  calculateRow(event) {
    const row = event.currentTarget.closest("tr")
    this.updateRowAmount(row)
    this.calculateAllTotals()
  }

  // 諸経費・法定福利費率変更時の計算
  calculateRates() {
    this.calculateAllTotals()
  }

  // 工種名変更時
  updateCategoryName() {
    this.updateCoverCategoryList()
  }

  // 端数調整変更時
  adjustmentChanged() {
    this.calculateAllTotals()
  }

  // 行の金額を更新
  updateRowAmount(row) {
    const qtyInput = row.querySelector(".estimate-qty")
    const priceInput = row.querySelector(".estimate-price")
    const amountCell = row.querySelector(".estimate-amount")

    if (!qtyInput || !priceInput || !amountCell) return

    const qty = parseFloat(qtyInput.value) || 0
    const price = parseFloat(priceInput.value) || 0
    const amount = Math.round(qty * price)

    amountCell.textContent = amount > 0 ? this.formatCurrency(amount) : "-"
  }

  // カテゴリ番号を更新
  updateCategoryNumbers() {
    let visibleIndex = 0
    this.element.querySelectorAll(".category-section").forEach((section) => {
      if (section.style.display !== "none") {
        visibleIndex++
        const numEl = section.querySelector(".category-number")
        if (numEl) numEl.textContent = visibleIndex
      }
    })
  }

  // 全体の金額を計算
  calculateAllTotals() {
    let totalDirectCost = 0
    let totalOverheadCost = 0
    let totalWelfareCost = 0

    // 各カテゴリの計算
    this.element.querySelectorAll(".category-section").forEach(section => {
      if (section.style.display === "none") return

      let categoryDirectCost = 0
      section.querySelectorAll(".item-row").forEach(row => {
        if (row.style.display !== "none") {
          const qty = parseFloat(row.querySelector(".estimate-qty")?.value) || 0
          const price = parseFloat(row.querySelector(".estimate-price")?.value) || 0
          categoryDirectCost += Math.round(qty * price)
        }
      })

      const overheadRate = parseFloat(section.querySelector(".category-overhead-rate")?.value) || 0
      const welfareRate = parseFloat(section.querySelector(".category-welfare-rate")?.value) || 0

      const categoryOverheadCost = Math.round(categoryDirectCost * overheadRate / 100)
      const categoryWelfareCost = Math.round(categoryDirectCost * welfareRate / 100)
      const categorySubtotal = categoryDirectCost + categoryOverheadCost + categoryWelfareCost

      // カテゴリ内表示更新
      const directCostEl = section.querySelector(".category-direct-cost")
      const overheadCostEl = section.querySelector(".category-overhead-cost")
      const welfareCostEl = section.querySelector(".category-welfare-cost")
      const subtotalEl = section.querySelector(".category-subtotal")

      if (directCostEl) directCostEl.textContent = this.formatCurrency(categoryDirectCost)
      if (overheadCostEl) overheadCostEl.textContent = this.formatCurrency(categoryOverheadCost)
      if (welfareCostEl) welfareCostEl.textContent = this.formatCurrency(categoryWelfareCost)
      if (subtotalEl) subtotalEl.textContent = this.formatCurrency(categorySubtotal)

      totalDirectCost += categoryDirectCost
      totalOverheadCost += categoryOverheadCost
      totalWelfareCost += categoryWelfareCost
    })

    const adjustmentVal = this.hasAdjustmentInputTarget ? parseInt(this.adjustmentInputTarget.value) || 0 : 0
    const subtotal = totalDirectCost + totalOverheadCost + totalWelfareCost + adjustmentVal
    const taxAmount = Math.round(subtotal * 0.1)
    const totalAmount = subtotal + taxAmount

    // 全体表示更新
    if (this.hasDirectCostDisplayTarget) this.directCostDisplayTarget.textContent = this.formatCurrency(totalDirectCost)
    if (this.hasOverheadCostDisplayTarget) this.overheadCostDisplayTarget.textContent = this.formatCurrency(totalOverheadCost)
    if (this.hasWelfareCostDisplayTarget) this.welfareCostDisplayTarget.textContent = this.formatCurrency(totalWelfareCost)
    if (this.hasAdjustmentDisplayTarget) this.adjustmentDisplayTarget.textContent = this.formatCurrency(adjustmentVal)
    if (this.hasSubtotalDisplayTarget) this.subtotalDisplayTarget.textContent = this.formatCurrency(subtotal)
    if (this.hasTaxDisplayTarget) this.taxDisplayTarget.textContent = this.formatCurrency(taxAmount)
    if (this.hasTotalDisplayTarget) this.totalDisplayTarget.textContent = this.formatCurrency(totalAmount)

    // 表紙タブの金額を更新
    this.updateCoverTab(totalDirectCost, totalOverheadCost, totalWelfareCost, adjustmentVal, subtotal, taxAmount, totalAmount)

    // カスタムイベントを発火（予算タブと連携）
    this.dispatch("calculated", {
      detail: { directCost: totalDirectCost, subtotal, totalAmount }
    })
  }

  // 表紙タブの金額を更新
  updateCoverTab(directCost, overheadCost, welfareCost, adjustment, subtotal, taxAmount, totalAmount) {
    const coverDirectCost = document.getElementById("cover-direct-cost")
    const coverOverheadCost = document.getElementById("cover-overhead-cost")
    const coverWelfareCost = document.getElementById("cover-welfare-cost")
    const coverAdjustment = document.getElementById("cover-adjustment")
    const coverSubtotal = document.getElementById("cover-subtotal")
    const coverTax = document.getElementById("cover-tax")
    const coverTotal = document.getElementById("cover-total")

    if (coverDirectCost) coverDirectCost.textContent = this.formatCurrency(directCost)
    if (coverOverheadCost) coverOverheadCost.textContent = this.formatCurrency(overheadCost)
    if (coverWelfareCost) coverWelfareCost.textContent = this.formatCurrency(welfareCost)
    if (coverAdjustment) coverAdjustment.textContent = this.formatCurrency(adjustment)
    if (coverSubtotal) coverSubtotal.textContent = this.formatCurrency(subtotal)
    if (coverTax) coverTax.textContent = this.formatCurrency(taxAmount)
    if (coverTotal) coverTotal.textContent = this.formatCurrency(totalAmount)

    this.updateCoverCategoryList()
  }

  // 表紙タブの工種一覧を更新
  updateCoverCategoryList() {
    const coverCategoriesBody = document.getElementById("cover-categories-body")
    if (!coverCategoriesBody) return

    const sections = this.element.querySelectorAll(".category-section")
    let visibleSections = []

    sections.forEach(section => {
      if (section.style.display !== "none") {
        visibleSections.push(section)
      }
    })

    if (visibleSections.length === 0) {
      coverCategoriesBody.innerHTML = '<tr id="cover-no-categories-row"><td class="py-2 text-gray-500" colspan="2">※ 内訳明細タブで工種を追加</td></tr>'
      return
    }

    let html = ""
    visibleSections.forEach((section, idx) => {
      const categoryName = section.querySelector(".category-name-input")?.value || ""
      const categorySubtotal = section.querySelector(".category-subtotal")?.textContent || "¥0"

      if (categoryName) {
        html += '<tr class="cover-category-row">'
        html += '<td class="py-2 text-gray-600">' + (idx + 1) + "、" + categoryName + "一式</td>"
        html += '<td class="py-2 text-right font-medium">' + categorySubtotal + "</td>"
        html += "</tr>"
      }
    })

    if (html) {
      coverCategoriesBody.innerHTML = html
    } else {
      coverCategoriesBody.innerHTML = '<tr id="cover-no-categories-row"><td class="py-2 text-gray-500" colspan="2">※ 工種名を入力してください</td></tr>'
    }
  }

  // 予算タブへ切り替え（タブコントローラーと連携）
  goToBudget(event) {
    event.preventDefault()
    // tabs:switchTo イベントを発火
    const tabsController = this.element.closest("[data-controller*='tabs']")
    if (tabsController) {
      const budgetTab = tabsController.querySelector("[data-tab-name='budget']")
      if (budgetTab) budgetTab.click()
    }
  }

  formatCurrency(amount) {
    return "¥" + Math.round(amount).toLocaleString()
  }
}
