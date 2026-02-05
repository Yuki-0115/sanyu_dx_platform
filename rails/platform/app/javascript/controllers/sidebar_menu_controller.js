import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "arrow"]

  connect() {
    // 現在のページに該当するセクションを自動展開
    this.expandCurrentSection()
  }

  toggle(event) {
    const button = event.currentTarget
    const sectionId = button.dataset.section
    const section = this.sectionTargets.find(s => s.dataset.sectionId === sectionId)
    const arrow = button.querySelector('[data-sidebar-menu-target="arrow"]')

    if (section) {
      const isHidden = section.classList.contains("hidden")

      if (isHidden) {
        section.classList.remove("hidden")
        arrow?.classList.add("rotate-90")
      } else {
        section.classList.add("hidden")
        arrow?.classList.remove("rotate-90")
      }
    }
  }

  expandCurrentSection() {
    // 現在アクティブなリンクを含むセクションを展開
    this.sectionTargets.forEach(section => {
      const hasActiveLink = section.querySelector('.bg-gray-800')
      if (hasActiveLink) {
        section.classList.remove("hidden")
        const sectionId = section.dataset.sectionId
        const button = this.element.querySelector(`[data-section="${sectionId}"]`)
        const arrow = button?.querySelector('[data-sidebar-menu-target="arrow"]')
        arrow?.classList.add("rotate-90")
      }
    })
  }
}
