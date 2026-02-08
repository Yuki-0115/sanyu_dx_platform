import { Controller } from "@hotwired/stimulus"

// チャットフォーム制御
export default class extends Controller {
  static targets = ["input"]

  reset() {
    // フォーム送信後に入力欄をクリア
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }

    // メッセージ一覧を最下部にスクロール
    const messages = document.getElementById("chat-messages")
    if (messages) {
      setTimeout(() => {
        messages.scrollTop = messages.scrollHeight
      }, 100)
    }
  }
}
