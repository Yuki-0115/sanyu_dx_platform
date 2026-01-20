import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "content", "text", "overlay", "collapseIcon"]
  static values = { collapsed: { type: Boolean, default: false } }

  connect() {
    // localStorageから状態を復元（デスクトップのみ）
    if (window.innerWidth >= 1024) {
      const savedState = localStorage.getItem("sidebarCollapsed")
      if (savedState !== null) {
        this.collapsedValue = savedState === "true"
      }
      this.updateDesktopUI()
    }

    // リサイズ時の対応
    window.addEventListener("resize", this.handleResize.bind(this))
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize.bind(this))
  }

  handleResize() {
    if (window.innerWidth >= 1024) {
      // デスクトップ: モバイルの状態をリセット
      this.closeMobile()
      this.updateDesktopUI()
    } else {
      // モバイル: デスクトップの折りたたみ状態をリセット
      this.resetDesktopUI()
    }
  }

  toggle() {
    // モバイル: サイドバーを開閉
    if (window.innerWidth < 1024) {
      this.toggleMobile()
    } else {
      // デスクトップ: 折り畳み
      this.collapsedValue = !this.collapsedValue
      localStorage.setItem("sidebarCollapsed", this.collapsedValue)
      this.updateDesktopUI()
    }
  }

  toggleMobile() {
    if (!this.hasSidebarTarget) return

    const sidebar = this.sidebarTarget
    const isOpen = !sidebar.classList.contains("-translate-x-full")

    if (isOpen) {
      this.closeMobile()
    } else {
      this.openMobile()
    }
  }

  openMobile() {
    if (!this.hasSidebarTarget) return

    this.sidebarTarget.classList.remove("-translate-x-full")
    this.sidebarTarget.classList.add("translate-x-0")

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
      this.overlayTarget.classList.add("opacity-100", "pointer-events-auto")
    }
    document.body.style.overflow = "hidden"
  }

  closeMobile() {
    if (!this.hasSidebarTarget) return

    this.sidebarTarget.classList.add("-translate-x-full")
    this.sidebarTarget.classList.remove("translate-x-0")

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("opacity-0", "pointer-events-none")
      this.overlayTarget.classList.remove("opacity-100", "pointer-events-auto")
    }
    document.body.style.overflow = ""
  }

  close() {
    this.closeMobile()
  }

  updateDesktopUI() {
    if (!this.hasSidebarTarget) return

    const sidebar = this.sidebarTarget

    if (this.collapsedValue) {
      // 折り畳み状態
      sidebar.classList.remove("w-64")
      sidebar.classList.add("w-16")

      // テキストを非表示
      this.textTargets.forEach(el => {
        el.classList.add("lg:hidden")
        el.classList.add("opacity-0")
      })

      // アイコンを回転
      if (this.hasCollapseIconTarget) {
        this.collapseIconTarget.classList.add("rotate-180")
      }
    } else {
      // 展開状態
      sidebar.classList.remove("w-16")
      sidebar.classList.add("w-64")

      // テキストを表示
      this.textTargets.forEach(el => {
        el.classList.remove("lg:hidden")
        el.classList.remove("opacity-0")
      })

      // アイコンを元に戻す
      if (this.hasCollapseIconTarget) {
        this.collapseIconTarget.classList.remove("rotate-180")
      }
    }
  }

  resetDesktopUI() {
    if (!this.hasSidebarTarget) return

    const sidebar = this.sidebarTarget
    sidebar.classList.remove("w-16")
    sidebar.classList.add("w-64")

    this.textTargets.forEach(el => {
      el.classList.remove("lg:hidden")
      el.classList.remove("opacity-0")
    })
  }
}
