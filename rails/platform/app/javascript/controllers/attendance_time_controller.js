import { Controller } from "@hotwired/stimulus"

// 出退勤時刻から残業・深夜時間を自動計算するコントローラー
export default class extends Controller {
  static targets = ["startTime", "endTime", "breakMinutes", "overtimeMinutes", "nightMinutes", "workCategory"]

  // 時間帯設定
  static WORK_START_HOUR = 8   // 基本就業開始 08:00
  static WORK_END_HOUR = 17    // 基本就業終了 17:00
  static NIGHT_START_HOUR = 22 // 深夜開始 22:00
  static NIGHT_END_HOUR = 5    // 深夜終了 05:00

  connect() {
    this.calculate()
  }

  calculate() {
    // 出勤以外の場合は計算しない
    if (this.hasWorkCategoryTarget) {
      const category = this.workCategoryTarget.value
      if (category !== "work" && category !== "") {
        this.clearFields()
        return
      }
    }

    const startTime = this.startTimeTarget?.value
    const endTime = this.endTimeTarget?.value
    const breakMinutes = parseInt(this.breakMinutesTarget?.value || "60", 10)

    if (!startTime || !endTime) {
      return
    }

    const breakdown = this.calculateTimeBreakdown(startTime, endTime, breakMinutes)

    if (breakdown) {
      if (this.hasOvertimeMinutesTarget) {
        this.overtimeMinutesTarget.value = breakdown.overtimeMinutes
      }
      if (this.hasNightMinutesTarget) {
        this.nightMinutesTarget.value = breakdown.nightMinutes
      }
    }
  }

  clearFields() {
    if (this.hasOvertimeMinutesTarget) {
      this.overtimeMinutesTarget.value = 0
    }
    if (this.hasNightMinutesTarget) {
      this.nightMinutesTarget.value = 0
    }
  }

  calculateTimeBreakdown(startTimeStr, endTimeStr, breakMins = 60) {
    const [startHour, startMin] = startTimeStr.split(":").map(Number)
    const [endHour, endMin] = endTimeStr.split(":").map(Number)

    let startMins = startHour * 60 + startMin
    let endMins = endHour * 60 + endMin

    // 翌日にまたがる場合
    if (endMins < startMins) {
      endMins += 24 * 60
    }

    const totalMins = endMins - startMins - breakMins
    if (totalMins <= 0) {
      return null
    }

    let regular = 0
    let overtime = 0
    let night = 0

    const WORK_START = 8
    const WORK_END = 17
    const NIGHT_START = 22
    const NIGHT_END = 5

    for (let current = startMins; current < endMins; current++) {
      const hourOfDay = Math.floor(current / 60) % 24

      // 深夜時間帯 (22:00-05:00)
      if (hourOfDay >= NIGHT_START || hourOfDay < NIGHT_END) {
        night++
      }
      // 残業時間帯 (17:00-22:00 or 05:00-08:00)
      else if (hourOfDay >= WORK_END || hourOfDay < WORK_START) {
        overtime++
      }
      // 基本就業時間帯 (08:00-17:00)
      else {
        regular++
      }
    }

    // 休憩時間を基本時間から引く
    regular = Math.max(regular - breakMins, 0)

    return {
      regularMinutes: regular,
      overtimeMinutes: overtime,
      nightMinutes: night,
      totalMinutes: regular + overtime + night
    }
  }
}
