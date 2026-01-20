import { Controller } from "@hotwired/stimulus"
import { formatCurrency } from "utils/currency"

export default class extends Controller {
  static targets = ["unitPrice", "total"]
  static values = { quantity: Number }

  connect() {
    this.calculate()
  }

  calculate() {
    const unitPrice = parseFloat(this.unitPriceTarget.value) || 0
    const quantity = this.quantityValue || 0
    const total = Math.round(unitPrice * quantity)

    this.totalTarget.textContent = formatCurrency(total)
  }
}
