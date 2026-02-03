import { Controller } from "@hotwired/stimulus"

// データ取込フォーム：ドラッグ＆ドロップとファイル選択
export default class extends Controller {
  static targets = ["dropzone", "fileInput", "fileInfo", "fileName", "submitBtn"]

  connect() {
    // 初期状態
  }

  // ファイル選択時
  fileSelected(event) {
    const file = event.target.files[0]
    if (file) {
      this.showFileInfo(file)
    }
  }

  // ドラッグオーバー
  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50")
  }

  // ドラッグエンター
  dragenter(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-blue-500", "bg-blue-50")
  }

  // ドラッグリーブ
  dragleave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50")
  }

  // ドロップ
  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-blue-500", "bg-blue-50")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      const file = files[0]
      const validExtensions = [".xlsx", ".xls", ".csv"]
      const ext = file.name.substring(file.name.lastIndexOf(".")).toLowerCase()

      if (validExtensions.includes(ext)) {
        // ファイル入力に設定
        const dataTransfer = new DataTransfer()
        dataTransfer.items.add(file)
        this.fileInputTarget.files = dataTransfer.files
        this.showFileInfo(file)
      } else {
        alert("対応しているファイル形式: .xlsx, .xls, .csv")
      }
    }
  }

  // ファイル情報表示
  showFileInfo(file) {
    this.fileInfoTarget.classList.remove("hidden")
    this.fileNameTarget.textContent = `${file.name} (${this.formatFileSize(file.size)})`
  }

  // ファイルサイズフォーマット
  formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes"
    const k = 1024
    const sizes = ["Bytes", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i]
  }
}
