import { Controller } from "@hotwired/stimulus"

// 外注セクション：常用/請負の切替 + 自動計算 → 原価情報の外注費に反映
// 外注費 = 常用（単価×人工）+ 請負（出来高合計）
export default class extends Controller {
  static targets = ["container"]
  static values = {
    unitPrice: { type: Number, default: 18000 },   // 常用単価（予算から）
    unitPrices: { type: Object, default: {} }       // Worker Web用：project_id → 単価マッピング
  }

  connect() {
    this.initializeEntries()
    this.calculateTotal()

    // Worker Web: 案件変更時に常用単価を切替
    this.projectSelect = document.querySelector("[data-outsourcing-project-select]")
    if (this.projectSelect) {
      this.onProjectChange = this.onProjectChange.bind(this)
      this.projectSelect.addEventListener("change", this.onProjectChange)
    }
  }

  disconnect() {
    if (this.projectSelect) {
      this.projectSelect.removeEventListener("change", this.onProjectChange)
    }
  }

  // 案件変更時：常用単価を更新して再計算
  onProjectChange(event) {
    const projectId = event.target.value
    if (projectId && this.unitPricesValue[projectId]) {
      this.unitPriceValue = parseInt(this.unitPricesValue[projectId]) || 18000
    } else {
      this.unitPriceValue = 18000
    }
    this.calculateTotal()
  }

  // 区分変更時：フィールド表示切替 + 合計再計算
  toggleType(event) {
    const entry = event.target.closest("[data-nested-form-target='item']")
    this.updateEntryFields(entry)
    this.calculateTotal()
  }

  // 常用：人数or出勤区分変更時 → 合計再計算
  calculateManDays() {
    this.calculateTotal()
  }

  // 請負：数量or単価変更時 → 出来高金額を計算 + 合計再計算
  calculateAmount(event) {
    const entry = event.target.closest("[data-nested-form-target='item']")
    this.updateContractAmount(entry)
    this.calculateTotal()
  }

  // 常用（単価×人工）+ 請負（出来高合計）= 外注費
  calculateTotal() {
    let manDaysTotal = 0
    let contractTotal = 0

    this.containerTarget.querySelectorAll("[data-nested-form-target='item']").forEach(entry => {
      if (entry.style.display === "none") return
      const destroyField = entry.querySelector("input[name*='[_destroy]']")
      if (destroyField && destroyField.value === "1") return

      const billingType = entry.querySelector("select[name*='[billing_type]']")
      if (!billingType) return

      if (billingType.value === "man_days") {
        // 常用：単価 × 人数 × 出勤係数（1日=1.0, 半日=0.5）
        const headcount = parseInt(entry.querySelector("input[name*='[headcount]']")?.value) || 0
        const attendanceType = entry.querySelector("select[name*='[attendance_type]']")?.value
        const factor = attendanceType === "half" ? 0.5 : 1.0
        manDaysTotal += this.unitPriceValue * headcount * factor
      } else if (billingType.value === "contract") {
        // 請負：出来高金額の合計
        const amount = entry.querySelector("input[name*='[contract_amount]']")
        contractTotal += parseFloat(amount?.value) || 0
      }
    })

    const total = Math.round(manDaysTotal + contractTotal)
    const field = document.querySelector("[data-outsourcing-cost-field]")
    if (field) {
      field.value = total > 0 ? total : ""
    }
  }

  // 行追加時（DOM反映待ちのためrAF使用）
  entryAdded() {
    requestAnimationFrame(() => {
      this.initializeEntries()
      this.calculateTotal()
    })
  }

  // 行削除時（DOM反映待ちのためrAF使用）
  entryRemoved() {
    requestAnimationFrame(() => this.calculateTotal())
  }

  // 全エントリのフィールド表示を初期化
  initializeEntries() {
    this.containerTarget.querySelectorAll("[data-nested-form-target='item']").forEach(entry => {
      this.updateEntryFields(entry)
    })
  }

  updateEntryFields(entry) {
    const billingType = entry.querySelector("select[name*='[billing_type]']")
    if (!billingType) return
    const isContract = billingType.value === "contract"
    entry.querySelectorAll("[data-man-days-fields]").forEach(el => el.classList.toggle("hidden", isContract))
    entry.querySelectorAll("[data-contract-fields]").forEach(el => el.classList.toggle("hidden", !isContract))
  }

  // 数量×単価＝出来高金額
  updateContractAmount(entry) {
    const quantity = parseFloat(entry.querySelector("input[name*='[quantity]']")?.value) || 0
    const unitPrice = parseFloat(entry.querySelector("input[name*='[unit_price]']")?.value) || 0
    const amountField = entry.querySelector("input[name*='[contract_amount]']")
    if (amountField) {
      const amount = Math.round(quantity * unitPrice)
      amountField.value = amount > 0 ? amount : ""
    }
  }
}
