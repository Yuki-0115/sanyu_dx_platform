import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "content", "filename", "filesize", "backdrop"]

  connect() {
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  open(event) {
    event.preventDefault()

    const url = event.currentTarget.dataset.filePreviewUrlValue
    const filename = event.currentTarget.dataset.filePreviewFilenameValue
    const contentType = event.currentTarget.dataset.filePreviewContentTypeValue
    const filesize = event.currentTarget.dataset.filePreviewFilesizeValue

    this.filenameTarget.textContent = filename
    this.filesizeTarget.textContent = filesize

    // コンテンツをクリア
    this.contentTarget.innerHTML = ""

    if (this.isImage(contentType)) {
      // 画像の場合
      const img = document.createElement("img")
      img.src = url
      img.alt = filename
      img.className = "max-w-full max-h-[70vh] mx-auto"
      this.contentTarget.appendChild(img)
    } else if (this.isPdf(contentType)) {
      // PDFの場合
      const iframe = document.createElement("iframe")
      iframe.src = url
      iframe.className = "w-full h-[70vh]"
      iframe.title = filename
      this.contentTarget.appendChild(iframe)
    } else {
      // その他のファイルの場合
      const div = document.createElement("div")
      div.className = "text-center py-12"
      div.innerHTML = `
        <svg class="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
        </svg>
        <p class="text-gray-600 mb-4">このファイル形式はプレビューできません</p>
        <a href="${url}" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700" download>
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
          </svg>
          ダウンロード
        </a>
      `
      this.contentTarget.appendChild(div)
    }

    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")

    // ESCキーでモーダルを閉じる
    document.addEventListener("keydown", this.boundCloseOnEscape)
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.contentTarget.innerHTML = ""

    // ESCキーリスナーを解除
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnBackdrop(event) {
    // クリックがモーダルコンテンツの外側（バックドロップ）の場合のみ閉じる
    if (event.target === this.backdropTarget || event.target.parentElement === this.backdropTarget) {
      this.close()
    }
  }

  isImage(contentType) {
    return contentType && contentType.startsWith("image/")
  }

  isPdf(contentType) {
    return contentType === "application/pdf"
  }
}
