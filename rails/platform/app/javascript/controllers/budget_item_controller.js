import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "chevron", "total", "costTotal", "costsContainer", "emptyState", "templateSelect"]
  static values = { qty: Number, units: Array }

  // 単位の選択肢
  get unitOptions() {
    return this.unitsValue.length > 0 ? this.unitsValue : ["式", "m", "m²", "m³", "t", "kg", "本", "個", "台", "人工", "日", "回", "箇所", "セット"]
  }

  toggle(event) {
    // input要素のクリックは無視
    if (event.target.tagName === "INPUT") return

    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden")
      if (this.hasChevronTarget) {
        this.chevronTarget.classList.toggle("-rotate-90")
      }
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  showCosts(event) {
    event.stopPropagation()
    const itemIndex = event.currentTarget.dataset.itemIndex

    // 空の状態を隠す
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add("hidden")
    }

    // 内訳セクションを表示
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("hidden")
    }

    // 最初の行を追加
    this.addCostRow(itemIndex)
  }

  addCost(event) {
    event.stopPropagation()
    const itemIndex = event.currentTarget.dataset.itemIndex
    this.addCostRow(itemIndex)
  }

  addCostRow(itemIndex, templateData = null) {
    if (!this.hasCostsContainerTarget) return

    const costIndex = this.costsContainerTarget.querySelectorAll(".cost-row").length
    const unitOptions = this.unitOptions.map(u =>
      `<option value="${u}" ${templateData?.unit === u ? 'selected' : ''}>${u}</option>`
    ).join("")

    const template = `
      <tr class="cost-row bg-gray-50 border-t">
        <td class="px-2 py-1">
          <input type="text" name="estimate[estimate_items_attributes][${itemIndex}][estimate_item_costs_attributes][${costIndex}][cost_name]"
                 value="${templateData?.name || ''}"
                 class="block w-full rounded border-gray-300 text-sm"
                 placeholder="材料費、労務費など">
        </td>
        <td class="px-2 py-1">
          <input type="number" name="estimate[estimate_items_attributes][${itemIndex}][estimate_item_costs_attributes][${costIndex}][quantity]"
                 step="0.01"
                 class="block w-full rounded border-gray-300 text-sm text-right cost-qty"
                 data-action="input->budget-item#calculate">
        </td>
        <td class="px-2 py-1">
          <select name="estimate[estimate_items_attributes][${itemIndex}][estimate_item_costs_attributes][${costIndex}][unit]"
                  class="block w-full rounded border-gray-300 text-sm text-center">
            ${unitOptions}
          </select>
        </td>
        <td class="px-2 py-1">
          <input type="number" name="estimate[estimate_items_attributes][${itemIndex}][estimate_item_costs_attributes][${costIndex}][unit_price]"
                 value="${templateData?.unit_price || ''}"
                 step="1"
                 class="block w-full rounded border-gray-300 text-sm text-right cost-price"
                 data-action="input->budget-item#calculate">
        </td>
        <td class="px-2 py-1 text-right text-sm font-medium cost-amount">¥0</td>
        <td class="px-2 py-1">
          <input type="text" name="estimate[estimate_items_attributes][${itemIndex}][estimate_item_costs_attributes][${costIndex}][note]"
                 value="${templateData?.note || ''}"
                 class="block w-full rounded border-gray-300 text-sm"
                 placeholder="備考">
        </td>
        <td class="px-2 py-1 text-center">
          <button type="button" data-action="click->budget-item#removeCost"
                  class="text-red-500 hover:text-red-700">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </td>
      </tr>
    `
    this.costsContainerTarget.insertAdjacentHTML("beforeend", template)
  }

  addFromTemplate(event) {
    event.stopPropagation()
    const select = event.currentTarget
    const itemIndex = select.dataset.itemIndex

    if (!select.value) return

    try {
      const templateData = JSON.parse(select.value)
      this.addCostRow(itemIndex, templateData)
      this.calculate()
      select.value = "" // リセット
    } catch (e) {
      console.error("Template parse error:", e)
    }
  }

  removeCost(event) {
    event.stopPropagation()
    const row = event.currentTarget.closest("tr")
    const destroyInput = row.querySelector(".destroy-flag")

    if (destroyInput) {
      destroyInput.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
    this.calculate()
  }

  calculate() {
    if (!this.hasCostsContainerTarget) return

    let total = 0
    this.costsContainerTarget.querySelectorAll(".cost-row:not(.hidden)").forEach(row => {
      const qty = parseFloat(row.querySelector(".cost-qty")?.value) || 0
      const price = parseFloat(row.querySelector(".cost-price")?.value) || 0
      const amount = Math.round(qty * price)
      total += amount

      const amountCell = row.querySelector(".cost-amount")
      if (amountCell) {
        amountCell.textContent = this.formatCurrency(amount)
      }
    })

    // 内訳合計を更新
    if (this.hasCostTotalTarget) {
      this.costTotalTarget.textContent = this.formatCurrency(total)
    }

    // 項目の予算合計を更新
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = this.formatCurrency(total)
    }

    // 親のカテゴリ合計と全体合計を更新
    this.updateCategoryTotals()
  }

  updateCategoryTotals() {
    // 同じカテゴリ内の全項目の合計を計算
    const categorySection = this.element.closest(".budget-category-section")
    if (!categorySection) return

    let categoryTotal = 0
    categorySection.querySelectorAll(".budget-item-section").forEach(itemSection => {
      const totalEl = itemSection.querySelector("[data-budget-item-target='total']")
      if (totalEl) {
        const value = parseInt(totalEl.textContent.replace(/[¥,]/g, "")) || 0
        categoryTotal += value
      }
    })

    // カテゴリヘッダーの予算表示を更新
    const categoryTotalEl = categorySection.querySelector(".budget-category-total")
    if (categoryTotalEl) {
      categoryTotalEl.innerHTML = "予算: " + this.formatCurrency(categoryTotal)
    }

    // カテゴリ小計を更新
    const categorySubtotalEl = categorySection.querySelector(".budget-category-subtotal")
    if (categorySubtotalEl) {
      categorySubtotalEl.textContent = this.formatCurrency(categoryTotal)
    }

    // 全体の予算合計を更新
    this.updateGrandTotal()
  }

  updateGrandTotal() {
    let grandTotal = 0
    document.querySelectorAll(".budget-category-section").forEach(section => {
      section.querySelectorAll(".budget-item-section").forEach(itemSection => {
        const totalEl = itemSection.querySelector("[data-budget-item-target='total']")
        if (totalEl) {
          const value = parseInt(totalEl.textContent.replace(/[¥,]/g, "")) || 0
          grandTotal += value
        }
      })
    })

    // サマリーの予算合計を更新
    const budgetTotalEl = document.querySelector("[data-estimate-budget-target='budgetTotal']")
    if (budgetTotalEl) {
      budgetTotalEl.textContent = this.formatCurrency(grandTotal)
    }

    // 見積金額を取得
    const directCostEl = document.querySelector("[data-estimate-budget-target='directCost']")
    const directCost = directCostEl ? parseInt(directCostEl.textContent.replace(/[¥,]/g, "")) || 0 : 0

    // 粗利計算
    const grossProfit = directCost - grandTotal
    const profitRate = directCost > 0 ? (grossProfit / directCost * 100).toFixed(1) : 0

    const grossProfitEl = document.querySelector("[data-estimate-budget-target='grossProfit']")
    if (grossProfitEl) {
      grossProfitEl.textContent = this.formatCurrency(grossProfit)
      grossProfitEl.className = "text-xl font-bold " + (grossProfit >= 0 ? "text-green-600" : "text-red-600")
    }

    const profitRateEl = document.querySelector("[data-estimate-budget-target='profitRate']")
    if (profitRateEl) {
      profitRateEl.textContent = profitRate + "%"
      profitRateEl.className = "text-xl font-bold " + (grossProfit >= 0 ? "text-green-600" : "text-red-600")
    }
  }

  formatCurrency(amount) {
    return "¥" + Math.round(amount).toLocaleString()
  }
}
