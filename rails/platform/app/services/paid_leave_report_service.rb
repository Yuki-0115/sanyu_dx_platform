# frozen_string_literal: true

require "csv"

class PaidLeaveReportService
  # 有給休暇管理簿CSV出力
  # 労働基準法で義務付けられた年次有給休暇管理簿の形式に準拠
  def self.generate_csv(employees, year)
    # 年度の開始・終了日（4月〜翌3月）
    fiscal_start = Date.new(year, 4, 1)
    fiscal_end = Date.new(year + 1, 3, 31)

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << [
        "社員コード",
        "氏名",
        "入社日",
        "基準日",
        "前年度繰越日数",
        "当年度付与日数",
        "合計付与日数",
        "取得日数",
        "残日数",
        "5日義務達成",
        "取得日一覧"
      ]

      employees.order(:code).each do |emp|
        base_date = emp.paid_leave_base_date || (emp.hire_date && (emp.hire_date + 6.months))

        # 当年度の付与
        current_grants = emp.paid_leave_grants.where(
          "grant_date >= ? AND grant_date <= ?", fiscal_start, fiscal_end
        )
        granted_days = current_grants.sum(:granted_days)

        # 前年度からの繰越（前年度付与分で、今年度期間に有効なもの）
        prev_grants = emp.paid_leave_grants.where(
          "grant_date < ? AND expiry_date >= ?", fiscal_start, fiscal_start
        )
        carried_over = prev_grants.sum { |g|
          # 前年度末時点での残日数を推定
          g.remaining_days + emp.paid_leave_requests
                                .approved
                                .where(paid_leave_grant_id: g.id)
                                .where("leave_date >= ?", fiscal_start)
                                .sum(:consumed_days)
        }

        # 年度内取得
        requests = emp.paid_leave_requests
                      .approved
                      .where(leave_date: fiscal_start..fiscal_end)
                      .order(:leave_date)
        taken_days = requests.sum(:consumed_days)

        # 残日数計算
        total_available = granted_days + carried_over
        remaining = total_available - taken_days

        # 取得日一覧
        dates_list = requests.map do |r|
          type_label = r.full_day? ? "全" : "半"
          "#{r.leave_date.strftime('%m/%d')}(#{type_label})"
        end.join(" / ")

        # 5日義務達成判定
        obligation_met = taken_days >= 5.0 ? "○" : "×"

        csv << [
          emp.code,
          emp.name,
          emp.hire_date&.strftime("%Y/%m/%d") || "-",
          base_date&.strftime("%m/%d") || "-",
          carried_over,
          granted_days,
          total_available,
          taken_days,
          remaining,
          obligation_met,
          dates_list.presence || "-"
        ]
      end
    end.encode("Windows-31J", undef: :replace, replace: "?")
  end

  # 月次有給取得状況レポート
  def self.generate_monthly_report(year, month)
    target_month = Date.new(year, month, 1)
    month_end = target_month.end_of_month

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << [
        "社員コード",
        "氏名",
        "当月取得日数",
        "累計取得日数",
        "残日数",
        "取得日一覧"
      ]

      Employee.where(employment_type: "regular").order(:code).each do |emp|
        # 当月取得
        monthly_requests = emp.paid_leave_requests
                              .approved
                              .where(leave_date: target_month..month_end)
                              .order(:leave_date)
        monthly_taken = monthly_requests.sum(:consumed_days)

        # 累計（年度開始から）
        fiscal_start = target_month.month >= 4 ? Date.new(year, 4, 1) : Date.new(year - 1, 4, 1)
        cumulative_taken = emp.paid_leave_taken_in_period(fiscal_start, month_end)

        # 残日数
        remaining = emp.total_paid_leave_remaining

        # 当月取得日一覧
        dates_list = monthly_requests.map do |r|
          type_label = r.full_day? ? "全" : "半"
          "#{r.leave_date.strftime('%m/%d')}(#{type_label})"
        end.join(" / ")

        csv << [
          emp.code,
          emp.name,
          monthly_taken,
          cumulative_taken,
          remaining,
          dates_list.presence || "-"
        ]
      end
    end.encode("Windows-31J", undef: :replace, replace: "?")
  end
end
