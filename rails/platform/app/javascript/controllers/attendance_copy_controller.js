import { Controller } from "@hotwired/stimulus"

// 出面一括入力で、1行目の時間・距離・メモを他の行に自動反映 + 追加時に引き継ぎ
export default class extends Controller {
  static values = {
    fields: { type: Array, default: ["start_time", "end_time", "break_minutes", "travel_distance", "site_note"] }
  }

  // 1行目の値変更時に2行目以降へ反映
  propagate(event) {
    const changedField = event.target
    const fieldName = this.extractFieldName(changedField.name)
    if (!fieldName || !this.fieldsValue.includes(fieldName)) return

    const items = this.getVisibleItems()
    if (items.length < 2) return

    // 1行目からの変更のみ反映
    if (!items[0].contains(changedField)) return

    const value = changedField.value

    for (let i = 1; i < items.length; i++) {
      const targetField = items[i].querySelector(`[name$="[${fieldName}]"]`)
      if (targetField && targetField.value !== value) {
        targetField.value = value
        targetField.dispatchEvent(new Event("change", { bubbles: true }))
      }
    }
  }

  // 出面追加時に直前の出面から値をコピー
  copyTimes() {
    requestAnimationFrame(() => {
      const items = this.getVisibleItems()
      if (items.length < 2) return

      const source = this.findSourceItem(items)
      if (!source) return

      const target = items[items.length - 1]
      for (const fieldName of this.fieldsValue) {
        this.copyField(source, target, fieldName)
      }
    })
  }

  findSourceItem(items) {
    // 値が入っている最後の出面を探す（新規追加の直前のもの）
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

  extractFieldName(name) {
    if (!name) return null
    const match = name.match(/\[(\w+)\]$/)
    return match ? match[1] : null
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
