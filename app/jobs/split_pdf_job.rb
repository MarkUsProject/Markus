class SplitPdfJob < ApplicationJob
  def perform(exam_template, _path, split_pdf_log, _original_filename = nil, _role = nil,
              on_duplicate = nil, enqueuing_user = nil)
    m_logger = MarkusLogger.instance
    begin
      # Create directory for files whose QR code couldn't be parsed
      error_dir = File.join(exam_template.base_path, 'error')
      raw_dir = File.join(exam_template.base_path, 'raw')
      FileUtils.mkdir_p error_dir
      FileUtils.mkdir_p raw_dir

      filename = split_pdf_log.filename

      pdf = CombinePDF.load File.join(raw_dir, "raw_upload_#{split_pdf_log.id}.pdf")
      num_pages = pdf.pages.length
      progress.total = num_pages
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
        original_pdf = File.binread(File.join(raw_dir, "#{split_page.id}.pdf"))

        # convert PDF to an image
        img = Magick::Image.from_blob(original_pdf) do |options|
          options.quality = 100
          options.density = '200'
        end.first

        qr_file_location = File.join(raw_dir, "#{split_page.id}.jpg")
        img.crop(Magick::NorthWestGravity, img.columns, img.rows / 5.0).write(qr_file_location)
        img.destroy!
        code_regex = /(?<short_id>[\w-]+)-(?<exam_num>\d+)-(?<page_num>\d+)/
        python_exe = Rails.application.config.python
        stdout, status = Open3.capture2(python_exe, '-m', 'markus_exam_matcher', 'qr', qr_file_location)
        if status.success?
          m = code_regex.match(stdout)
        else
          m = code_regex.match(RTesseract.new(qr_file_location).to_s)
        end
        status = ''

        if m.nil?
          new_page.save File.join(error_dir, "#{split_page.id}.pdf")
          num_pages_qr_scan_error += 1
          status = 'ERROR: QR code not found'
          m_logger.log(status)
          split_page.update(status: status)
        else
          group = Group.find_or_create_by(
            group_name: group_name_for(exam_template, m[:exam_num].to_i),
            repo_name: group_name_for(exam_template, m[:exam_num].to_i),
            course: exam_template.course
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
          split_page.update(status: status, group: group, exam_page_number: m[:page_num].to_i)
        end
        progress.increment

        # Broadcast job progress
        if enqueuing_user
          ExamTemplatesChannel.broadcast_to(enqueuing_user, { status: 'in_progress',
                                                              job_class: 'SplitPdfJob',
                                                              exam_name: exam_template.name,
                                                              page_number: progress.progress,
                                                              total_pages: progress.total })
        end
      end
      num_complete = save_pages(exam_template, partial_exams, filename, split_pdf_log, on_duplicate)
      num_incomplete = partial_exams.length - num_complete

      split_pdf_log.update(
        num_groups_in_complete: num_complete,
        num_groups_in_incomplete: num_incomplete,
        num_pages_qr_scan_error: num_pages_qr_scan_error
      )

      m_logger.log('Split pdf process done')
      # Broadcast job completion
      if enqueuing_user
        ExamTemplatesChannel.broadcast_to(enqueuing_user, { status: 'completed',
                                                            job_class: 'SplitPdfJob',
                                                            exam_name: exam_template.name })
      end
      split_pdf_log
    rescue StandardError => e
      # Clean tmp folder
      Dir.glob('/tmp/magick-*').each { |file| File.delete(file) }
      # Broadcast job error
      if enqueuing_user
        ExamTemplatesChannel.broadcast_to(enqueuing_user, {
          status: 'failed',
          job_class: 'SplifPdfJob',
          exam_name: exam_template.name,
          exception: e.message
        })
      end
      raise e
    end
  end

  # Save the pages into groups for this assignment
  def save_pages(exam_template, partial_exams, filename = nil, split_pdf_log = nil, on_duplicate = nil)
    return unless exam_template.course.instructors.exists?
    complete_dir = File.join(exam_template.base_path, 'complete')
    incomplete_dir = File.join(exam_template.base_path, 'incomplete')
    error_dir = File.join(exam_template.base_path, 'error')

    groupings = []
    num_complete = 0
    partial_exams.each do |exam_num, pages|
      next if pages.empty?
      pages.sort_by! { |page_num, _| page_num }

      group = Group.find_by(
        group_name: group_name_for(exam_template, exam_num),
        repo_name: group_name_for(exam_template, exam_num),
        course: exam_template.course
      )

      grouping = Grouping.find_or_create_by(
        group: group,
        assignment: exam_template.assignment
      )
      groupings << grouping

      # Save raw pages.
      if File.exist?(File.join(complete_dir, exam_num.to_s)) || pages.length == exam_template.num_pages
        destination = File.join complete_dir, exam_num.to_s
        num_complete += 1
      else
        destination = File.join incomplete_dir, exam_num.to_s
      end
      FileUtils.mkdir_p destination
      pages.each do |page_num, page, raw_page_num|
        new_pdf = CombinePDF.new
        new_pdf << page
        split_page = SplitPage.find_by(
          filename: filename,
          exam_page_number: page_num.to_i,
          raw_page_number: raw_page_num,
          group: group,
          split_pdf_log: split_pdf_log
        )
        if !File.exist?(File.join(destination, "#{page_num}.pdf")) || on_duplicate == 'overwrite'
          # if the page already exists and on_duplicate == 'overwrite', overwrite the page,
          # and indicate in page status
          status = File.exist?(File.join(destination, "#{page_num}.pdf")) ? '(Overwritten) ' : ''
          new_pdf.save File.join(destination, "#{page_num}.pdf")

          # set status depending on whether parent directory of destination is complete or incomplete
          if File.dirname(destination) == complete_dir
            status += 'Saved to complete directory'
          else
            status += 'Saved to incomplete directory'
          end
        elsif File.exist?(File.join(destination, "#{page_num}.pdf")) && on_duplicate == 'ignore'
          # if the page already exists and on_duplicate == 'ignore', ignore the page
          status = 'Duplicate page ignored'
        else
          # if the page already exists and on_duplicate is anything else, move the page to error directory
          new_pdf.save File.join(error_dir, "#{split_page.id}.pdf")
          status = "ERROR: #{exam_template.name}: exam number #{exam_num}, page #{page_num} already exists"
        end
        # update status of page
        split_page.update(status: status)
      end

      # Get all pages in the destination. This lets us combine newly-scanned pages with
      # any pages for this group that were previously scanned.
      destination_pages = Dir.glob(File.join(destination, '*.pdf')).map do |path|
        [Integer(File.basename(path, '.pdf')), CombinePDF.load(path)]
      end

      grouping.access_repo do |repo|
        assignment_folder = exam_template.assignment.repository_folder
        txn = repo.get_transaction(exam_template.course.instructors.first.user_name)

        revision = repo.get_latest_revision
        # Pages that belong to a division
        exam_template.template_divisions.each do |division|
          new_pdf = CombinePDF.new
          destination_pages.each do |page_num, page|
            if page_num.between?(division.start, division.end)
              new_pdf << page
            end
          end
          if revision.path_exists? File.join(assignment_folder, "#{division.label}.pdf")
            txn.replace(File.join(assignment_folder,
                                  "#{division.label}.pdf"),
                        new_pdf.to_pdf,
                        'application/pdf',
                        revision.revision_identifier)
          else
            txn.add(File.join(assignment_folder,
                              "#{division.label}.pdf"),
                    new_pdf.to_pdf,
                    'application/pdf')
          end
        end

        # Pages that don't belong to any division
        extra_pages = destination_pages.reject do |page_num, _|
          exam_template.template_divisions.any? do |division|
            page_num.between?(division.start, division.end)
          end
        end
        extra_pages.sort_by! { |page_num, _| page_num }
        extra_pdf = CombinePDF.new
        cover_pdf = CombinePDF.new
        start_page = 0
        if !extra_pages.empty? && extra_pages[0][0] == 1
          cover_pdf << extra_pages[0][1]
          start_page = 1
        end
        extra_pages[start_page..extra_pages.size].each do |(_, pdf)|
          extra_pdf << pdf
        end

        if revision.path_exists? File.join(assignment_folder, 'EXTRA.pdf')
          txn.replace(File.join(assignment_folder,
                                'EXTRA.pdf'),
                      extra_pdf.to_pdf,
                      'application/pdf',
                      revision.revision_identifier)
        else
          txn.add(File.join(assignment_folder,
                            'EXTRA.pdf'),
                  extra_pdf.to_pdf,
                  'application/pdf')
        end

        if revision.path_exists? File.join(assignment_folder, 'COVER.pdf')
          txn.replace(File.join(assignment_folder,
                                'COVER.pdf'),
                      cover_pdf.to_pdf,
                      'application/pdf',
                      revision.revision_identifier)
        else
          txn.add(File.join(assignment_folder,
                            'COVER.pdf'),
                  cover_pdf.to_pdf,
                  'application/pdf')
        end
        repo.commit(txn)
      end
    end
    num_complete
  end

  def group_name_for(exam_template, exam_num)
    "#{exam_template.name}_paper_#{exam_num}"
  end

  def get_num_groups_in_dir(dir)
    num_groups_in_dir = 0
    if Dir.exist?(dir)
      Dir.foreach(dir) do |filename|
        if File.directory?(File.join(dir, filename)) && !filename.start_with?('.')
          num_groups_in_dir += 1
        end
      end
    end
    num_groups_in_dir
  end
end
