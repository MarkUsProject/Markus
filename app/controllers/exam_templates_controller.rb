class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = ExamTemplate.find_by(assignment: @assignment)
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    exam_template = ExamTemplate.find_by(assignment: assignment, id: params[:id]) # look up a specific exam template based on the params[:id]
    filename = exam_template.filename
    basename = File.basename(filename, ".pdf")
    send_file("#{EXAM_TEMPLATE_DIR}/#{basename}/#{filename}",
              filename: "#{filename}",
              type: "application/pdf")
  end

  def update
    new_uploaded_io = params[:new_template]
    # error checking when new_uploaded_io is not pdf
    if new_uploaded_io.content_type != 'application/pdf'
      flash_message(:failure, 'Exam Template should be in pdf format')
      redirect_to action: 'index'
    else
      assignment = Assignment.find(params[:assignment_id])
      old_exam_template = ExamTemplate.find_by(assignment: assignment, id: params[:id])
      old_template_filename = old_exam_template.filename
      ExamTemplate.create_with_file(new_uploaded_io.read, assignment_id: assignment.id, filename: old_template_filename)
      flash_message(:success, 'Exam Template has been successfully uploaded')
      redirect_to action: 'index'
    end
  end
end
