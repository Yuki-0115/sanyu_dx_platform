import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async toggleDate(event) {
    const button = event.currentTarget
    const date = button.dataset.date
    const calendarType = button.dataset.calendarType
    const isHoliday = button.dataset.isHoliday === "true"

    // ボタンを一時的に無効化
    button.disabled = true

    try {
      const response = await fetch("/master/company_holidays/toggle", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          date: date,
          calendar_type: calendarType,
          name: ""
        })
      })

      const data = await response.json()

      if (data.success) {
        // ページをリロードして反映
        window.location.reload()
      } else {
        alert("エラー: " + (data.errors?.join(", ") || "更新に失敗しました"))
        button.disabled = false
      }
    } catch (error) {
      alert("通信エラーが発生しました")
      button.disabled = false
    }
  }
}
