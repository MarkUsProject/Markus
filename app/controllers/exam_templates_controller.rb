class ExamTemplatesController < ApplicationController
  # responders setup
  responders :flash, :http_cache
  respond_to :html

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = @assignment.exam_templates.includes(:template_divisions)
  end

  # Creates a new instance of the exam template.
  def create
    assignment = Assignment.find(params[:assignment_id])
    new_uploaded_io = params[:create_template][:file_io]
    name_input = params[:create_template][:name]
    # error checking when new_uploaded_io is not pdf, nil, or when filename is not given
    if new_uploaded_io.nil? || new_uploaded_io.content_type != 'application/pdf'
      flash_message(:error, t('exam_templates.create.failure'))
    else
      filename = new_uploaded_io.original_filename
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
      new_template_filename = new_uploaded_io.original_filename
      # error checking when new_uploaded_io is not pdf
      if new_uploaded_io.content_type != 'application/pdf'
        flash_message(:error, t('exam_templates.update.failure'))
      else
        old_template_filename = old_exam_template.filename
        old_exam_template.replace_with_file(new_uploaded_io.read,
                                            assignment_id: assignment.id,
                                            old_filename: old_template_filename,
                                            new_filename: new_template_filename)
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

  def generate
    copies = params[:numCopies].to_i
    index = params[:examTemplateIndex].to_i
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find(params[:id])

    flash_message(:success, t('exam_templates.generate.generate_job_started',
                              exam_name: exam_template.assignment.short_identifier))
    current_job = exam_template.generate_copies(copies, index)
    respond_to do |format|
      format.js { render 'exam_templates/_poll_generate_job.js.erb',
                         locals: { file_name: "#{index}-#{index + copies - 1}.pdf",
                                   exam_id: exam_template.id,
                                   job_id: current_job.job_id} }
    end
  end

  def download_generate
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find(params[:id])
    send_file(exam_template.base_path + '/' + params[:file_name],
              filename: params[:file_name],
              type: "application/pdf")
  end

  def split
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find(params[:id])
    split_exam = params[:exam_template][:pdf_to_split]
    unless split_exam.nil?
      if split_exam.content_type != 'application/pdf'
        flash_message(:error, t('exam_templates.split.invalid'))
        redirect_to action: 'index'
      else
        current_job = exam_template.split_pdf(split_exam.path, split_exam.original_filename, @current_user)
        flash[:split] = current_job.job_id
        respond_to do |format|
          format.html { redirect_to view_logs_assignment_exam_templates_path }
        end
      end
    else
      flash_message(:error, t('exam_templates.split.missing'))
      redirect_to action: 'index'
    end
  end

  def destroy
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find(params[:id])
    if exam_template.destroy
      flash_message(:success, t('exam_templates.delete.success'))
    else
      flash_message(:failure, t('exam_templates.delete.failure'))
    end
    redirect_to action: 'index'
  end

  def view_logs
    @assignment = Assignment.find(params[:assignment_id])
    @split_pdf_logs = SplitPdfLog.joins(exam_template: :assignment)
                                 .where(assignments: {id: @assignment.id})
                                 .includes(:exam_template)
                                 .includes(:user)
  end

  def exam_template_params
    params.require(:exam_template)
       .permit(
         :name,
         template_divisions_attributes: [:id, :start, :end, :label, :_destroy]
       )
  end
end
