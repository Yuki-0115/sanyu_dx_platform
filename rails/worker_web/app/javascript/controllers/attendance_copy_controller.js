import { Controller } from "@hotwired/stimulus"

// 出面追加時に、直前の出面から開始時間・終了時間・休憩・移動距離・現場メモを引き継ぐ
export default class extends Controller {
  static values = {
    fields: { type: Array, default: ["start_time", "end_time", "break_minutes", "travel_distance", "site_note"] }
  }

  copyTimes() {
    // nested-form#add が先に実行されてDOMが更新された後に実行
    setTimeout(() => {
      const items = this.getVisibleItems()
      if (items.length < 2) return

      const source = this.findSourceItem(items)
      if (!source) return

      const target = items[items.length - 1]
      for (const fieldName of this.fieldsValue) {
        this.copyField(source, target, fieldName)
      }
    }, 0)
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

  getVisibleItems() {
    return Array.from(
      this.element.querySelectorAll("[data-nested-form-target='item']")
    ).filter(item => {
      if (item.style.display === "none") return false
      return item.offsetParent !== null
    })
  }
}
