import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["consumedDisplay", "remainingDisplay"]
  static values = { remaining: Number }

  updateConsumed() {
    const selected = this.element.querySelector("input[name='paid_leave_request[leave_type]']:checked")
    if (!selected) return

    const consumed = selected.value === "full" ? 1.0 : 0.5
    const afterRemaining = this.remainingValue - consumed

    this.consumedDisplayTarget.textContent = consumed.toFixed(1)
    this.remainingDisplayTarget.textContent = afterRemaining.toFixed(1)

    if (afterRemaining < 0) {
      this.remainingDisplayTarget.classList.add("text-red-600")
      this.remainingDisplayTarget.classList.remove("text-blue-600")
    } else {
      this.remainingDisplayTarget.classList.remove("text-red-600")
      this.remainingDisplayTarget.classList.add("text-blue-600")
    }
  }
}
