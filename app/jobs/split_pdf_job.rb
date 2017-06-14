class SplitPDFJob < ActiveJob::Base
  include ActiveJob::Status

  queue_as MarkusConfigurator.markus_job_split_pdf_queue_name

  def perform(exam_template, path)
    m_logger = MarkusLogger.instance
    begin
      progress.total = 0
      # Create directory for files whose QR code couldn't be parsed
      error_dir = File.join(exam_template.base_path, 'error')
      raw_dir = File.join(exam_template.base_path, 'raw')
      FileUtils.mkdir error_dir unless Dir.exists? error_dir
      FileUtils.mkdir raw_dir unless Dir.exists? raw_dir

      basename = File.basename path, '.pdf'
      pdf = CombinePDF.load path
      partial_exams = Hash.new do |hash, key|
        hash[key] = []
      end
      pdf.pages.each_index do |i|
        page = pdf.pages[i]
        new_page = CombinePDF.new
        new_page << page
        new_page.save File.join(raw_dir, "#{basename}-#{i}.pdf")

        # Snip out the part of the PDF that contains the QR code.
        img = Magick::Image::read(File.join(raw_dir, "#{basename}-#{i}.pdf")).first
        qr_img = img.crop 0, 10, img.columns, img.rows / 5
        qr_img.write File.join(raw_dir, "#{basename}-#{i}.png")

        # qrcode_string = ZXing.decode new_page.to_pdf
        qrcode_string = ZXing.decode qr_img.to_blob
        qrcode_regex = /(?<short_id>\w+)-(?<exam_num>\d+)-(?<page_num>\d+)/
        m = qrcode_regex.match qrcode_string
        if m.nil?
          new_page.save File.join(error_dir, "#{basename}-#{i}.pdf")
        else
          partial_exams[m[:exam_num]] << [m[:page_num].to_i, page]
          m_logger.log("#{m[:short_id]}: exam number #{m[:exam_num]}, page #{m[:page_num]}")
        end
      end

      exam_template.save_pages partial_exams
      progress.increment
    end
     m_logger.log('Split pdf process done')
    rescue => e
      Rails.logger.error e.message
      raise e
    end
  end
