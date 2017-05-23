class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = ExamTemplate.find_by(assignment: @assignment)
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    exam_templates = ExamTemplate.find_by(assignment: assignment)
    filename = exam_templates[0].filename
    basename = File.basename(filename, ".pdf")
    send_file("#{EXAM_TEMPLATE_DIR}/#{basename}/#{filename}",
              filename: "#{filename}",
              type: "application/pdf")
  end
end
