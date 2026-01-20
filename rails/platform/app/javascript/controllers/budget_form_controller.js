import { Controller } from "@hotwired/stimulus"
import { formatCurrency } from "utils/currency"

export default class extends Controller {
  static targets = [
    "material", "outsourcing", "labor", "expense", "targetRate",
    "totalCost", "orderAmount", "grossProfit", "profitRate",
    "orderAmountValue"
  ]

  calculate() {
    const material = parseFloat(this.materialTarget.value) || 0
    const outsourcing = parseFloat(this.outsourcingTarget.value) || 0
    const labor = parseFloat(this.laborTarget.value) || 0
    const expense = parseFloat(this.expenseTarget.value) || 0

    const totalCost = material + outsourcing + labor + expense
    const orderAmount = parseFloat(this.orderAmountValueTarget.value) || 0
    const targetRate = parseFloat(this.orderAmountValueTarget.dataset.targetRate) || 0

    const grossProfit = orderAmount - totalCost
    const profitRate = orderAmount > 0 ? (grossProfit / orderAmount * 100) : 0

    // Update displays
    this.totalCostTarget.textContent = formatCurrency(totalCost)
    this.grossProfitTarget.textContent = formatCurrency(grossProfit)
    this.profitRateTarget.textContent = profitRate.toFixed(1) + "%"

    // Update colors based on positive/negative
    this.grossProfitTarget.classList.remove("text-green-600", "text-red-600")
    if (grossProfit >= 0) {
      this.grossProfitTarget.classList.add("text-green-600")
    } else {
      this.grossProfitTarget.classList.add("text-red-600")
    }

    // Update profit rate color based on target
    this.profitRateTarget.classList.remove("text-green-600", "text-red-600")
    if (profitRate >= targetRate) {
      this.profitRateTarget.classList.add("text-green-600")
    } else {
      this.profitRateTarget.classList.add("text-red-600")
    }
  }
}
