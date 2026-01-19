import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["weekTab", "monthTab", "weekView", "monthView", "weekNav", "monthNav"]

  connect() {
    // URLパラメータからビューを判定
    const urlParams = new URLSearchParams(window.location.search)
    const view = urlParams.get("view") || "week"

    if (view === "month") {
      this.showMonthly(false)
    } else {
      this.showWeekly(false)
    }
  }

  showWeekly(updateUrl = true) {
    // タブスタイル
    this.weekTabTarget.classList.add("bg-blue-600", "text-white")
    this.weekTabTarget.classList.remove("text-gray-600", "hover:text-gray-900")
    this.monthTabTarget.classList.remove("bg-blue-600", "text-white")
    this.monthTabTarget.classList.add("text-gray-600", "hover:text-gray-900")

    // ビュー表示切替
    this.weekViewTarget.classList.remove("hidden")
    this.monthViewTarget.classList.add("hidden")

    // ナビゲーション切替
    this.weekNavTarget.classList.remove("hidden")
    this.monthNavTarget.classList.add("hidden")

    // URL更新
    if (updateUrl) {
      this.updateUrlParam("view", "week")
    }
  }

  showMonthly(updateUrl = true) {
    // タブスタイル
    this.monthTabTarget.classList.add("bg-blue-600", "text-white")
    this.monthTabTarget.classList.remove("text-gray-600", "hover:text-gray-900")
    this.weekTabTarget.classList.remove("bg-blue-600", "text-white")
    this.weekTabTarget.classList.add("text-gray-600", "hover:text-gray-900")

    // ビュー表示切替
    this.monthViewTarget.classList.remove("hidden")
    this.weekViewTarget.classList.add("hidden")

    // ナビゲーション切替
    this.monthNavTarget.classList.remove("hidden")
    this.weekNavTarget.classList.add("hidden")

    // URL更新
    if (updateUrl) {
      this.updateUrlParam("view", "month")
    }
  }

  updateUrlParam(key, value) {
    const url = new URL(window.location.href)
    url.searchParams.set(key, value)
    // 他のパラメータ（weekやmonth）は削除してリセット
    url.searchParams.delete("week")
    url.searchParams.delete("month")
    window.history.pushState({}, "", url.toString())
  }
}
