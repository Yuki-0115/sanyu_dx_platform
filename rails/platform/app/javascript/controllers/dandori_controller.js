import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "availableWorkers", "lastUpdated",
    "cellModal", "cellModalTitle", "cellModalDate", "cellEmployeeList",
    "cellEmployeeCheckbox", "cellRoleSelect", "cellSelectedCount", "cellSaveBtn",
    "cellModalHeader", "cellModalShiftBadge",
    "bulkModal", "projectSelect", "bulkEmployeeCheckbox", "selectedEmployeesCount",
    "bulkStartDate", "bulkEndDate", "bulkRole", "bulkShift", "bulkSummary", "bulkSubmitBtn",
    "noteModal", "noteModalTitle", "noteModalDate", "noteSaveBtn", "notePasteBtn",
    "noteWorkContent", "noteVehicles", "noteEquipment", "noteHeavyEquipment", "noteNotes"
  ]

  static values = {
    refreshInterval: { type: Number, default: 30000 } // 30秒
  }

  connect() {
    this.currentProjectId = null
    this.currentDate = null
    this.currentShift = "day" // 日勤/夜勤
    this.currentNoteProjectId = null
    this.currentNoteDate = null
    this.copiedNote = null // コピーされた備考データ
    this.assignedEmployees = {} // { date: [employeeIds] }

    // チェックボックスの変更を監視
    this.cellEmployeeCheckboxTargets.forEach(checkbox => {
      checkbox.addEventListener("change", () => this.updateCellSelectedCount())
    })

    // 自動更新を開始
    this.startAutoRefresh()

    // ページ可視性の変更を監視（タブ切り替え時）
    this.boundHandleVisibilityChange = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.boundHandleVisibilityChange)
  }

  disconnect() {
    this.stopAutoRefresh()
    document.removeEventListener("visibilitychange", this.boundHandleVisibilityChange)
  }

  // 自動更新を開始
  startAutoRefresh() {
    if (this.refreshTimer) return

    this.refreshTimer = setInterval(() => {
      this.refreshDandori()
    }, this.refreshIntervalValue)

    console.log(`段取り表: 自動更新開始 (${this.refreshIntervalValue / 1000}秒間隔)`)
  }

  // 自動更新を停止
  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
      console.log("段取り表: 自動更新停止")
    }
  }

  // ページ可視性の変更時
  handleVisibilityChange() {
    if (document.hidden) {
      this.stopAutoRefresh()
    } else {
      // タブに戻ってきたら即座に更新してから自動更新再開
      this.refreshDandori()
      this.startAutoRefresh()
    }
  }

  // 段取り表を更新（Turbo経由でリロード）
  refreshDandori() {
    // モーダルが開いている場合は更新しない
    if (this.isModalOpen()) {
      console.log("段取り表: モーダル表示中のため更新スキップ")
      return
    }

    // スクロール位置を保存
    const scrollX = window.scrollX
    const scrollY = window.scrollY

    // Turbo を使ってページを更新
    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set("view", "dandori")

    // Turboのmorph機能でスムーズに更新
    Turbo.visit(currentUrl.toString(), {
      action: "replace",
      // 更新後にスクロール位置を復元
    })

    // 少し待ってスクロール位置を復元（Turboのレンダリング後）
    setTimeout(() => {
      window.scrollTo(scrollX, scrollY)
    }, 100)
  }

  // モーダルが開いているか確認
  isModalOpen() {
    return !this.cellModalTarget.classList.contains("hidden") ||
           !this.bulkModalTarget.classList.contains("hidden") ||
           !this.noteModalTarget.classList.contains("hidden")
  }

  // ========================
  // 日付ヘッダークリック - 残り人員表示
  // ========================

  async showAvailableWorkers(event) {
    const date = event.currentTarget.dataset.date
    const dateLabel = event.currentTarget.dataset.dateLabel

    // その日に配置されていない作業員を取得
    try {
      const response = await fetch(`/schedule/employee_schedule/available?date=${date}`, {
        headers: { "Accept": "application/json" }
      })

      if (response.ok) {
        const data = await response.json()
        this.displayAvailableWorkers(dateLabel, data.available)
      } else {
        // APIがない場合はページ上のデータから計算（フォールバック）
        this.calculateAvailableFromPage(date, dateLabel)
      }
    } catch (error) {
      this.calculateAvailableFromPage(date, dateLabel)
    }
  }

  calculateAvailableFromPage(date, dateLabel) {
    // ページ上のセルから配置済み社員を抽出
    const cells = document.querySelectorAll(`[data-date="${date}"]`)
    const assignedNames = new Set()

    cells.forEach(cell => {
      const badges = cell.querySelectorAll('span[title]')
      badges.forEach(badge => {
        const name = badge.textContent.trim().replace('★', '')
        if (name) assignedNames.add(name)
      })
    })

    // 全作業員リストから配置済みを除外
    const allWorkers = this.cellEmployeeCheckboxTargets.map(cb => ({
      id: cb.dataset.employeeId,
      name: cb.dataset.employeeName
    }))

    const available = allWorkers.filter(w => {
      return !Array.from(assignedNames).some(name => w.name.startsWith(name))
    })

    this.displayAvailableWorkers(dateLabel, available)
  }

  displayAvailableWorkers(dateLabel, available) {
    if (available.length === 0) {
      this.availableWorkersTarget.innerHTML = `
        <div class="text-red-600 font-medium">${dateLabel}: 配置可能な作業員がいません</div>
      `
    } else {
      const names = available.map(w => w.name || w).join('、')
      this.availableWorkersTarget.innerHTML = `
        <div><span class="font-medium text-green-700">${dateLabel}</span> の残り人員 (${available.length}名):</div>
        <div class="mt-1 flex flex-wrap gap-1">
          ${available.map(w => `<span class="inline-flex items-center px-2 py-0.5 rounded bg-green-100 text-green-800 text-xs">${w.name || w}</span>`).join('')}
        </div>
      `
    }
  }

  // ========================
  // セルモーダル操作
  // ========================

  async openCellModal(event) {
    event.stopPropagation()

    this.currentProjectId = event.currentTarget.dataset.projectId
    this.currentDate = event.currentTarget.dataset.date
    this.currentShift = event.currentTarget.dataset.shift || "day"
    const projectName = event.currentTarget.dataset.projectName
    const dateLabel = event.currentTarget.dataset.dateLabel

    this.cellModalTitleTarget.textContent = projectName
    this.cellModalDateTarget.textContent = dateLabel

    // 勤務帯バッジを更新
    if (this.hasCellModalShiftBadgeTarget) {
      const isDay = this.currentShift === "day"
      this.cellModalShiftBadgeTarget.textContent = isDay ? "日勤" : "夜勤"
      this.cellModalShiftBadgeTarget.className = `px-2 py-0.5 text-xs font-medium rounded-full ${
        isDay ? "bg-orange-100 text-orange-700" : "bg-indigo-100 text-indigo-700"
      }`
    }

    // ヘッダーの背景色を更新
    if (this.hasCellModalHeaderTarget) {
      const isDay = this.currentShift === "day"
      this.cellModalHeaderTarget.className = `px-4 py-3 border-b ${
        isDay ? "bg-orange-50" : "bg-indigo-50"
      }`
    }

    // 現在の配置状況を取得
    await this.loadCurrentCellAssignments()

    this.cellModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeCellModal() {
    this.cellModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetCellModal()
  }

  resetCellModal() {
    this.cellEmployeeCheckboxTargets.forEach(cb => cb.checked = false)
    this.cellRoleSelectTargets.forEach(select => select.value = "worker")
    document.querySelectorAll('.cell-worker-status').forEach(el => el.textContent = '')
    this.updateCellSelectedCount()
  }

  async loadCurrentCellAssignments() {
    try {
      // WorkScheduleベースのAPIを呼び出す
      const response = await fetch(`/schedule/cell_data?project_id=${this.currentProjectId}&date=${this.currentDate}`)
      if (!response.ok) return

      const data = await response.json()

      // 現在の勤務帯に配置されている社員にチェック
      const assignments = this.currentShift === "day" ? data.day : data.night

      assignments.forEach(a => {
        const checkbox = this.cellEmployeeCheckboxTargets.find(
          cb => cb.dataset.employeeId === String(a.employee_id)
        )
        if (checkbox) {
          checkbox.checked = true
          // 役割もセット（WorkScheduleにroleがある場合）
          const roleSelect = this.cellRoleSelectTargets.find(
            s => s.dataset.employeeId === String(a.employee_id)
          )
          if (roleSelect && a.role) roleSelect.value = a.role
        }
      })

      this.updateCellSelectedCount()
    } catch (error) {
      console.error("Failed to load assignments:", error)
    }
  }

  markOtherAssignments() {
    // この機能は後で実装（他現場配置状況の表示）
    // 今はスキップ
  }

  selectAllInCell() {
    this.cellEmployeeCheckboxTargets.forEach(cb => cb.checked = true)
    this.updateCellSelectedCount()
  }

  deselectAllInCell() {
    this.cellEmployeeCheckboxTargets.forEach(cb => cb.checked = false)
    this.updateCellSelectedCount()
  }

  updateCellSelectedCount() {
    const count = this.cellEmployeeCheckboxTargets.filter(cb => cb.checked).length
    this.cellSelectedCountTarget.textContent = `${count}名選択中`
  }

  async saveCellAssignments() {
    const selectedEmployees = this.cellEmployeeCheckboxTargets
      .filter(cb => cb.checked)
      .map(cb => {
        const roleSelect = this.cellRoleSelectTargets.find(
          s => s.dataset.employeeId === cb.dataset.employeeId
        )
        return {
          employee_id: cb.dataset.employeeId,
          role: roleSelect ? roleSelect.value : "worker"
        }
      })

    this.cellSaveBtnTarget.disabled = true
    this.cellSaveBtnTarget.textContent = "保存中..."

    try {
      // save_cell APIは既存の配置をクリアして新しい配置を作成する
      const response = await fetch("/schedule/save_cell", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          project_id: this.currentProjectId,
          date: this.currentDate,
          shift: this.currentShift,
          employee_ids: selectedEmployees.map(e => e.employee_id),
          roles: selectedEmployees.reduce((acc, e) => {
            acc[e.employee_id] = e.role
            return acc
          }, {})
        })
      })

      const data = await response.json()

      if (data.success) {
        window.location.reload()
      } else {
        alert("エラー:\n" + (data.errors?.join("\n") || "保存に失敗しました"))
        this.cellSaveBtnTarget.disabled = false
        this.cellSaveBtnTarget.textContent = "保存"
      }
    } catch (error) {
      alert("通信エラーが発生しました")
      this.cellSaveBtnTarget.disabled = false
      this.cellSaveBtnTarget.textContent = "保存"
    }
  }

  // ========================
  // 一括配置モーダル（ヘッダーボタン用）
  // ========================

  openBulkModal() {
    this.bulkModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.resetBulkForm()
  }

  closeBulkModal() {
    this.bulkModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  resetBulkForm() {
    if (this.hasProjectSelectTarget) this.projectSelectTarget.value = ""
    this.bulkEmployeeCheckboxTargets.forEach(cb => cb.checked = false)
    if (this.hasBulkStartDateTarget) this.bulkStartDateTarget.value = ""
    if (this.hasBulkEndDateTarget) this.bulkEndDateTarget.value = ""
    if (this.hasBulkShiftTarget) this.bulkShiftTarget.value = "day"
    if (this.hasBulkRoleTarget) this.bulkRoleTarget.value = "worker"
    this.updateBulkSummary()
  }

  selectProject(event) {
    const projectId = event.currentTarget.dataset.projectId

    this.openBulkModal()
    if (this.hasProjectSelectTarget) {
      this.projectSelectTarget.value = projectId
      this.onProjectChange()
    }
  }

  onProjectChange() {
    if (!this.hasProjectSelectTarget) return

    const selectedOption = this.projectSelectTarget.selectedOptions[0]
    if (selectedOption && selectedOption.value) {
      const startDate = selectedOption.dataset.start
      const endDate = selectedOption.dataset.end

      if (startDate && this.hasBulkStartDateTarget) this.bulkStartDateTarget.value = startDate
      if (endDate && this.hasBulkEndDateTarget) this.bulkEndDateTarget.value = endDate
    }
    this.updateBulkSummary()
  }

  selectAllEmployees() {
    this.bulkEmployeeCheckboxTargets.forEach(cb => cb.checked = true)
    this.updateBulkSummary()
  }

  deselectAllEmployees() {
    this.bulkEmployeeCheckboxTargets.forEach(cb => cb.checked = false)
    this.updateBulkSummary()
  }

  updateBulkSummary() {
    if (!this.hasProjectSelectTarget || !this.hasBulkSummaryTarget) return

    const projectId = this.projectSelectTarget.value
    const projectName = this.projectSelectTarget.selectedOptions[0]?.text || ""
    const employeeCount = this.bulkEmployeeCheckboxTargets.filter(cb => cb.checked).length
    const startDate = this.hasBulkStartDateTarget ? this.bulkStartDateTarget.value : ""
    const endDate = this.hasBulkEndDateTarget ? this.bulkEndDateTarget.value : ""
    const shift = this.hasBulkShiftTarget ? (this.bulkShiftTarget.selectedOptions[0]?.text || "日勤") : "日勤"
    const role = this.hasBulkRoleTarget ? (this.bulkRoleTarget.selectedOptions[0]?.text || "作業員") : "作業員"

    if (this.hasSelectedEmployeesCountTarget) {
      this.selectedEmployeesCountTarget.textContent = `${employeeCount}名選択中`
    }

    if (projectId && employeeCount > 0) {
      let period = "全期間"
      if (startDate && endDate) {
        period = `${this.formatDate(startDate)} 〜 ${this.formatDate(endDate)}`
      }

      this.bulkSummaryTarget.innerHTML = `
        <div class="text-gray-900 font-medium">${projectName}</div>
        <div class="mt-1">に ${employeeCount}名 を「${shift}」「${role}」として配置します</div>
        <div class="mt-1 text-gray-500">期間: ${period}</div>
      `
      if (this.hasBulkSubmitBtnTarget) this.bulkSubmitBtnTarget.disabled = false
    } else {
      this.bulkSummaryTarget.textContent = "案件と作業員を選択してください"
      if (this.hasBulkSubmitBtnTarget) this.bulkSubmitBtnTarget.disabled = true
    }
  }

  formatDate(dateStr) {
    const date = new Date(dateStr)
    return `${date.getMonth() + 1}/${date.getDate()}`
  }

  async executeBulkAssign() {
    if (!this.hasProjectSelectTarget) return

    const projectId = this.projectSelectTarget.value
    const employeeIds = this.bulkEmployeeCheckboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.dataset.employeeId)
    const startDate = this.hasBulkStartDateTarget ? this.bulkStartDateTarget.value : null
    const endDate = this.hasBulkEndDateTarget ? this.bulkEndDateTarget.value : null
    const shift = this.hasBulkShiftTarget ? this.bulkShiftTarget.value : "day"
    const role = this.hasBulkRoleTarget ? this.bulkRoleTarget.value : "worker"

    if (!projectId || employeeIds.length === 0) {
      alert("案件と作業員を選択してください")
      return
    }

    this.bulkSubmitBtnTarget.disabled = true
    this.bulkSubmitBtnTarget.textContent = "処理中..."

    try {
      const response = await fetch("/schedule/bulk_assign", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          project_id: projectId,
          employee_ids: employeeIds,
          start_date: startDate || null,
          end_date: endDate || null,
          shift: shift,
          role: role
        })
      })

      const data = await response.json()

      if (data.success) {
        alert(data.message)
        window.location.reload()
      } else {
        alert("エラー:\n" + (data.errors?.join("\n") || "配置に失敗しました"))
        this.bulkSubmitBtnTarget.disabled = false
        this.bulkSubmitBtnTarget.textContent = "一括配置を実行"
      }
    } catch (error) {
      alert("通信エラーが発生しました")
      this.bulkSubmitBtnTarget.disabled = false
      this.bulkSubmitBtnTarget.textContent = "一括配置を実行"
    }
  }

  // ========================
  // 配置解除
  // ========================

  async removeAssignment(event) {
    const assignmentId = event.currentTarget.dataset.assignmentId
    if (!confirm("この配置を解除しますか？")) return

    try {
      const response = await fetch(`/schedule/remove_assignment/${assignmentId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        window.location.reload()
      } else {
        alert("削除に失敗しました")
      }
    } catch (error) {
      alert("エラーが発生しました")
    }
  }

  // ========================
  // 備考モーダル操作
  // ========================

  async openNoteModal(event) {
    event.stopPropagation()

    this.currentNoteProjectId = event.currentTarget.dataset.projectId
    this.currentNoteDate = event.currentTarget.dataset.date
    const projectName = event.currentTarget.dataset.projectName
    const dateLabel = event.currentTarget.dataset.dateLabel

    this.noteModalTitleTarget.textContent = projectName
    this.noteModalDateTarget.textContent = dateLabel

    // 貼り付けボタンの状態を更新
    if (this.hasNotePasteBtnTarget) {
      if (this.copiedNote) {
        this.notePasteBtnTarget.disabled = false
        this.notePasteBtnTarget.classList.remove("text-gray-400")
        this.notePasteBtnTarget.classList.add("text-gray-600", "hover:bg-gray-50")
      } else {
        this.notePasteBtnTarget.disabled = true
        this.notePasteBtnTarget.classList.add("text-gray-400")
        this.notePasteBtnTarget.classList.remove("text-gray-600", "hover:bg-gray-50")
      }
    }

    // 現在の備考を読み込み
    await this.loadCurrentNote()

    this.noteModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeNoteModal() {
    this.noteModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.resetNoteModal()
  }

  resetNoteModal() {
    this.noteWorkContentTarget.value = ""
    this.noteVehiclesTarget.value = ""
    this.noteEquipmentTarget.value = ""
    this.noteHeavyEquipmentTarget.value = ""
    this.noteNotesTarget.value = ""
  }

  async loadCurrentNote() {
    try {
      const response = await fetch(
        `/schedule/schedule_note?project_id=${this.currentNoteProjectId}&date=${this.currentNoteDate}`,
        { headers: { "Accept": "application/json" } }
      )

      if (!response.ok) return

      const data = await response.json()

      if (data.note) {
        this.noteWorkContentTarget.value = data.note.work_content || ""
        this.noteVehiclesTarget.value = data.note.vehicles || ""
        this.noteEquipmentTarget.value = data.note.equipment || ""
        this.noteHeavyEquipmentTarget.value = data.note.heavy_equipment_transport || ""
        this.noteNotesTarget.value = data.note.notes || ""
      } else {
        this.resetNoteModal()
      }
    } catch (error) {
      console.error("Failed to load note:", error)
    }
  }

  async saveNote() {
    this.noteSaveBtnTarget.disabled = true
    this.noteSaveBtnTarget.textContent = "保存中..."

    try {
      const response = await fetch("/schedule/save_schedule_note", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          project_id: this.currentNoteProjectId,
          date: this.currentNoteDate,
          work_content: this.noteWorkContentTarget.value,
          vehicles: this.noteVehiclesTarget.value,
          equipment: this.noteEquipmentTarget.value,
          heavy_equipment_transport: this.noteHeavyEquipmentTarget.value,
          notes: this.noteNotesTarget.value
        })
      })

      const data = await response.json()

      if (data.success) {
        // セルの備考アイコンを更新
        this.updateNoteIcon()
        this.closeNoteModal()
      } else {
        alert("エラー:\n" + (data.errors?.join("\n") || "保存に失敗しました"))
      }
    } catch (error) {
      alert("通信エラーが発生しました")
    } finally {
      this.noteSaveBtnTarget.disabled = false
      this.noteSaveBtnTarget.textContent = "保存"
    }
  }

  updateNoteIcon() {
    // 該当セルの備考アイコンを更新
    const cell = document.querySelector(
      `td[data-project-id="${this.currentNoteProjectId}"][data-date="${this.currentNoteDate}"]`
    )

    if (!cell) return

    const noteBtn = cell.querySelector('button[data-action="click->dandori#openNoteModal"]')
    if (!noteBtn) return

    const svg = noteBtn.querySelector('svg')
    const hasContent = this.noteWorkContentTarget.value ||
                       this.noteVehiclesTarget.value ||
                       this.noteEquipmentTarget.value ||
                       this.noteHeavyEquipmentTarget.value ||
                       this.noteNotesTarget.value

    if (hasContent) {
      noteBtn.classList.remove("text-gray-300")
      noteBtn.classList.add("text-amber-500")
      svg.setAttribute("fill", "currentColor")
      noteBtn.title = "備考（入力あり）"
    } else {
      noteBtn.classList.remove("text-amber-500")
      noteBtn.classList.add("text-gray-300")
      svg.setAttribute("fill", "none")
      noteBtn.title = "備考"
    }
  }

  // 備考をコピー
  copyNote() {
    this.copiedNote = {
      work_content: this.noteWorkContentTarget.value,
      vehicles: this.noteVehiclesTarget.value,
      equipment: this.noteEquipmentTarget.value,
      heavy_equipment_transport: this.noteHeavyEquipmentTarget.value,
      notes: this.noteNotesTarget.value
    }

    // 貼り付けボタンを有効化
    if (this.hasNotePasteBtnTarget) {
      this.notePasteBtnTarget.disabled = false
      this.notePasteBtnTarget.classList.remove("text-gray-400")
      this.notePasteBtnTarget.classList.add("text-gray-600", "hover:bg-gray-50")
    }

    // フィードバック表示
    const originalText = event.currentTarget.innerHTML
    event.currentTarget.innerHTML = `
      <svg class="w-4 h-4 mr-1 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      コピー完了
    `
    setTimeout(() => {
      event.currentTarget.innerHTML = originalText
    }, 1500)
  }

  // 備考を貼り付け
  pasteNote() {
    if (!this.copiedNote) return

    this.noteWorkContentTarget.value = this.copiedNote.work_content || ""
    this.noteVehiclesTarget.value = this.copiedNote.vehicles || ""
    this.noteEquipmentTarget.value = this.copiedNote.equipment || ""
    this.noteHeavyEquipmentTarget.value = this.copiedNote.heavy_equipment_transport || ""
    this.noteNotesTarget.value = this.copiedNote.notes || ""

    // フィードバック表示
    const originalText = event.currentTarget.innerHTML
    event.currentTarget.innerHTML = `
      <svg class="w-4 h-4 mr-1 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      貼り付け完了
    `
    setTimeout(() => {
      event.currentTarget.innerHTML = originalText
    }, 1500)
  }
}
