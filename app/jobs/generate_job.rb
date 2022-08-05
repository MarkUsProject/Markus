class GenerateJob < ApplicationJob
  def self.on_complete_js(status)
    path = Rails.application.routes.url_helpers.download_generate_course_exam_template_path(
      course_id: status[:course_id],
      id: status[:exam_id]
    )
    "(data) => {
      if (!data.error_message) {
        window.location = '#{path}?file_name=#{status[:file_name]}'
      }
    }"
  end

  def self.show_status(status)
    I18n.t('poll_job.generate_job', progress: status[:progress], total: status[:total], exam_name: status[:exam_name])
  end

  before_enqueue do |job|
    status.update(exam_name: job.arguments[0].name)
  end

  def perform(exam_template, num_copies, start)
    m_logger = MarkusLogger.instance
    progress.total = num_copies
    template_path = File.join(
      exam_template.base_path,
      exam_template.filename
    )
    template_pdf = CombinePDF.load template_path
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
    end

    generated_pdf.save File.join(
      exam_template.base_path,
      "#{exam_template.name}-#{start}-#{start + num_copies - 1}.pdf"
    )
    m_logger.log('Generate pdf copies process done')
  end
end
