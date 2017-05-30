class ExamTemplatesController < ApplicationController

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = @assignment.exam_templates
  end

  # Creates a new instance of the exam template.
  def create
    assignment = Assignment.find(params[:assignment_id])
    # retrieving exam template file
    new_uploaded_io = params[:create_template][:file_io]
    # error checking when new_uploaded_io is not pdf
    if new_uploaded_io.content_type != 'application/pdf'
      flash_message(:error, 'Exam Template Not Created Successfully')
      redirect_to action: 'index'
      return
    end
    # getting number of pages
    pdf = CombinePDF.parse new_uploaded_io.read
    num_pages = pdf.pages.length
    # getting filename
    filename = params[:create_template][:filename]
    # instantiates new exam template
    new_template = ExamTemplate.new(
      filename: filename,
      num_pages: num_pages,
      assignment: assignment
    )
    # creating corresponding directory and file
    assignment_name = Assignment.find(assignment.id).short_identifier
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name
    )
    FileUtils.mkdir template_path unless Dir.exists? template_path
    File.open(File.join(template_path, filename), 'wb') do |f|
      f.write new_uploaded_io.read
    end
    # sending flash message if saved
    if new_template.save
      flash_message(:success, 'Exam Template Created Successfully')
    else
      flash_message(:error, 'Exam Template Not Created Successfully')
    end
    redirect_to action: 'index'
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
end
