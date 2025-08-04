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

      if enqueuing_user
        ExamTemplatesChannel.broadcast_to(enqueuing_user, {
          status: 'in_progress',
          job_class: 'SplitPdfJob',
          exam_name: exam_template.name,
          message: I18n.t('exam_templates.split_pdf_log.qr_scan_in_progress')
        })
      end

      # First, save each PDF file
      split_pages_to_insert = Array.new(pdf.pages.length) do |i|
        { filename: filename, split_pdf_log_id: split_pdf_log.id, raw_page_number: i + 1 }
      end
      split_page_ids = SplitPage.insert_all(split_pages_to_insert).pluck('id')

      split_pages = []
      pdf.pages.each_index do |i|
        page = pdf.pages[i]
        new_page = CombinePDF.new
        new_page << page
        new_page.save File.join(raw_dir, "#{split_page_ids[i]}.pdf")
        split_pages << new_page
      end

      # Then, run the QR code scanner
      python_exe = Rails.application.config.python
      stdin_data = split_page_ids.map { |id| "#{id}.pdf" }.join("\n")
      stdout, stderr, status = Open3.capture3(
        python_exe,
        '-m',
        'markus_exam_matcher',
        '--bulk',
        'qr',
        raw_dir,
        stdin_data: stdin_data
      )
      qr_scan_results = {}
      if status.success?
        csv = CSV.parse(stdout, headers: false)
        csv.each do |row|
          next if row.empty?
          qr_scan_results[row[0]] = row.length >= 2 ? row[1] : ''
        end
      else
        raise "Error running markus-exam-matcher. Details:\n#{stdout}\n#{stderr}"
      end

      # Parse QR scan results and attempt OCR if QR parsing failed
      matches = {}
      pdf.pages.each_index do |i|
        split_page_id = split_page_ids[i]

        code_regex = /(?<short_id>[\w-]+)-(?<exam_num>\d+)-(?<page_num>\d+)/
        match_text = qr_scan_results["#{split_page_id}.pdf"] || ''
        if match_text.present?
          matches[i] = code_regex.match(match_text)
        else
          # convert PDF to an image
          new_page = split_pages[i]
          img = Magick::Image.from_blob(new_page.to_pdf) do |options|
            options.quality = 100
            options.density = '200'
          end.first

          qr_file_location = File.join(raw_dir, "#{split_page_id}.jpg")
          img.crop(Magick::NorthWestGravity, img.columns, img.rows / 5.0).write(qr_file_location)
          img.destroy!
          matches[i] = code_regex.match(RTesseract.new(qr_file_location).to_s)
        end
      end

      if enqueuing_user
        ExamTemplatesChannel.broadcast_to(enqueuing_user, {
          status: 'in_progress',
          job_class: 'SplitPdfJob',
          exam_name: exam_template.name,
          message: I18n.t('exam_templates.split_pdf_log.submission_in_progress')
        })
      end

      # Create group and grouping objects (done in bulk)
      assignment = exam_template.assignment
      groups_to_upsert = {}
      matches.each_value do |match|
        next if match.nil? || match[:short_id] != exam_template.name

        group_name = group_name_for(exam_template, match[:exam_num].to_i)
        groups_to_upsert[match[:exam_num]] = {
          group_name: group_name,
          repo_name: group_name,
          course_id: assignment.course_id
        }
      end
      group_data = Group.upsert_all(groups_to_upsert.values,
                                    returning: [:group_name, :id],
                                    unique_by: %i[group_name course_id])
      group_data = group_data.map { |x| [x['group_name'], x['id']] }.to_h
      groupings_to_upsert = group_data.map { |_, group_id| { group_id: group_id, assessment_id: assignment.id } }
      Grouping.upsert_all(groupings_to_upsert, returning: false, unique_by: %i[group_id assessment_id])

      # Get all groupings associated with this assignment.
      # The Grouping.upsert_all query above does not return any grouping ids if the groupings already exist.
      groupings_by_id = assignment.groupings.includes(:group).index_by(&:group_id)
      @group_name_to_groupings = group_data.transform_values { |group_id| groupings_by_id[group_id] }

      partial_exams = Hash.new do |hash, key|
        hash[key] = []
      end
      num_pages_qr_scan_error = 0
      split_page_updates = []
      pdf.pages.each_index do |i|
        split_page_id = split_page_ids[i]
        new_page = split_pages[i]
        page = pdf.pages[i]

        m = matches[i]
        status = ''

        if m.nil?
          new_page.save File.join(error_dir, "#{split_page_id}.pdf")
          num_pages_qr_scan_error += 1
          status = 'ERROR: QR code not found'
          m_logger.log(status)
          split_page_updates << {
            id: split_page_id,
            status: status,
            group_id: nil,
            exam_page_number: nil
          }
        elsif m[:short_id] != exam_template.name  # if QR code doesn't contain corresponding exam template
          new_page.save File.join(error_dir, "#{split_page_id}.pdf")
          num_pages_qr_scan_error += 1
          status = "ERROR: QR code does not contain corresponding exam template (got #{m[:short_id]})."
          m_logger.log(status)
          split_page_updates << {
            id: split_page_id,
            status: status,
            group_id: nil,
            exam_page_number: nil
          }
        else
          group_id = group_data[group_name_for(exam_template, m[:exam_num].to_i)]
          partial_exams[m[:exam_num]] << [m[:page_num].to_i, page, split_page_id]
          m_logger.log("#{m[:short_id]}: exam number #{m[:exam_num]}, page #{m[:page_num]}")
          split_page_updates << {
            id: split_page_id,
            status: status,
            group_id: group_id,
            exam_page_number: m[:page_num].to_i
          }
        end
      end
      SplitPage.upsert_all(split_page_updates, returning: false)
      num_complete = save_pages(exam_template, partial_exams, on_duplicate)
      num_incomplete = partial_exams.length - num_complete

      split_pdf_log.update(
        num_groups_in_complete: num_complete,
        num_groups_in_incomplete: num_incomplete,
        num_pages_qr_scan_error: num_pages_qr_scan_error
      )

      # Run Grouping callback that was skipped in the Grouping.upsert_all call
      assignment.groupings.first&.update_repo_permissions_after_save

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
          job_class: 'SplitPdfJob',
          exam_name: exam_template.name,
          exception: e.message
        })
      end
      raise e
    end
  end

  # Save the pages into groups for this assignment
  def save_pages(exam_template, partial_exams, on_duplicate = nil)
    complete_dir = File.join(exam_template.base_path, 'complete')
    incomplete_dir = File.join(exam_template.base_path, 'incomplete')
    error_dir = File.join(exam_template.base_path, 'error')

    groupings = []
    num_complete = 0
    partial_exams.each do |exam_num, pages|
      next if pages.empty?
      pages.sort_by! { |page_num, _| page_num }

      grouping = @group_name_to_groupings[group_name_for(exam_template, exam_num)]
      groupings << grouping

      # Save raw pages.
      if File.exist?(File.join(complete_dir, exam_num.to_s)) || pages.length == exam_template.num_pages
        destination = File.join complete_dir, exam_num.to_s
        num_complete += 1
      else
        destination = File.join incomplete_dir, exam_num.to_s
      end
      FileUtils.mkdir_p destination
      split_page_updates = []
      pages.each do |page_num, page, split_page_id|
        new_pdf = CombinePDF.new
        new_pdf << page

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
          new_pdf.save File.join(error_dir, "#{split_page_id}.pdf")
          status = "ERROR: #{exam_template.name}: exam number #{exam_num}, page #{page_num} already exists"
        end
        # update status of page
        split_page_updates << { id: split_page_id, status: status }
      end
      SplitPage.upsert_all(split_page_updates, returning: false)

      # Get all pages in the destination. This lets us combine newly-scanned pages with
      # any pages for this group that were previously scanned.
      destination_pages = Dir.glob(File.join(destination, '*.pdf')).map do |path|
        [Integer(File.basename(path, '.pdf')), CombinePDF.load(path)]
      end

      group = grouping.group
      group.build_repository unless Repository.get_class.repository_exists?(group.repo_path)
      grouping.access_repo do |repo|
        assignment_folder = exam_template.assignment.repository_folder
        txn = repo.get_transaction('MarkUs')

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
        repo.reload_non_bare_repo  # Unclear why, but this is needed to prevent a "bare index" error for new groups
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
