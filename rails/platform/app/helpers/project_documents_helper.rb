# frozen_string_literal: true

module ProjectDocumentsHelper
  def category_icon_svg(category)
    case category
    when "contract"
      '<svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>'.html_safe
    when "site_management"
      '<svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" /></svg>'.html_safe
    when "safety"
      '<svg class="w-5 h-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>'.html_safe
    when "completion"
      '<svg class="w-5 h-5 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" /></svg>'.html_safe
    when "photo"
      '<svg class="w-5 h-5 text-pink-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>'.html_safe
    else
      '<svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" /></svg>'.html_safe
    end
  end

  # システムで自動生成される書類（見積・日報等）を取得
  def get_system_documents(project, category)
    documents = []

    case category
    when "contract"
      # 見積書
      if project.estimate.present?
        documents << {
          type: "見積",
          name: "見積書",
          date: project.estimate.created_at.strftime("%Y/%m/%d"),
          path: project_estimate_path(project)
        }
      end

    when "site_management"
      # 現場台帳（案件詳細）
      documents << {
        type: "台帳",
        name: "現場台帳",
        date: project.created_at.strftime("%Y/%m/%d"),
        path: project_path(project)
      }

      # 実行予算
      if project.budget.present?
        documents << {
          type: "予算",
          name: "実行予算書",
          date: project.budget.created_at.strftime("%Y/%m/%d"),
          path: project_budget_path(project)
        }
      end

      # 日報一覧
      if project.daily_reports.any?
        documents << {
          type: "日報",
          name: "日報一覧（#{project.daily_reports.count}件）",
          date: project.daily_reports.maximum(:report_date)&.strftime("%Y/%m/%d") || "-",
          path: project_daily_reports_path(project)
        }
      end

    when "completion"
      # 請求書
      project.invoices.each do |invoice|
        documents << {
          type: "請求",
          name: "請求書 ##{invoice.invoice_number}",
          date: invoice.issued_date&.strftime("%Y/%m/%d") || invoice.created_at.strftime("%Y/%m/%d"),
          path: project_invoice_path(project, invoice)
        }
      end
    end

    documents
  end
end
