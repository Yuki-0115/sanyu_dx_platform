import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tableView", "cardView", "tableBtn", "cardBtn"]

  showTable() {
    this.tableViewTarget.classList.remove("hidden")
    this.cardViewTarget.classList.add("hidden")
    this.tableBtnTarget.classList.replace("bg-gray-100", "bg-blue-100")
    this.tableBtnTarget.classList.replace("text-gray-600", "text-blue-700")
    this.cardBtnTarget.classList.replace("bg-blue-100", "bg-gray-100")
    this.cardBtnTarget.classList.replace("text-blue-700", "text-gray-600")
  }

  showCards() {
    this.tableViewTarget.classList.add("hidden")
    this.cardViewTarget.classList.remove("hidden")
    this.cardBtnTarget.classList.replace("bg-gray-100", "bg-blue-100")
    this.cardBtnTarget.classList.replace("text-gray-600", "text-blue-700")
    this.tableBtnTarget.classList.replace("bg-blue-100", "bg-gray-100")
    this.tableBtnTarget.classList.replace("text-blue-700", "text-gray-600")
  }
}
