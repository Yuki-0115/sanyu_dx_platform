import { Controller } from "@hotwired/stimulus"

// 全ページの数字入力フィールドに対して：
// - 全角数字を半角に自動変換（ペースト・IME確定時）
// - フォーカス時に全選択（すぐ上書き可能に）
export default class extends Controller {
  connect() {
    this._focusedInput = null

    this.onFocusIn = this.onFocusIn.bind(this)
    this.onFocusOut = this.onFocusOut.bind(this)
    this.onPaste = this.onPaste.bind(this)
    this.onCompositionEnd = this.onCompositionEnd.bind(this)

    this.element.addEventListener("focusin", this.onFocusIn)
    this.element.addEventListener("focusout", this.onFocusOut)
    this.element.addEventListener("paste", this.onPaste)
    this.element.addEventListener("compositionend", this.onCompositionEnd)
  }

  disconnect() {
    this.element.removeEventListener("focusin", this.onFocusIn)
    this.element.removeEventListener("focusout", this.onFocusOut)
    this.element.removeEventListener("paste", this.onPaste)
    this.element.removeEventListener("compositionend", this.onCompositionEnd)
  }

  // フォーカス時：数字フィールドの内容を全選択（1回だけ）
  onFocusIn(event) {
    const input = event.target
    if (!this.isNumberField(input)) return
    if (input === this._focusedInput) return // 既にフォーカス中 → 再選択しない
    this._focusedInput = input
    if (input.value === "") return

    requestAnimationFrame(() => {
      // まだ同じフィールドにフォーカスしている場合のみ選択
      if (document.activeElement === input) {
        input.select()
      }
    })
  }

  // フォーカスアウト時：追跡をリセット
  onFocusOut(event) {
    if (event.target === this._focusedInput) {
      this._focusedInput = null
    }
  }

  // ペースト時：全角数字を半角に変換
  onPaste(event) {
    const input = event.target
    if (!this.isNumberField(input)) return

    const pasted = (event.clipboardData || window.clipboardData).getData("text")
    if (this.hasZenkaku(pasted)) {
      event.preventDefault()
      const converted = this.convertZenkaku(pasted)
      input.value = converted
      input.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  // IME確定時：全角数字を半角に変換
  onCompositionEnd(event) {
    const input = event.target
    if (!this.isNumberField(input)) return
    if (!event.data || !this.hasZenkaku(event.data)) return

    const converted = this.convertZenkaku(event.data)
    // type="number"ではブラウザが全角を拒否して値が空になるので直接セット
    requestAnimationFrame(() => {
      if (input.value === "" || this.hasZenkaku(input.value)) {
        input.value = converted
        input.dispatchEvent(new Event("input", { bubbles: true }))
      }
    })
  }

  isNumberField(el) {
    return el.tagName === "INPUT" && (el.type === "number" || el.type === "text")
  }

  hasZenkaku(str) {
    return /[０-９．，、。ー−]/.test(str)
  }

  convertZenkaku(str) {
    return str
      .replace(/[０-９]/g, s => String.fromCharCode(s.charCodeAt(0) - 0xFEE0))
      .replace(/[．。]/g, ".")
      .replace(/[，、]/g, "")
      .replace(/[ー−]/g, "-")
  }
}
