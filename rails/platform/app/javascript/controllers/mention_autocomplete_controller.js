import { Controller } from "@hotwired/stimulus"

// メンションオートコンプリート
// @入力時に社員候補を表示し、選択するとテキストに挿入
export default class extends Controller {
  static targets = ["input", "dropdown", "list"]
  static values = {
    employees: Array
  }

  connect() {
    this.isOpen = false
    this.currentQuery = ""
    this.selectedIndex = -1
  }

  // 入力時のハンドラ
  onInput(event) {
    const value = event.target.value
    const cursorPos = event.target.selectionStart

    // カーソル位置より前のテキストを取得
    const textBeforeCursor = value.substring(0, cursorPos)

    // @の後に続く文字列を検出
    const mentionMatch = textBeforeCursor.match(/@(\S*)$/)

    if (mentionMatch) {
      this.currentQuery = mentionMatch[1].toLowerCase()
      this.showDropdown()
    } else {
      this.hideDropdown()
    }
  }

  // キーダウンハンドラ
  onKeydown(event) {
    if (!this.isOpen) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.moveSelection(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveSelection(-1)
        break
      case "Enter":
        if (this.selectedIndex >= 0) {
          event.preventDefault()
          this.selectCurrentItem()
        }
        break
      case "Escape":
        this.hideDropdown()
        break
    }
  }

  // ドロップダウン表示
  showDropdown() {
    const filtered = this.filteredEmployees()

    if (filtered.length === 0) {
      this.hideDropdown()
      return
    }

    this.renderList(filtered)
    this.dropdownTarget.classList.remove("hidden")
    this.isOpen = true
    this.selectedIndex = 0
    this.updateSelection()
  }

  // ドロップダウン非表示
  hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.isOpen = false
    this.selectedIndex = -1
  }

  // フィルタリング
  filteredEmployees() {
    if (!this.employeesValue) return []

    return this.employeesValue.filter(emp => {
      const name = emp.name.toLowerCase()
      return name.includes(this.currentQuery)
    }).slice(0, 5)  // 最大5件
  }

  // リスト描画
  renderList(employees) {
    this.listTarget.innerHTML = employees.map((emp, index) => `
      <li class="px-3 py-2 cursor-pointer hover:bg-blue-100 ${index === this.selectedIndex ? 'bg-blue-100' : ''}"
          data-action="click->mention-autocomplete#selectItem"
          data-index="${index}"
          data-name="${emp.name}">
        <span class="font-medium">${emp.name}</span>
        <span class="text-gray-500 text-xs ml-1">(${emp.role})</span>
      </li>
    `).join("")
  }

  // 選択移動
  moveSelection(direction) {
    const items = this.listTarget.querySelectorAll("li")
    const maxIndex = items.length - 1

    this.selectedIndex += direction
    if (this.selectedIndex < 0) this.selectedIndex = maxIndex
    if (this.selectedIndex > maxIndex) this.selectedIndex = 0

    this.updateSelection()
  }

  // 選択状態更新
  updateSelection() {
    const items = this.listTarget.querySelectorAll("li")
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("bg-blue-100")
      } else {
        item.classList.remove("bg-blue-100")
      }
    })
  }

  // 現在選択中の項目を挿入
  selectCurrentItem() {
    const items = this.listTarget.querySelectorAll("li")
    if (items[this.selectedIndex]) {
      const name = items[this.selectedIndex].dataset.name
      this.insertMention(name)
    }
  }

  // 項目クリック時
  selectItem(event) {
    const name = event.currentTarget.dataset.name
    this.insertMention(name)
  }

  // メンションをテキストに挿入
  insertMention(name) {
    const input = this.inputTarget
    const value = input.value
    const cursorPos = input.selectionStart

    // @の位置を見つける
    const textBeforeCursor = value.substring(0, cursorPos)
    const atIndex = textBeforeCursor.lastIndexOf("@")

    if (atIndex === -1) return

    // テキストを置き換え
    const before = value.substring(0, atIndex)
    const after = value.substring(cursorPos)
    const newValue = before + "@" + name + " " + after

    input.value = newValue

    // カーソル位置を調整
    const newCursorPos = atIndex + name.length + 2  // @name + space
    input.setSelectionRange(newCursorPos, newCursorPos)
    input.focus()

    this.hideDropdown()
  }

  // フォーカスが外れたときドロップダウンを閉じる（少し遅延）
  onBlur() {
    setTimeout(() => {
      this.hideDropdown()
    }, 200)
  }
}
