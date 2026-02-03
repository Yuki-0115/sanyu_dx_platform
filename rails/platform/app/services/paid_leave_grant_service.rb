# frozen_string_literal: true

class PaidLeaveGrantService
  # 法定付与日数テーブル（フルタイム）
  # 勤続年数 => 付与日数
  GRANT_TABLE = {
    0.5 => 10, # 6ヶ月
    1.5 => 11, # 1年6ヶ月
    2.5 => 12, # 2年6ヶ月
    3.5 => 14, # 3年6ヶ月
    4.5 => 16, # 4年6ヶ月
    5.5 => 18, # 5年6ヶ月
    6.5 => 20  # 6年6ヶ月以上
  }.freeze

  def initialize(employee)
    @employee = employee
  end

  # 付与日数を計算
  def calculate_grant_days
    years = continuous_service_years
    return 0 if years < 0.5

    # 6.5年以上は一律20日
    return 20 if years >= 6.5

    GRANT_TABLE.select { |k, _| k <= years }.max_by { |k, _| k }&.last || 0
  end

  # 次回付与日を計算
  def next_grant_date
    base = @employee.paid_leave_base_date || (@employee.hire_date && (@employee.hire_date + 6.months))
    return nil unless base
    return base if base > Date.current

    # 既に基準日を過ぎている場合、次の付与日を計算
    years_since_base = ((Date.current - base) / 365.25).floor
    base + (years_since_base + 1).years
  end

  # 勤続年数を取得
  def continuous_service_years
    return 0 unless @employee.hire_date

    ((Date.current - @employee.hire_date) / 365.25).round(1)
  end

  # 付与実行
  def grant!(grant_date: Date.current, grant_type: "auto")
    days = calculate_grant_days
    return nil if days == 0

    expiry_date = grant_date + 2.years

    PaidLeaveGrant.create!(
      employee: @employee,
      grant_date: grant_date,
      expiry_date: expiry_date,
      granted_days: days,
      remaining_days: days,
      fiscal_year: grant_date.year,
      grant_type: grant_type
    )
  end

  # 手動付与（特別付与など）
  def manual_grant!(days:, grant_date: Date.current, expiry_date: nil, grant_type: "manual", notes: nil)
    expiry_date ||= grant_date + 2.years

    PaidLeaveGrant.create!(
      employee: @employee,
      grant_date: grant_date,
      expiry_date: expiry_date,
      granted_days: days,
      remaining_days: days,
      fiscal_year: grant_date.year,
      grant_type: grant_type,
      notes: notes
    )
  end

  # 一括付与（基準日到来社員に対して）
  def self.bulk_grant!(target_date = Date.current)
    results = { granted: [], skipped: [], errors: [] }

    Employee.where(employment_type: "regular").find_each do |employee|
      service = new(employee)
      base = employee.paid_leave_base_date || (employee.hire_date && (employee.hire_date + 6.months))

      # 基準日がない場合はスキップ
      unless base
        results[:skipped] << { employee: employee, reason: "基準日なし" }
        next
      end

      # 基準日が対象日でない場合はスキップ
      unless grant_due?(base, target_date)
        results[:skipped] << { employee: employee, reason: "付与対象日ではない" }
        next
      end

      # 既に同一基準日で付与済みならスキップ
      if employee.paid_leave_grants.exists?(grant_date: target_date)
        results[:skipped] << { employee: employee, reason: "付与済み" }
        next
      end

      begin
        grant = service.grant!(grant_date: target_date)
        if grant
          results[:granted] << { employee: employee, days: grant.granted_days }
        else
          results[:skipped] << { employee: employee, reason: "付与日数0" }
        end
      rescue => e
        results[:errors] << { employee: employee, error: e.message }
      end
    end

    results
  end

  # 失効処理（期限切れの有給を失効扱いにする）
  def self.expire_old_grants!(target_date = Date.current)
    expired_count = 0

    PaidLeaveGrant.where("expiry_date < ? AND remaining_days > 0", target_date).find_each do |grant|
      grant.update!(
        expired_days: grant.remaining_days,
        remaining_days: 0
      )
      expired_count += 1
    end

    expired_count
  end

  private

  def self.grant_due?(base_date, target_date)
    return false unless base_date

    # 初回付与（まさに基準日当日）
    return true if base_date == target_date

    # 年次チェック：基準日の月日が一致するか
    base_date.month == target_date.month && base_date.day == target_date.day
  end
end
