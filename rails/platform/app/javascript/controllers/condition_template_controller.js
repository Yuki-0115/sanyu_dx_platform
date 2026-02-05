import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "templateName", "saveResult", "tabInput", "tabUse", "tabSave"]
  static values = { templates: Object }

  // タブ切り替え
  switchTab(event) {
    const tab = event.currentTarget.dataset.tab

    // タブボタンのスタイル切り替え
    this.element.querySelectorAll('.condition-tab-btn').forEach(btn => {
      btn.classList.remove('border-blue-500', 'text-blue-600')
      btn.classList.add('border-transparent', 'text-gray-500')
    })
    event.currentTarget.classList.remove('border-transparent', 'text-gray-500')
    event.currentTarget.classList.add('border-blue-500', 'text-blue-600')

    // タブコンテンツの切り替え
    if (this.hasTabInputTarget) this.tabInputTarget.classList.toggle('hidden', tab !== 'input')
    if (this.hasTabUseTarget) this.tabUseTarget.classList.toggle('hidden', tab !== 'use')
    if (this.hasTabSaveTarget) this.tabSaveTarget.classList.toggle('hidden', tab !== 'save')
  }

  // 新規作成フォームを表示（保存タブへ切り替え）
  showCreateForm() {
    const saveTabBtn = this.element.querySelector('.condition-tab-btn[data-tab="save"]')
    if (saveTabBtn) {
      saveTabBtn.click()
    }
  }

  // テンプレート挿入
  insertTemplate(event) {
    const name = event.currentTarget.dataset.templateName
    const content = event.currentTarget.dataset.templateContent

    if (content && this.hasTextareaTarget) {
      this.textareaTarget.value = content
      // 入力タブに切り替え
      this.element.querySelector('.condition-tab-btn[data-tab="input"]').click()
    }
  }

  // テンプレート保存
  async saveAsTemplate(event) {
    event.preventDefault()

    const name = this.templateNameTarget.value.trim()
    if (!name) {
      alert("テンプレート名を入力してください")
      return
    }

    const content = this.textareaTarget.value
    if (!content) {
      alert("条件内容を入力してください")
      return
    }

    const isSharedCheckbox = this.element.querySelector('[name="is_shared"]')
    const isShared = isSharedCheckbox?.checked || false

    try {
      const response = await fetch("/estimate_templates/quick_create", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          template_type: "condition",
          name: name,
          content: content,
          is_shared: isShared
        })
      })

      const data = await response.json()

      if (data.success) {
        this.templateNameTarget.value = ""

        if (this.hasSaveResultTarget) {
          this.saveResultTarget.textContent = `「${data.template.name}」を保存しました`
          this.saveResultTarget.classList.remove("hidden")
          setTimeout(() => this.saveResultTarget.classList.add("hidden"), 3000)
        }
      } else {
        alert("保存に失敗しました: " + data.errors.join(", "))
      }
    } catch (error) {
      alert("保存に失敗しました")
      console.error(error)
    }
  }
}
