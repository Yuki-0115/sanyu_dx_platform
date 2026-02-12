import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container", "item"]

  add(event) {
    event.preventDefault()
    const template = this.templateTarget.innerHTML
    const newIndex = new Date().getTime()
    const newRow = template.replace(/NEW_RECORD/g, newIndex)
    this.containerTarget.insertAdjacentHTML("beforeend", newRow)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']")
    if (item) {
      const destroyField = item.querySelector("input[name*='_destroy']")
      if (destroyField) {
        destroyField.value = "1"
        item.style.display = "none"
      } else {
        item.remove()
      }
    }
  }
}
