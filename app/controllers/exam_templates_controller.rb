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
    assignment = Assignment.find(params[:assignment_id])
    old_exam_template = ExamTemplate.find_by(assignment: assignment, id: params[:id]) # look up a specific exam template based on the params[:id]
    filename = old_exam_template.filename
    # Get new exam template from upload form
    new_exam_template = File.open(params[:upload])
    template = ExamTemplate.create_with_file(new_exam_template.read, assignment_id: assignment.id, filename: filename)
    #template.template_divisions.create_with_associations(assignment.id, label: 'Q1', start: 2, end: 2)
    #template.template_divisions.create_with_associations(assignment.id, label: 'Q2', start: 3, end: 3)
    #template.template_divisions.create_with_associations(assignment.id, label: 'Q3', start: 3, end: 3)
    #template.template_divisions.create_with_associations(assignment.id, label: 'Q4', start: 4, end: 5)
    #flash_message(:success, I18n.t('update success'))
    #redirect_to action: 'index'
  end
end
