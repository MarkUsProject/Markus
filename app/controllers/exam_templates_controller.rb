class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = ExamTemplate.all
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    exam_template = ExamTemplate.find_by(assignment: assignment)
    filename = exam_template.filename
    basename = File.basename(filename, ".pdf")
    send_file("#{Rails.root}/data/dev/exam_templates/#{basename}/#{filename}",
              filename: "#{filename}",
              type: "application/pdf")
  end
end
