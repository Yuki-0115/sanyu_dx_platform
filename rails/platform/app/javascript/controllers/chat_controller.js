import { Controller } from "@hotwired/stimulus"

// チャット折りたたみ制御
export default class extends Controller {
  static targets = ["content", "arrow", "messages"]

  connect() {
    // 初期状態は開いた状態
    this.isOpen = true
    this.scrollToBottom()
  }

  toggle() {
    this.isOpen = !this.isOpen

    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.isOpen)
    }

    if (this.hasArrowTarget) {
      this.arrowTarget.classList.toggle("rotate-180", !this.isOpen)
    }
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
