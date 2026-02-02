import { Controller } from "@hotwired/stimulus"

// 汎用タブ切り替えコントローラー
// 使用例:
// <div data-controller="tabs" data-tabs-active-class="tab-active" data-tabs-inactive-class="tab-inactive">
//   <button data-tabs-target="tab" data-action="click->tabs#select">Tab 1</button>
//   <button data-tabs-target="tab" data-action="click->tabs#select">Tab 2</button>
//   <div data-tabs-target="panel">Panel 1</div>
//   <div data-tabs-target="panel">Panel 2</div>
// </div>

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]
  static values = {
    index: { type: Number, default: 0 },
    hiddenClass: { type: String, default: "hidden" }
  }

  connect() {
    this.showTab(this.indexValue)
  }

  select(event) {
    event.preventDefault()
    const index = this.tabTargets.indexOf(event.currentTarget)
    if (index !== -1) {
      this.showTab(index)
    }
  }

  // 外部から呼び出し可能（タブ名で切り替え）
  switchTo(event) {
    const tabName = event.params?.tab || event.currentTarget.dataset.tabsTabParam
    const index = this.tabTargets.findIndex(tab => tab.dataset.tabName === tabName)
    if (index !== -1) {
      this.showTab(index)
    }
  }

  showTab(index) {
    // タブのアクティブ状態を更新
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.remove(...this.inactiveClasses)
        tab.classList.add(...this.activeClasses)
      } else {
        tab.classList.remove(...this.activeClasses)
        tab.classList.add(...this.inactiveClasses)
      }
    })

    // パネルの表示/非表示を更新
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove(this.hiddenClassValue)
      } else {
        panel.classList.add(this.hiddenClassValue)
      }
    })

    this.indexValue = index

    // カスタムイベントを発火（他のコントローラーと連携用）
    this.dispatch("changed", { detail: { index, tabName: this.tabTargets[index]?.dataset.tabName } })
  }

  // クラス配列を取得（スペース区切りの文字列にも対応）
  get activeClasses() {
    return this.hasActiveClass ? this.activeClass.split(" ") : ["tab-active"]
  }

  get inactiveClasses() {
    return this.hasInactiveClass ? this.inactiveClass.split(" ") : ["tab-inactive"]
  }
}
