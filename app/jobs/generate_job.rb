class GenerateJob < ApplicationJob

  queue_as Rails.configuration.x.queues.exam_generate

  def self.on_complete_js(status)
    path = Rails.application.routes.url_helpers.download_generate_assignment_exam_template_path(
      assignment_id: status[:id],
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
      pdf = Prawn::Document.new(margin: 15) do
        exam_template.num_pages.times do |page_num|
          qrcode_content = "#{exam_template.name}-#{exam_num}-#{page_num + 1}"
          qrcode = RQRCode::QRCode.new qrcode_content, level: :l, size: 2
          alignment = page_num.even? ? :right : :left
          # TODO: remove the line below and the pos: argument in render_qr_code once the align: argument is fixed
          #       see: https://github.com/jabbrwcky/prawn-qrcode/pull/33 (probably in release v0.5.2 of prawn-qrcode)
          pos = [page_num.even? ? bounds.width - 140 : 0, cursor]
          render_qr_code(qrcode, align: alignment, dot: 4.0, stroke: false, pos: pos)
          draw_text(qrcode_content,
                    at: [alignment == :left ? 140 : bounds.width - 140 - qrcode_content.length * 6, bounds.height - 30])
          start_new_page
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
