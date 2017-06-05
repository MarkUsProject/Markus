class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = @assignment.exam_templates
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find_by(id: params[:id]) # look up a specific exam template based on the params[:id]
    filename = exam_template.filename
    basename = File.basename(filename, ".pdf")
    send_file("#{EXAM_TEMPLATE_DIR}/#{basename}/#{filename}",
              filename: "#{filename}",
              type: "application/pdf")
  end

  def update
    new_uploaded_io = params[:exam_template][:new_template]
    # error checking when new_uploaded_io is not pdf
    if new_uploaded_io.content_type != 'application/pdf'
      flash_message(:error, t('exam_templates.update.failure'))
      redirect_to action: 'index'
      return
    end
    assignment = Assignment.find(params[:assignment_id])
    old_exam_template = assignment.exam_templates.find_by(id: params[:id])
    old_template_filename = old_exam_template.filename
    old_exam_template.replace_with_file(new_uploaded_io.read, assignment_id: assignment.id, filename: old_template_filename)
    flash_message(:success, t('exam_templates.update.success'))
    redirect_to action: 'index'
  end

  def generate
    copies = params[:numCopies]
    index = params[:examTemplateIndex]
    if copies < 1 || index < 1
      flash_message(:error, "Invalid")
      redirect_to action: 'index'
      return
    end

    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find_by(id: params[:id])
    exam_template.generate_copies(copies, index)
    flash_message(:success, "Successfully generated #{copies} exam copies")
    redirect_to action: 'index'
  end
end
