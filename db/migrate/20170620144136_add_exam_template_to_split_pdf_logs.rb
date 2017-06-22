class AddExamTemplateToSplitPdfLogs < ActiveRecord::Migration
  def change
    add_reference :split_pdf_logs, :exam_template, index: true, foreign_key: true
  end
end
