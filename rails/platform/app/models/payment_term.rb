# frozen_string_literal: true

class PaymentTerm < ApplicationRecord
  # Associations
  belongs_to :termable, polymorphic: true

  # Validations
  validates :name, presence: true
  validates :closing_day, presence: true, inclusion: { in: 0..31 }
  validates :payment_month_offset, presence: true, inclusion: { in: 0..6 }
  validates :payment_day, presence: true, inclusion: { in: 0..31 }

  # Scopes
  scope :default_term, -> { where(is_default: true) }

  # Calculate expected payment date from base date (invoice issue date, etc.)
  def calculate_payment_date(base_date)
    # 1. Find closing date for the period
    closing_date = find_closing_date(base_date)

    # 2. Add month offset
    payment_month = closing_date + payment_month_offset.months

    # 3. Determine payment day
    if payment_day.zero? # 末日
      payment_month.end_of_month
    else
      day = [payment_day, payment_month.end_of_month.day].min
      Date.new(payment_month.year, payment_month.month, day)
    end
  end

  # Display format: "20日締め・翌月末払い"
  def display_name
    closing = closing_day.zero? ? "末" : "#{closing_day}日"
    month = case payment_month_offset
            when 0 then "当月"
            when 1 then "翌月"
            when 2 then "翌々月"
            else "#{payment_month_offset}ヶ月後"
            end
    pay_day = payment_day.zero? ? "末" : "#{payment_day}日"
    "#{closing}締め・#{month}#{pay_day}払い"
  end

  # プリセット一覧
  PRESETS = [
    { name: "末締め・翌月末払い", closing_day: 0, payment_month_offset: 1, payment_day: 0 },
    { name: "20日締め・翌月末払い", closing_day: 20, payment_month_offset: 1, payment_day: 0 },
    { name: "末締め・翌々月10日払い", closing_day: 0, payment_month_offset: 2, payment_day: 10 },
    { name: "末締め・翌々月末払い", closing_day: 0, payment_month_offset: 2, payment_day: 0 },
    { name: "20日締め・翌々月20日払い", closing_day: 20, payment_month_offset: 2, payment_day: 20 }
  ].freeze

  private

  def find_closing_date(base_date)
    if closing_day.zero? # 末日締め
      base_date.end_of_month
    else
      day = [closing_day, base_date.end_of_month.day].min
      closing = Date.new(base_date.year, base_date.month, day)
      # 基準日が締め日より後なら翌月の締め日
      closing >= base_date ? closing : (closing + 1.month).beginning_of_month + (closing_day - 1).days
    end
  end
end
