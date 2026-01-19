import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal", "modalTitle", "currentAssignments", "projectIdInput", "employeeSelect", "assignForm",
    "assignmentTypePermanent", "assignmentTypePeriod", "dateFieldContainer", "startDateInput", "endDateInput"
  ]

  connect() {
    this.currentProjectId = null
  }

  openModal(event) {
    const projectId = event.params.projectId
    const projectName = event.params.projectName
    const date = event.params.date

    this.currentProjectId = projectId
    this.projectIdInputTarget.value = projectId
    this.modalTitleTarget.textContent = `人員配置: ${projectName}`

    // 日付が指定されている場合は期間指定モードをデフォルトに（単日としてセット）
    if (date) {
      this.assignmentTypePeriodTarget.checked = true
      this.dateFieldContainerTarget.classList.remove("hidden")
      this.startDateInputTarget.value = date
      this.endDateInputTarget.value = date
      this.startDateInputTarget.required = true
      this.endDateInputTarget.required = true
    } else {
      // 日付が指定されていない場合は固定モードをデフォルトに
      this.assignmentTypePermanentTarget.checked = true
      this.dateFieldContainerTarget.classList.add("hidden")
      this.startDateInputTarget.value = ""
      this.endDateInputTarget.value = ""
      this.startDateInputTarget.required = false
      this.endDateInputTarget.required = false
    }

    // 現在の配置を読み込む
    this.loadCurrentAssignments(projectId)

    // モーダルを表示
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.employeeSelectTarget.value = ""
    // リセット
    this.assignmentTypePermanentTarget.checked = true
    this.dateFieldContainerTarget.classList.add("hidden")
    this.startDateInputTarget.value = ""
    this.endDateInputTarget.value = ""
  }

  toggleDateField() {
    if (this.assignmentTypePeriodTarget.checked) {
      this.dateFieldContainerTarget.classList.remove("hidden")
      this.startDateInputTarget.required = true
      this.endDateInputTarget.required = true
    } else {
      this.dateFieldContainerTarget.classList.add("hidden")
      this.startDateInputTarget.required = false
      this.endDateInputTarget.required = false
      this.startDateInputTarget.value = ""
      this.endDateInputTarget.value = ""
    }
  }

  async loadCurrentAssignments(projectId) {
    this.currentAssignmentsTarget.innerHTML = '<p class="text-sm text-gray-500">読み込み中...</p>'

    try {
      const response = await fetch(`/schedule/project_assignments/${projectId}`)
      if (!response.ok) throw new Error("Failed to load")

      const data = await response.json()

      if (data.assignments && data.assignments.length > 0) {
        const html = data.assignments.map(a => `
          <div class="flex items-center justify-between py-1">
            <div class="flex items-center flex-wrap gap-1">
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${this.badgeClass(a.employment_type)}">
                ${a.employee_name}
              </span>
              <span class="text-xs text-gray-500">(${this.roleLabel(a.role)})</span>
              <span class="text-xs ${this.dateRangeClass(a)}">${this.formatDateRange(a)}</span>
            </div>
            <button type="button" class="text-red-500 hover:text-red-700 text-xs ml-2"
                    data-action="click->calendar#removeAssignment"
                    data-assignment-id="${a.id}">
              削除
            </button>
          </div>
        `).join("")
        this.currentAssignmentsTarget.innerHTML = html
      } else {
        this.currentAssignmentsTarget.innerHTML = '<p class="text-sm text-gray-400">配置なし</p>'
      }
    } catch (error) {
      this.currentAssignmentsTarget.innerHTML = '<p class="text-sm text-red-500">読み込みエラー</p>'
    }
  }

  async submitAssignment(event) {
    event.preventDefault()

    const formData = new FormData(this.assignFormTarget)
    const projectId = formData.get("project_assignment[project_id]")
    const assignmentType = formData.get("assignment_type")

    // 期間指定の場合、日付のバリデーション
    if (assignmentType === "period") {
      const startDate = formData.get("project_assignment[start_date]")
      const endDate = formData.get("project_assignment[end_date]")

      if (!startDate || !endDate) {
        alert("開始日と終了日を選択してください")
        return
      }

      if (startDate > endDate) {
        alert("終了日は開始日以降の日付を選択してください")
        return
      }
    }

    try {
      const response = await fetch(`/projects/${projectId}/project_assignments`, {
        method: "POST",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        // 成功したらページをリロードして表示を更新
        window.location.reload()
      } else {
        const data = await response.json()
        alert(data.error || "追加に失敗しました")
      }
    } catch (error) {
      alert("エラーが発生しました")
    }
  }

  async removeAssignment(event) {
    const assignmentId = event.target.dataset.assignmentId
    if (!confirm("この配置を削除しますか？")) return

    try {
      const response = await fetch(`/projects/${this.currentProjectId}/project_assignments/${assignmentId}`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        // 成功したらページをリロードして表示を更新
        window.location.reload()
      } else {
        alert("削除に失敗しました")
      }
    } catch (error) {
      alert("エラーが発生しました")
    }
  }

  badgeClass(employmentType) {
    const classes = {
      regular: "bg-blue-100 text-blue-700",
      temporary: "bg-yellow-100 text-yellow-700",
      external: "bg-purple-100 text-purple-700"
    }
    return classes[employmentType] || "bg-gray-100 text-gray-700"
  }

  roleLabel(role) {
    const labels = {
      foreman: "職長",
      worker: "作業員",
      support: "応援"
    }
    return labels[role] || role
  }

  formatDateRange(assignment) {
    // start_dateとend_dateが同じ場合は単日
    if (assignment.start_date && assignment.end_date && assignment.start_date === assignment.end_date) {
      return `[${this.formatDate(assignment.start_date)}のみ]`
    }
    // start_dateもend_dateもない場合は固定（全期間）
    if (!assignment.start_date && !assignment.end_date) {
      return "[固定]"
    }
    // それ以外は期間表示
    const start = assignment.start_date ? this.formatDate(assignment.start_date) : "開始"
    const end = assignment.end_date ? this.formatDate(assignment.end_date) : "終了"
    return `[${start}〜${end}]`
  }

  formatDate(dateStr) {
    const date = new Date(dateStr)
    return `${date.getMonth() + 1}/${date.getDate()}`
  }

  dateRangeClass(assignment) {
    // 単日の場合は青
    if (assignment.start_date && assignment.end_date && assignment.start_date === assignment.end_date) {
      return "text-blue-600"
    }
    // 期間指定の場合は緑
    if (assignment.start_date && assignment.end_date) {
      return "text-green-600"
    }
    // 固定の場合はグレー
    return "text-gray-400"
  }
}
