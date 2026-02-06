import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "reason", "vendorName"]

  showRejectModal(event) {
    const invoiceId = event.currentTarget.dataset.invoiceId
    const vendorName = event.currentTarget.dataset.vendorName

    // フォームのアクションURLを設定
    this.formTarget.action = `/accounting/received_invoices/${invoiceId}/reject`

    // 情報を表示
    this.vendorNameTarget.textContent = vendorName

    // 理由をクリア
    this.reasonTarget.value = ""

    // モーダルを表示
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  hideModal() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
