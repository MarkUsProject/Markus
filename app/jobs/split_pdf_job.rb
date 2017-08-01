class SplitPDFJob < ActiveJob::Base
  include ActiveJob::Status

  queue_as MarkusConfigurator.markus_job_split_pdf_queue_name

  def self.on_complete_js(status)
    'window.location.reload.bind(window.location)'
  end

  def self.show_status(status)
    I18n.t('poll_job.split_pdf_job', progress: status[:progress],
                            total: status[:total],
                            exam_name: status[:exam_name])
  end

  before_enqueue do |job|
    status.update(job_class: self.class)
    status.update(exam_name: job.arguments[0].name + ' (' + job.arguments[2] + ')')
  end

  def perform(exam_template, path, original_filename=nil, current_user=nil)
    m_logger = MarkusLogger.instance
    begin
      # Create directory for files whose QR code couldn't be parsed
      error_dir = File.join(exam_template.base_path, 'error')
      raw_dir = File.join(exam_template.base_path, 'raw')
      complete_dir = File.join(exam_template.base_path, 'complete')
      incomplete_dir = File.join(exam_template.base_path, 'incomplete')
      FileUtils.mkdir_p error_dir unless Dir.exists? error_dir
      FileUtils.mkdir_p raw_dir unless Dir.exists? raw_dir

      basename = File.basename path, '.pdf'
      filename = original_filename.nil? ? basename : File.basename(original_filename)
      pdf = CombinePDF.load path
      num_pages = pdf.pages.length

      # creating an instance of split_pdf_log
      split_pdf_log = SplitPdfLog.create(
        exam_template: exam_template,
        filename: filename,
        original_num_pages: num_pages,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        user: current_user
      )

      progress.total = pdf.pages.length
      partial_exams = Hash.new do |hash, key|
        hash[key] = []
      end
      num_pages_qr_scan_error = 0
      pdf.pages.each_index do |i|
        split_page = SplitPage.create(filename: filename,
                                      raw_page_number: i + 1,
                                      split_pdf_log: split_pdf_log)
        page = pdf.pages[i]
        new_page = CombinePDF.new
        new_page << page
        new_page.save File.join(raw_dir, "#{split_page.id}.pdf")

        # Snip out the part of the PDF that contains the QR code.
        img = Magick::Image::read(File.join(raw_dir, "#{split_page.id}.pdf")).first
        qrcode_regex = /(?<short_id>\w+)-(?<exam_num>\d+)-(?<page_num>\d+)/

        # Snip out the top left corner of PDF that contains the QR code
        top_left_qr_img = img.crop 0, 10, img.columns / 4.5, img.rows / 5.7
        left_qr_code_string = ZXing.decode top_left_qr_img.to_blob
        left_m = qrcode_regex.match left_qr_code_string
        unless left_m.nil?
          m = left_m
          top_left_qr_img.write File.join(raw_dir, "#{split_page.id}.png")
        else # if parsing fails, try the top right corner of the PDF
          top_right_qr_img = img.crop 470, 10, img.columns / 4.5, img.rows / 5.7
          right_qr_code_string = ZXing.decode top_right_qr_img.to_blob
          right_m = qrcode_regex.match right_qr_code_string
          m = right_m
          top_right_qr_img.write File.join(raw_dir, "#{split_page.id}.png")
        end

        status = ''
        if m.nil?
          new_page.save File.join(error_dir, "#{split_page.id}.pdf")
          num_pages_qr_scan_error += 1
          status = 'ERROR: QR code not found'
          m_logger.log(status)
          split_page.update_attributes(status: status)
        else
          group = Group.find_or_create_by(
            group_name: group_name_for(exam_template, m[:exam_num].to_i),
            repo_name: group_name_for(exam_template, m[:exam_num].to_i)
          )
          if m[:short_id] == exam_template.name # if QR code contains corresponding exam template
            partial_exams[m[:exam_num]] << [m[:page_num].to_i, page, i + 1]
            m_logger.log("#{m[:short_id]}: exam number #{m[:exam_num]}, page #{m[:page_num]}")
          else # if QR code doesn't contain corresponding exam template
            new_page.save File.join(error_dir, "#{split_page.id}.pdf")
            status = 'ERROR: QR code does not contain corresponding exam template.'
            m_logger.log(status)
            num_pages_qr_scan_error += 1
          end
          split_page.update_attributes(status: status, group: group, exam_page_number: m[:exam_num].to_i)
        end
        progress.increment
      end
      save_pages(exam_template, partial_exams, filename, split_pdf_log)

      num_groups_in_complete = get_num_groups_in_dir(complete_dir)
      num_groups_in_incomplete = get_num_groups_in_dir(incomplete_dir)
      split_pdf_log.update_attributes(
        num_groups_in_complete: num_groups_in_complete,
        num_groups_in_incomplete: num_groups_in_incomplete,
        num_pages_qr_scan_error: num_pages_qr_scan_error
      )

      return split_pdf_log
    end
     m_logger.log('Split pdf process done')
    rescue => e
      Rails.logger.error e.message
      raise e
  end

  # Save the pages into groups for this assignment
  def save_pages(exam_template, partial_exams, filename=nil, split_pdf_log=nil)
    return unless Admin.exists?
    complete_dir = File.join(exam_template.base_path, 'complete')
    incomplete_dir = File.join(exam_template.base_path, 'incomplete')
    error_dir = File.join(exam_template.base_path, 'error')

    groupings = []
    partial_exams.each do |exam_num, pages|
      next if pages.empty?
      pages.sort_by! { |page_num, _| page_num }

      group = Group.find_by(
        group_name: group_name_for(exam_template, exam_num),
        repo_name: group_name_for(exam_template, exam_num)
      )

      groupings << Grouping.find_or_create_by(
        group: group,
        assignment: exam_template.assignment
      )

      # Save raw pages
      if pages.length == exam_template.num_pages
        destination = File.join complete_dir, "#{exam_num}"
      else
        destination = File.join incomplete_dir, "#{exam_num}"
      end
      FileUtils.mkdir_p destination
      pages.each do |page_num, page, raw_page_num|
        new_pdf = CombinePDF.new
        new_pdf << page
        split_page = SplitPage.find_by(
          filename: filename,
          exam_page_number: exam_num.to_i,
          raw_page_number: raw_page_num,
          group: group,
          split_pdf_log: split_pdf_log
        )
        # if a page already exists, move the page to error directory instead of overwriting it
        if File.exists?(File.join(destination, "#{page_num}.pdf"))
          new_pdf.save File.join(error_dir, "#{split_page.id}.pdf")
          status = "ERROR: #{exam_template.name}: exam number #{exam_num}, page #{page_num} already exists"
        else
          new_pdf.save File.join(destination, "#{page_num}.pdf")
          # set status depending on whether parent directory of destination is complete or incomplete
          status = File.dirname(destination) == complete_dir ? 'Saved to complete directory' : 'Saved to incomplete directory'
        end
        # update status of page
        split_page.update_attributes(status: status)
      end

      group.access_repo do |repo|
        assignment_folder = exam_template.assignment.repository_folder
        txn = repo.get_transaction(Admin.first.user_name)

        # Pages that belong to a division
        exam_template.template_divisions.each do |division|
          new_pdf = CombinePDF.new
          pages.each do |page_num, page|
            if division.start <= page_num && page_num <= division.end
              new_pdf << page
            end
          end
          txn.add(File.join(assignment_folder,
                            "#{division.label}.pdf"),
                  new_pdf.to_pdf,
                  'application/pdf'
          )
        end

        # Pages that don't belong to any division
        extra_pages = pages.reject do |page_num, _|
          exam_template.template_divisions.any? do |division|
            division.start <= page_num && page_num <= division.end
          end
        end
        extra_pages.sort_by! { |page_num, _| page_num }
        extra_pdf = CombinePDF.new
        cover_pdf = CombinePDF.new
        start_page = 0
        if extra_pages[0][0] == 1
          cover_pdf << extra_pages[0][1]
          start_page = 1
        end
        extra_pdf << extra_pages[start_page..extra_pages.size].collect { |_, page| page }
        txn.add(File.join(assignment_folder,
                          "EXTRA.pdf"),
                extra_pdf.to_pdf,
                'application/pdf'
        )
        txn.add(File.join(assignment_folder,
                          "COVER.pdf"),
                cover_pdf.to_pdf,
                'application/pdf'
        )
        repo.commit(txn)
      end
    end
    groupings.each do |grouping|
      grouping.group.access_repo do |repo|
        SubmissionsJob.perform_later([grouping], revision_identifier: repo.get_latest_revision.revision_identifier)
      end
    end
  end

  def group_name_for(exam_template, exam_num)
    "#{exam_template.name}_paper_#{exam_num}"
  end

  def get_num_groups_in_dir(dir)
    num_groups_in_dir = 0
    if Dir.exists?(dir)
      Dir.foreach(dir) do |filename|
        if File.directory?(File.join(dir, filename)) && !filename.start_with?('.')
          num_groups_in_dir += 1
        end
      end
    end
    num_groups_in_dir
  end
end
