class GenerateJob < ApplicationJob
  def perform(exam_template, num_copies, start, enqueuing_user = nil)
    m_logger = MarkusLogger.instance
    progress.total = num_copies
    template_pdf = CombinePDF.load exam_template.file_path
    generated_pdf = CombinePDF.new
    (start..start + num_copies - 1).each do |exam_num|
      m_logger.log("Now generating: #{exam_num}")
      pdf = Prawn::Document.new(margin: 15, skip_page_creation: true) do
        template_pdf.pages.each_with_index do |page, page_num|
          # Start a new page with the same size and layout as the current page
          start_new_page(size: page.page_size[2..4], layout: page.orientation)
          qrcode_content = "#{exam_template.name}-#{exam_num}-#{page_num + 1}"
          qrcode = RQRCode::QRCode.new qrcode_content, level: :l, size: 2
          alignment = page_num.even? ? :right : :left
          render_qr_code(qrcode, align: alignment, dot: 4.0, stroke: false)
          draw_text(qrcode_content,
                    at: [alignment == :left ? 140 : bounds.width - 140 - qrcode_content.length * 6, bounds.height - 30])
        end
      end
      combine_pdf_qr = CombinePDF.parse(pdf.render)
      template_pdf.pages.zip(combine_pdf_qr.pages) do |template_page, qr_page|
        generated_pdf << (qr_page << template_page)
      end
      progress.increment
      if enqueuing_user
        ExamTemplatesChannel.broadcast_to(enqueuing_user, {
          status: 'in_progress',
          job_class: 'GenerateJob',
          exam_name: exam_template.name,
          page_number: progress.progress,
          total_pages: progress.total
        })
      end
    end

    FileUtils.mkdir_p(exam_template.tmp_path)
    generated_pdf.save File.join(exam_template.tmp_path, exam_template.generated_copies_file_name(num_copies, start))
    m_logger.log('Generate pdf copies process done')
    if enqueuing_user
      ExamTemplatesChannel.broadcast_to(enqueuing_user,
                                        { status: 'completed',
                                          job_class: 'GenerateJob',
                                          course_id: exam_template.course.id,
                                          exam_id: exam_template.id,
                                          file_name: exam_template.generated_copies_file_name(num_copies,
                                                                                              start) })
    end
  rescue StandardError => e
    if enqueuing_user
      ExamTemplatesChannel.broadcast_to(enqueuing_user, {
        status: 'failed',
        job_class: 'GenerateJob',
        exam_name: exam_template.name,
        exception: e.message
      })
    end
    raise e
  end
end
