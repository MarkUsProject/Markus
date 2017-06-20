class AddSuccessToSplitPdfLogs < ActiveRecord::Migration
  def change
    add_column :split_pdf_logs, :success, :boolean
  end
end
