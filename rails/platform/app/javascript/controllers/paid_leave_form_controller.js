import { Controller } from "@hotwired/stimulus"

// 有給申請フォーム：消化日数の動的更新
export default class extends Controller {
  static targets = ["consumedDays", "remainingAfter"]
  static values = {
    remaining: { type: Number, default: 0 }
  }

  connect() {
    // 初期値を取得
    const remainingText = this.remainingAfterTarget.textContent
    this.remainingValue = parseFloat(remainingText) + 1.0 // 初期表示は1日引かれた状態なので戻す
  }

  updateDays(event) {
    const leaveType = event.target.value
    const consumedDays = leaveType === "full" ? 1.0 : 0.5

    this.consumedDaysTarget.textContent = `${consumedDays}日`

    const remaining = this.remainingValue - consumedDays
    this.remainingAfterTarget.textContent = `${remaining}日`
  }
}
