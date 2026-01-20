import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["price"]

  applyAll() {
    const rows = document.querySelectorAll("tr.fuel-row")
    let updatedCount = 0
    const updatedRows = []

    // 各油種の単価入力欄を処理
    this.priceTargets.forEach(priceInput => {
      const fuelType = priceInput.dataset.fuelType
      const price = priceInput.value

      if (!price) return // 入力がない油種はスキップ

      // 該当する燃料費行を更新
      rows.forEach(row => {
        const rowFuelType = row.dataset.fuelType

        if (rowFuelType === fuelType) {
          const unitPriceInput = row.querySelector("input[name='unit_price']")
          if (unitPriceInput) {
            unitPriceInput.value = price
            // fuel-calc コントローラーの計算をトリガー
            unitPriceInput.dispatchEvent(new Event("input", { bubbles: true }))
            updatedCount++
            updatedRows.push(row)
          }
        }
      })
    })

    if (updatedCount > 0) {
      // 更新した行をハイライト
      updatedRows.forEach(row => {
        row.classList.add("bg-orange-50")
        setTimeout(() => row.classList.remove("bg-orange-50"), 1500)
      })
    } else {
      alert("単価を入力してください")
    }
  }
}
