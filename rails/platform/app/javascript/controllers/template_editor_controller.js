import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conditionItems", "confirmationCategories", "hiddenContent"]
  static values = { type: String }

  connect() {
    // 既存データをパース
    if (this.hasHiddenContentTarget && this.hiddenContentTarget.value) {
      this.parseExistingContent()
    }
  }

  parseExistingContent() {
    const content = this.hiddenContentTarget.value

    if (this.typeValue === "condition") {
      // 条件書: 改行区切りのテキスト
      const items = content.split("\n").filter(line => line.trim())
      this.conditionItemsTarget.innerHTML = ""
      items.forEach(item => this.addConditionItemElement(item))
    } else {
      // 確認書: JSON形式
      try {
        const data = JSON.parse(content)
        this.confirmationCategoriesTarget.innerHTML = ""
        Object.entries(data).forEach(([category, items]) => {
          this.addCategoryElement(category, items)
        })
      } catch (e) {
        console.error("JSON parse error:", e)
      }
    }
  }

  // === 条件書 ===
  addConditionItem() {
    this.addConditionItemElement("")
    this.updateHiddenContent()
  }

  addConditionItemElement(value) {
    const div = document.createElement("div")
    div.className = "flex items-center gap-2 mb-2"
    div.innerHTML = `
      <span class="text-gray-400">・</span>
      <input type="text" value="${this.escapeHtml(value)}"
             class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
             data-action="input->template-editor#updateHiddenContent"
             placeholder="条件を入力">
      <button type="button" data-action="click->template-editor#removeConditionItem"
              class="text-red-500 hover:text-red-700 p-1">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    `
    this.conditionItemsTarget.appendChild(div)
  }

  removeConditionItem(event) {
    event.currentTarget.closest("div").remove()
    this.updateHiddenContent()
  }

  // === 確認書 ===
  addCategory() {
    this.addCategoryElement("", [])
    this.updateHiddenContent()
  }

  addCategoryElement(name, items) {
    const div = document.createElement("div")
    div.className = "border rounded-lg p-4 mb-4 bg-gray-50"
    div.dataset.category = ""
    div.innerHTML = `
      <div class="flex items-center gap-2 mb-3">
        <input type="text" value="${this.escapeHtml(name)}"
               class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 font-medium"
               data-action="input->template-editor#updateHiddenContent"
               data-role="category-name"
               placeholder="カテゴリ名（例: 材料費）">
        <button type="button" data-action="click->template-editor#removeCategory"
                class="text-red-500 hover:text-red-700 p-1" title="カテゴリを削除">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>
      <div data-role="items-container" class="space-y-2 ml-4">
      </div>
      <button type="button" data-action="click->template-editor#addItem"
              class="mt-2 ml-4 text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
        </svg>
        項目を追加
      </button>
    `

    this.confirmationCategoriesTarget.appendChild(div)

    // 項目を追加
    const container = div.querySelector('[data-role="items-container"]')
    items.forEach(item => this.addItemElement(container, item))
  }

  removeCategory(event) {
    event.currentTarget.closest("[data-category]").remove()
    this.updateHiddenContent()
  }

  addItem(event) {
    const container = event.currentTarget.closest("[data-category]").querySelector('[data-role="items-container"]')
    this.addItemElement(container, "")
    this.updateHiddenContent()
  }

  addItemElement(container, value) {
    const div = document.createElement("div")
    div.className = "flex items-center gap-2"
    div.innerHTML = `
      <span class="text-gray-400 text-sm">-</span>
      <input type="text" value="${this.escapeHtml(value)}"
             class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
             data-action="input->template-editor#updateHiddenContent"
             data-role="item-name"
             placeholder="項目名">
      <button type="button" data-action="click->template-editor#removeItem"
              class="text-red-400 hover:text-red-600 p-1">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    `
    container.appendChild(div)
  }

  removeItem(event) {
    event.currentTarget.closest("div").remove()
    this.updateHiddenContent()
  }

  // === 共通 ===
  updateHiddenContent() {
    if (this.typeValue === "condition") {
      const items = []
      this.conditionItemsTarget.querySelectorAll("input").forEach(input => {
        if (input.value.trim()) {
          items.push(input.value.trim())
        }
      })
      this.hiddenContentTarget.value = items.join("\n")
    } else {
      const data = {}
      this.confirmationCategoriesTarget.querySelectorAll("[data-category]").forEach(categoryDiv => {
        const categoryName = categoryDiv.querySelector('[data-role="category-name"]').value.trim()
        if (categoryName) {
          const items = []
          categoryDiv.querySelectorAll('[data-role="item-name"]').forEach(input => {
            if (input.value.trim()) {
              items.push(input.value.trim())
            }
          })
          if (items.length > 0) {
            data[categoryName] = items
          }
        }
      })
      this.hiddenContentTarget.value = JSON.stringify(data)
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
