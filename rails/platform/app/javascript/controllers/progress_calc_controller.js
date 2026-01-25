import { Controller } from "@hotwired/stimulus"

// 出来高入力時の進捗率・未請求額を自動計算
export default class extends Controller {
  static targets = ["input", "rate", "unbilled"]
  static values = { order: Number }

  calculate() {
    const amount = this.parseNumber(this.inputTarget.value)
    const orderAmount = this.orderValue

    // 進捗率計算
    if (orderAmount > 0) {
      const rate = ((amount / orderAmount) * 100).toFixed(1)
      this.rateTarget.textContent = `${rate}%`
    } else {
      this.rateTarget.textContent = "0%"
    }

    // 未請求額計算
    const invoiced = parseInt(this.unbilledTarget.dataset.invoiced) || 0
    const unbilled = Math.max(amount - invoiced, 0)
    this.unbilledTarget.textContent = this.formatNumber(unbilled)

    // 未請求がある場合はオレンジ色に
    if (unbilled > 0) {
      this.unbilledTarget.classList.remove("text-gray-500")
      this.unbilledTarget.classList.add("text-orange-600")
    } else {
      this.unbilledTarget.classList.remove("text-orange-600")
      this.unbilledTarget.classList.add("text-gray-500")
    }
  }

  parseNumber(value) {
    if (!value) return 0
    // 全角数字を半角に、カンマを除去
    const normalized = value
      .replace(/[０-９]/g, s => String.fromCharCode(s.charCodeAt(0) - 0xFEE0))
      .replace(/,/g, "")
    return parseInt(normalized) || 0
  }

  formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }
}
