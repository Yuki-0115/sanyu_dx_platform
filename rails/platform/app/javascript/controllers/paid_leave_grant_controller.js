import { Controller } from "@hotwired/stimulus"

// 手動付与フォーム：失効日の自動計算
export default class extends Controller {
  static targets = ["grantDate", "expiryDate", "days", "remaining"]

  connect() {
    // 初期値を設定
    this.updateExpiry()
  }

  // 付与日変更時に失効日を自動更新（付与日+2年）
  updateExpiry() {
    if (!this.hasGrantDateTarget || !this.hasExpiryDateTarget) return

    const grantDate = new Date(this.grantDateTarget.value)
    if (isNaN(grantDate.getTime())) return

    // 2年後を計算
    const expiryDate = new Date(grantDate)
    expiryDate.setFullYear(expiryDate.getFullYear() + 2)

    // YYYY-MM-DD形式にフォーマット
    const formatted = expiryDate.toISOString().split('T')[0]
    this.expiryDateTarget.value = formatted
  }

  // 付与日数変更時に残日数を同期（未入力の場合のみ）
  updateRemaining() {
    if (!this.hasDaysTarget || !this.hasRemainingTarget) return

    // 残日数が空の場合のみ同期
    if (this.remainingTarget.value === "") {
      this.remainingTarget.placeholder = this.daysTarget.value || "付与日数と同じ"
    }
  }
}
