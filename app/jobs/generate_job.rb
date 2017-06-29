class GenerateJob < ActiveJob::Base
  include ActiveJob::Status

  queue_as MarkusConfigurator.markus_job_generate_queue_name

  def perform(exam_template, num_copies, start)
    m_logger = MarkusLogger.instance
    begin
      progress.total = num_copies
      template_path = File.join(
        exam_template.base_path,
        exam_template.filename
      )
      template_pdf = CombinePDF.load template_path
      generated_pdf = CombinePDF.new
      (start..start + num_copies - 1).each do |exam_num|
        m_logger.log("Now generating: #{exam_num}")
        pdf = Prawn::Document.new(margin: 20)
        exam_template.num_pages.times do |page_num|
          qrcode_content = "#{exam_template.assignment.short_identifier}-#{exam_num}-#{page_num + 1}"
          qrcode = RQRCode::QRCode.new qrcode_content, level: :l, size: 2
          alignment = page_num % 2 == 0 ? :right : :left
          pdf.render_qr_code(qrcode, align: alignment, dot: 3.2, stroke: false)
          pdf.text("#{exam_template.name} #{exam_num}-#{page_num + 1}", align: alignment)
          pdf.start_new_page
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
     end
     m_logger.log('Generate pdf copies process done')
    rescue => e
      Rails.logger.error e.message
      raise e
    end
  end
