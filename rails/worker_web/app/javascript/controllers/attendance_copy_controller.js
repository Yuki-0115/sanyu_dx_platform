import { Controller } from "@hotwired/stimulus"

// 出面追加時に、直前の出面から開始時間・終了時間・休憩・移動距離・現場メモを引き継ぐ
export default class extends Controller {
  static targets = ["container"]
  static copyFields = ["start_time", "end_time", "break_minutes", "travel_distance", "site_note"]

  copyTimes() {
    // nested-form#add が先に実行されてから呼ばれる前提
    requestAnimationFrame(() => {
      const items = this.containerTarget.querySelectorAll("[data-nested-form-target='item']")
      const visible = Array.from(items).filter(item => item.style.display !== "none")

      if (visible.length < 2) return

      const source = this.findSourceItem(visible)
      if (!source) return

      const target = visible[visible.length - 1]
      for (const fieldName of this.constructor.copyFields) {
        this.copyField(source, target, fieldName)
      }
    })
  }

  // 値が入っている最後の出面を探す（新規追加の直前のもの）
  findSourceItem(items) {
    for (let i = items.length - 2; i >= 0; i--) {
      const startTime = items[i].querySelector("input[name*='[start_time]']")
      if (startTime && startTime.value) return items[i]
    }
    return null
  }

  copyField(source, target, fieldName) {
    const sourceInput = source.querySelector(`[name*='[${fieldName}]']`)
    const targetInput = target.querySelector(`[name*='[${fieldName}]']`)
    if (sourceInput && targetInput && sourceInput.value) {
      targetInput.value = sourceInput.value
    }
  }
}
