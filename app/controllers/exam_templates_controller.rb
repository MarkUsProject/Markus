# The actions necessary for managing the Testing Framework form
require 'helpers/ensure_config_helper.rb'

class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = ExamTemplate.all

    # exam template with specific assignment
    @exam_template = ExamTemplate.find_by(assignment: @assignment)
    @filename = @exam_template.filename
    @num_pages = @exam_template.num_pages
    @template_divisions = @exam_template.template_divisions
  end

  def download
    @assignment = Assignment.find(params[:assignment_id])
    @exam_template = ExamTemplate.find_by(assignment: @assignment)
    @filename = @exam_template.filename
    @basename = File.basename(@filename, ".pdf")
    send_file("#{Rails.root}/data/dev/exam_templates/#{@basename}/#{@filename}",
              filename: "#{@filename}",
              type: "application/pdf")
  end
end
