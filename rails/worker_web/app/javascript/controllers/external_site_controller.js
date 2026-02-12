import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["externalFields", "projectField"]

  toggle(event) {
    const isExternal = event.target.checked
    this.externalFieldsTarget.classList.toggle("hidden", !isExternal)
    this.projectFieldTarget.classList.toggle("hidden", isExternal)
  }
}
