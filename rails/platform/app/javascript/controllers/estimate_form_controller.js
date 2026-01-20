import { Controller } from "@hotwired/stimulus"
import { formatCurrency } from "utils/currency"

export default class extends Controller {
  static targets = [
    "material", "outsourcing", "labor", "expense", "selling",
    "totalCost", "sellingDisplay", "grossProfit", "profitMargin"
  ]

  calculate() {
    const material = parseFloat(this.materialTarget.value) || 0
    const outsourcing = parseFloat(this.outsourcingTarget.value) || 0
    const labor = parseFloat(this.laborTarget.value) || 0
    const expense = parseFloat(this.expenseTarget.value) || 0
    const selling = parseFloat(this.sellingTarget.value) || 0

    const totalCost = material + outsourcing + labor + expense
    const grossProfit = selling - totalCost
    const profitMargin = selling > 0 ? (grossProfit / selling * 100) : 0

    // Update displays
    this.totalCostTarget.textContent = formatCurrency(totalCost)
    this.sellingDisplayTarget.textContent = formatCurrency(selling)
    this.grossProfitTarget.textContent = formatCurrency(grossProfit)
    this.profitMarginTarget.textContent = profitMargin.toFixed(1) + "%"

    // Update gross profit color
    this.grossProfitTarget.classList.remove("text-green-600", "text-red-600")
    if (grossProfit >= 0) {
      this.grossProfitTarget.classList.add("text-green-600")
    } else {
      this.grossProfitTarget.classList.add("text-red-600")
    }

    // Update profit margin color
    this.profitMarginTarget.classList.remove("text-green-600", "text-red-600")
    if (profitMargin >= 0) {
      this.profitMarginTarget.classList.add("text-green-600")
    } else {
      this.profitMarginTarget.classList.add("text-red-600")
    }
  }
}
