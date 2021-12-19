class ExamTemplatesController < ApplicationController
  # responders setup
  responders :flash, :http_cache
  respond_to :html

  before_action { authorize! }

  layout 'assignment_content'

  content_security_policy only: [:assign_errors] do |p|
    p.img_src :self, :blob
  end

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = @assignment.exam_templates.order(:created_at).includes(:template_divisions)
  end

  # Creates a new instance of the exam template.
  def create
    assignment = Assignment.find(params[:assignment_id])
    new_uploaded_io = params[:create_template][:file_io]
    name = params[:create_template][:name]
    # error checking when new_uploaded_io is not pdf, nil, or when filename is not given
    if new_uploaded_io.nil? || new_uploaded_io.content_type != 'application/pdf'
      flash_message(:error, t('exam_templates.create.failure'))
    else
      filename = new_uploaded_io.original_filename
      exam_template = ExamTemplate.create_with_file(new_uploaded_io.read,
                                                    assessment_id: assignment.id,
                                                    filename: filename,
                                                    name: name)
      if exam_template&.valid?
        flash_message(:success, t('exam_templates.create.success'))
      else
        flash_message(:error, t('exam_templates.create.failure'))
      end
    end
    redirect_to course_assignment_exam_templates_path(current_course, assignment)
  end

  def download
    exam_template = record
    filename = exam_template.filename
    send_file(File.join(exam_template.base_path, filename),
              filename: "#{filename}",
              type: "application/pdf")
  end

  def update
    old_exam_template = record
    assignment = record.assignment
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
        respond_with(old_exam_template,
                     location: course_assignment_exam_templates_url(assignment.course, assignment, old_exam_template))
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
    redirect_to course_assignment_exam_templates_path(current_course, assignment)
  end

  def generate
    copies = params[:exam_template][:num_copies].to_i
    index = params[:exam_template][:start_index].to_i
    exam_template = record
    assignment = exam_template.assignment

    current_job = exam_template.generate_copies(copies, index)
    current_job.status.update(file_name: "#{exam_template.name}-#{index}-#{index + copies - 1}.pdf")
    current_job.status.update(exam_id: exam_template.id)
    current_job.status.update(course_id: assignment.course.id)
    session[:job_id] = current_job.job_id

    respond_to do |format|
      format.js { render 'exam_templates/_poll_generate_job.js.erb' }
    end
  end

  def download_generate
    exam_template = record
    send_file(File.join(exam_template.base_path, params[:file_name]),
              filename: params[:file_name],
              type: "application/pdf")
  end

  def show_cover
    exam_template = record
    cover_file = File.join(exam_template.base_path, 'cover.jpg')
    if File.file?(cover_file)
      send_file cover_file, disposition: 'inline', filename: 'cover.jpg'
    else
      head :not_found
    end
  end

  def add_fields
    exam_template = record
    if params[:exam_template][:automatic_parsing] == '1'
      exam_template.update(exam_template_crop_fields_params)
    else
      exam_template.update(
        automatic_parsing: false,
        cover_fields: '',
        crop_x: nil,
        crop_y: nil,
        crop_width: nil,
        crop_height: nil
      )
    end
    exam_template.save
    redirect_to course_assignment_exam_templates_path(current_course, exam_template.assignment)
  end

  def split
    exam_template = record
    split_exam = params[:exam_template]&.fetch(:pdf_to_split) { nil }
    unless split_exam.nil?
      if split_exam.content_type != 'application/pdf'
        flash_message(:error, t('exam_templates.split.invalid'))
        redirect_to course_assignment_exam_templates_path(current_course, exam_template.assignment)
      else
        current_job = exam_template.split_pdf(split_exam.path, split_exam.original_filename, current_role)
        session[:job_id] = current_job.job_id
        redirect_to view_logs_course_assignment_exam_templates_path(current_course, exam_template.assignment)
      end
    else
      flash_message(:error, t('exam_templates.split.missing'))
      redirect_to course_assignment_exam_templates_path(current_course, exam_template.assignment)
    end
  end

  def destroy
    exam_template = record
    if exam_template.delete_with_file
      flash_message(:success, t('exam_templates.delete.success'))
    else
      flash_message(:failure, t('exam_templates.delete.failure'))
    end
    redirect_to course_assignment_exam_templates_path(current_course, exam_template.assignment)
  end

  def view_logs
    @assignment = Assignment.find(params[:assignment_id])

    respond_to do |format|
      format.html
      format.json do
        split_pdf_logs = SplitPdfLog.joins(exam_template: :assignment)
                                    .where(assessments: { id: @assignment.id })
                                    .includes(:exam_template)
                                    .includes(:role)
                                    .includes(split_pages: :group)

        data = split_pdf_logs.map do |log|
          pages = log.split_pages.select do |p|
            # TODO: make status non-nil.
            p.status == 'FIXED' || p.status&.start_with?('ERROR')
          end

          page_data = pages.map do |page|
            {
              raw_page_number: page.raw_page_number,
              exam_page_number: page.exam_page_number,
              status: page.status,
              group: page.group_id.nil? ? nil : page.group.group_name,
              id: page.id
            }
          end
          {
            date: I18n.l(log.uploaded_when),
            exam_template: log.exam_template.name,
            exam_template_id: log.exam_template_id,
            filename: log.filename,
            file_id: log.id,
            num_groups_in_complete: log.num_groups_in_complete,
            num_groups_in_incomplete: log.num_groups_in_incomplete,
            original_num_pages: log.original_num_pages,
            num_pages_qr_scan_error: log.num_pages_qr_scan_error,
            #number_of_pages_fixed: log.split_pages.where(status: 'FIXED').length
            page_data: page_data
          }
        end
        render json: data
      end
    end
  end

  def assign_errors
    @exam_template = record
    @assignment = @exam_template.assignment
    @error_files = []
    @split_pdf_log = SplitPdfLog.find(params[:split_pdf_log_id])
    if params[:split_page_id]
      @next_error = @split_pdf_log.split_pages
                      .find(params[:split_page_id])
      unless @next_error.status.start_with? 'ERROR'
        @next_error = @split_pdf_log.split_pages.order(:id)
                        .find_by('status LIKE ?', 'ERROR%')
      end
    else
      @next_error = @split_pdf_log.split_pages.order(:id)
                      .find_by('status LIKE ?', 'ERROR%')
    end
    if @next_error.nil?
      flash_message(:success, t('exam_templates.assign_scans.done'))
    end
  end

  def error_pages
    exam_template = record
    exam_group = current_course.groups.find_by(group_name: "#{exam_template.name}_paper_#{params[:exam_number]}")
    expected_pages = [*1..exam_template.num_pages]
    if exam_group.nil?
      pages = expected_pages
    else
      pages = expected_pages - exam_group.split_pages.pluck(:exam_page_number)
    end
    render json: pages
  end

  def download_raw_split_file
    exam_template = record
    split_pdf_log = exam_template.split_pdf_logs.find(params[:split_pdf_log_id])
    split_file = "raw_upload_#{split_pdf_log.id}.pdf"
    send_file(File.join(exam_template.base_path, 'raw', split_file),
              filename: split_pdf_log.filename,
              type: 'application/pdf')
  end

  def download_error_file
    exam_template = record
    @assignment = record.assignment
    send_file(File.join(exam_template.base_path, 'error', params[:file_name]),
              filename: params[:file_name],
              type: 'application/pdf')
  end

  def fix_error
    exam_template = record
    split_page_id = params[:split_page_id]

    if params[:commit] == 'Save'
      copy_number = params[:copy_number]
      page_number = params[:page_number]
      filename = "#{split_page_id}.pdf"
      upside_down = params[:upside_down]
      exam_template.fix_error(filename, copy_number, page_number, upside_down)
    end

    split_pdf_log = SplitPdfLog.find(params[:split_pdf_log_id])
    next_error = split_pdf_log.split_pages.order(:id)
                   .where('id > ?', split_page_id)
                   .find_by('status LIKE ?', 'ERROR%')

    # Try looping back to the first split page error.
    if next_error.nil?
      next_error = split_pdf_log.split_pages.order(:id)
                     .find_by('status LIKE ?', 'ERROR%')
    end

    if next_error.nil?
      flash_now(:success, t('exam_templates.assign_scans.done'))
      render plain: ''
    else
      render plain: "#{next_error.id}.pdf"
    end

  end

  def exam_template_params
    params.require(:exam_template)
       .permit(
         :name,
         template_divisions_attributes: [:id, :start, :end, :label, :_destroy]
       )
  end

  def exam_template_crop_fields_params
    params.require(:exam_template)
          .permit(
            :automatic_parsing,
            :cover_fields,
            :crop_x,
            :crop_y,
            :crop_width,
            :crop_height
          )
  end
end
