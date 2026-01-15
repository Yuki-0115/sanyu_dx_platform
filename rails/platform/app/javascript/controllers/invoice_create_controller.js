import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["projectSelect"]

  goToNew() {
    const projectId = this.projectSelectTarget.value
    if (projectId) {
      window.location.href = `/projects/${projectId}/invoices/new`
    } else {
      alert("案件を選択してください")
    }
  }
}
