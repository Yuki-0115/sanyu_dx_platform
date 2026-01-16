import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subtotalSum", "taxAmount", "totalAmount", "amountInput", "taxInput", "totalInput"]

  connect() {
    this.calculateTotals()
  }

  calculateSubtotal(event) {
    const row = event.target.closest(".item-row")
    if (!row) return

    const quantityInput = row.querySelector(".quantity-input")
    const unitPriceInput = row.querySelector(".unit-price-input")
    const subtotalDisplay = row.querySelector(".subtotal-display")
    const subtotalInput = row.querySelector(".subtotal-input")

    if (quantityInput && unitPriceInput && subtotalDisplay && subtotalInput) {
      const quantity = parseFloat(quantityInput.value) || 0
      const unitPrice = parseFloat(unitPriceInput.value) || 0
      const subtotal = Math.round(quantity * unitPrice)

      subtotalDisplay.textContent = this.formatCurrency(subtotal)
      subtotalInput.value = subtotal
    }

    this.calculateTotals()
  }

  calculateTotals() {
    const rows = this.element.querySelectorAll(".item-row")
    let total = 0

    rows.forEach(row => {
      // Skip rows marked for destruction
      const destroyInput = row.querySelector("input[name*='_destroy']")
      if (destroyInput && destroyInput.value === "1") return

      const subtotalInput = row.querySelector(".subtotal-input")
      if (subtotalInput) {
        total += parseFloat(subtotalInput.value) || 0
      }
    })

    const tax = Math.round(total * 0.1)
    const grandTotal = total + tax

    if (this.hasSubtotalSumTarget) {
      this.subtotalSumTarget.textContent = this.formatCurrency(total)
    }
    if (this.hasTaxAmountTarget) {
      this.taxAmountTarget.textContent = this.formatCurrency(tax)
    }
    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.textContent = this.formatCurrency(grandTotal)
    }
    if (this.hasAmountInputTarget) {
      this.amountInputTarget.value = total
    }
    if (this.hasTaxInputTarget) {
      this.taxInputTarget.value = tax
    }
    if (this.hasTotalInputTarget) {
      this.totalInputTarget.value = grandTotal
    }
  }

  formatCurrency(amount) {
    return "¥" + amount.toLocaleString("ja-JP")
  }
}
