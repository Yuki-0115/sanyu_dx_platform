import { Controller } from "@hotwired/stimulus"

// 有給申請の承認・却下処理
export default class extends Controller {
  static targets = ["modal", "form", "reason", "modalInfo"]

  showRejectModal(event) {
    const requestId = event.currentTarget.dataset.requestId
    const employeeName = event.currentTarget.dataset.employeeName
    const leaveDate = event.currentTarget.dataset.leaveDate

    // フォームのアクションURLを設定
    const url = `/paid_leave_requests/${requestId}/reject`
    this.formTarget.action = url

    // モーダル情報を更新
    this.modalInfoTarget.textContent = `${employeeName}さんの${leaveDate}の申請を却下します`

    // 理由フィールドをクリア
    this.reasonTarget.value = ""

    // モーダルを表示
    this.modalTarget.classList.remove("hidden")
  }

  hideModal() {
    this.modalTarget.classList.add("hidden")
  }

  // モーダル外をクリックした場合も閉じる
  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.hideModal()
    }
  }
}
