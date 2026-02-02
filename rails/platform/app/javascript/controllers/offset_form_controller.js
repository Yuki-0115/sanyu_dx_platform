import { Controller } from "@hotwired/stimulus"
import { formatCurrency } from "utils/currency"

export default class extends Controller {
  static targets = ["salary", "insurance", "revenue", "offsetAmount", "revenueDisplay", "balance"]
  static values = {
    totalSalary: Number,
    totalInsurance: Number
  }

  calculate() {
    const salary = parseFloat(this.salaryTarget.value) || 0
    const insurance = parseFloat(this.insuranceTarget.value) || 0
    const revenue = parseFloat(this.revenueTarget.value) || 0

    const offsetAmount = salary + insurance
    const balance = revenue - offsetAmount

    this.offsetAmountTarget.textContent = formatCurrency(offsetAmount)
    this.revenueDisplayTarget.textContent = formatCurrency(revenue)
    this.balanceTarget.textContent = formatCurrency(balance)

    // Update balance color based on positive/negative
    this.balanceTarget.classList.remove("text-green-600", "text-red-600")
    if (balance >= 0) {
      this.balanceTarget.classList.add("text-green-600")
    } else {
      this.balanceTarget.classList.add("text-red-600")
    }
  }

  autoFill() {
    this.salaryTarget.value = this.totalSalaryValue
    this.insuranceTarget.value = this.totalInsuranceValue
    this.calculate()
  }
}
