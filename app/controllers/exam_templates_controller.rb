class ExamTemplatesController < ApplicationController
  # responders setup
  responders :flash, :http_cache
  respond_to :html

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = @assignment.exam_templates
  end

  # Creates a new instance of the exam template.
  def create
    assignment = Assignment.find(params[:assignment_id])
    new_uploaded_io = params[:create_template][:file_io]
    name_input = params[:create_template][:name]
    filename = new_uploaded_io.original_filename
    # error checking when new_uploaded_io is not pdf, nil, or when filename is not given
    if filename.nil? || new_uploaded_io.nil? || new_uploaded_io.content_type != 'application/pdf'
      flash_message(:error, t('exam_templates.create.failure'))
    else
      new_template = ExamTemplate.new_with_file(new_uploaded_io.read,
                                                assignment_id: assignment.id,
                                                filename: filename,
                                                name_input: name_input)
      # sending flash message if saved
      if new_template.save
        flash_message(:success, t('exam_templates.create.success'))
      else
        flash_message(:error, t('exam_templates.create.failure'))
      end
    end
    redirect_to action: 'index'
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find_by(id: params[:id]) # look up a specific exam template based on the params[:id]
    filename = exam_template.filename
    assignment_name = assignment.short_identifier
    send_file("#{EXAM_TEMPLATE_DIR}/#{assignment_name}/#{filename}",
              filename: "#{filename}",
              type: "application/pdf")
  end

  def update
    assignment = Assignment.find(params[:assignment_id])
    old_exam_template = assignment.exam_templates.find_by(id: params[:id])
    # updating exam template file
    new_uploaded_io = params[:exam_template][:new_template]
    unless new_uploaded_io.nil?
      # error checking when new_uploaded_io is not pdf
      if new_uploaded_io.content_type != 'application/pdf'
        flash_message(:error, t('exam_templates.update.failure'))
      else
        old_template_filename = old_exam_template.filename
        old_exam_template.replace_with_file(new_uploaded_io.read, assignment_id: assignment.id, filename: old_template_filename)
        old_exam_template.update(exam_template_params)
        respond_with(old_exam_template, location: assignment_exam_templates_url)
        return
      end
    else
      # updating template division
      if old_exam_template.update(exam_template_params)
        flash_message(:success, t('exam_templates.update.success'))
      else
        flash_message(:error, t('exam_templates.update.failure'))
      end
    end
    redirect_to action: 'index'
  end

  def create_template_division
    assignment = Assignment.find(params[:assignment_id])
    template = assignment.exam_templates.find(params[:id])
    division_start = params[:start]
    division_end = params[:end]
    division_label = params[:label]

    new_template_division = template.template_divisions.new_with_input(
      assignment.id,
      label: division_label,
      start: division_start,
      end: division_end
    )
    # sending flash message if saved
    if new_template_division.save
      flash_message(:success, t('template_divisions.create.success'))
    else
      flash_message(:error, t('template_divisions.create.failure'))
    end
    redirect_to action: 'index'
  end

  # Dialog to create template division.
  def create_division_dialog
    @assignment = Assignment.find(params[:assignment_id])
    @exam_template = @assignment.exam_templates.find(params[:id])

    render partial: 'exam_templates/create_division_dialog',
           formats: [:js], handlers: [:erb]
  end

  def generate
    copies = params[:numCopies].to_i
    index = params[:examTemplateIndex].to_i
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find(params[:id])
    exam_template.generate_copies(copies, index)
    flash_message(:success, t('exam_templates.generate.success', copies: copies))

    generated_filename = "#{index}-#{index + copies - 1}.pdf"
    send_file("#{exam_template.base_path}/#{generated_filename}",
              filename: "#{generated_filename}",
              type: "application/pdf")
  end

  def exam_template_params
    params.require(:exam_template)
       .permit(
         :name,
         template_divisions_attributes: [:id, :start, :end, :label, :_destroy]
       )
  end
end
