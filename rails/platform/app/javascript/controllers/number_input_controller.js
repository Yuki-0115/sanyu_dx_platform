import { Controller } from "@hotwired/stimulus"

// 全ページの数字入力フィールドに対して：
// - 全角数字を半角に自動変換（ペースト・IME確定時）
// - フォーカス時に全選択（すぐ上書き可能に）
export default class extends Controller {
  connect() {
    this._focusedInput = null
    this._hasTyped = false
    this._trackedValue = ""
    this._inComposition = false
    this._wasSelected = false

    this.onFocusIn = this.onFocusIn.bind(this)
    this.onFocusOut = this.onFocusOut.bind(this)
    this.onInput = this.onInput.bind(this)
    this.onPaste = this.onPaste.bind(this)
    this.onCompositionStart = this.onCompositionStart.bind(this)
    this.onCompositionEnd = this.onCompositionEnd.bind(this)

    this.element.addEventListener("focusin", this.onFocusIn)
    this.element.addEventListener("focusout", this.onFocusOut)
    this.element.addEventListener("input", this.onInput)
    this.element.addEventListener("paste", this.onPaste)
    this.element.addEventListener("compositionstart", this.onCompositionStart)
    this.element.addEventListener("compositionend", this.onCompositionEnd)
  }

  disconnect() {
    this.element.removeEventListener("focusin", this.onFocusIn)
    this.element.removeEventListener("focusout", this.onFocusOut)
    this.element.removeEventListener("input", this.onInput)
    this.element.removeEventListener("paste", this.onPaste)
    this.element.removeEventListener("compositionstart", this.onCompositionStart)
    this.element.removeEventListener("compositionend", this.onCompositionEnd)
  }

  onInput(event) {
    const input = event.target
    if (!this.isNumberField(input)) return

    this._hasTyped = true

    // IME処理中（compositionEnd完了まで含む）はinput.valueが不正確なので無視
    if (this._inComposition) return

    this._wasSelected = false
    if (input.value !== "") {
      this._trackedValue = input.value
    }
  }

  onFocusIn(event) {
    const input = event.target
    if (!this.isNumberField(input)) return
    if (input === this._focusedInput) return
    this._focusedInput = input
    this._hasTyped = false
    this._wasSelected = false
    this._trackedValue = input.value || ""

    if (input.value === "") return

    requestAnimationFrame(() => {
      if (document.activeElement === input && !this._hasTyped) {
        input.select()
        this._wasSelected = true
      }
    })
  }

  onFocusOut(event) {
    const input = event.target
    if (input !== this._focusedInput) return

    setTimeout(() => {
      if (document.activeElement !== input) {
        this._focusedInput = null
        this._hasTyped = false
        this._trackedValue = ""
        this._wasSelected = false
      }
    }, 100)
  }

  onPaste(event) {
    const input = event.target
    if (!this.isNumberField(input)) return

    const pasted = (event.clipboardData || window.clipboardData).getData("text")
    if (this.hasZenkaku(pasted)) {
      event.preventDefault()
      const converted = this.convertZenkaku(pasted)
      input.value = converted
      this._trackedValue = converted
      this._wasSelected = false
      input.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  onCompositionStart(event) {
    if (!this.isNumberField(event.target)) return
    this._inComposition = true
  }

  onCompositionEnd(event) {
    const input = event.target

    if (!this.isNumberField(input)) {
      this._inComposition = false
      return
    }

    // 全角数字が含まれない場合はブラウザに任せる
    if (!event.data || !this.hasZenkaku(event.data)) {
      this._inComposition = false
      return
    }

    const converted = this.convertZenkaku(event.data)

    // 全選択状態だった場合は上書き、そうでなければ追記
    let newValue
    if (this._wasSelected) {
      newValue = converted
      this._wasSelected = false
    } else {
      newValue = (this._trackedValue || "") + converted
    }
    this._trackedValue = newValue

    // ★ _inCompositionをsetTimeoutまで維持する
    // compositionEnd後にブラウザがinputイベントを発火し、リバートされた
    // input.valueで_trackedValueを上書きするのを防ぐ
    setTimeout(() => {
      input.value = newValue
      this._inComposition = false
    }, 0)
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
