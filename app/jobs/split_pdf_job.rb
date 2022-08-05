class SplitPdfJob < ApplicationJob
  def self.on_complete_js(_status)
    'window.location.reload.bind(window.location)'
  end

  def self.show_status(status)
    I18n.t('poll_job.split_pdf_job', progress: status[:progress],
                                     total: status[:total],
                                     exam_name: status[:exam_name])
  end

  before_enqueue do |job|
    status.update(exam_name: "#{job.arguments[0].name} (#{job.arguments[3]})")
  end

  def perform(exam_template, _path, split_pdf_log, _original_filename = nil, _current_role = nil)
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
        imglist = Magick::Image.from_blob(original_pdf) do
          self.quality = 100
          self.density = '83'
        end
        imglist.each do |img|
          # Snip out the top left corner of PDF that contains the QR code
          top_left_qr_img = img.crop 20, 25, img.columns / 3.8, img.rows / 5.0
          top_left_qr_img.write(File.join(raw_dir, "#{split_page.id}.jpg"))
        end
        qrcode_regex = /\A(?<short_id>[\w-]+)-(?<exam_num>\d+)-(?<page_num>\d+)\Z/
        left_qr_code_string = ZXing.decode File.join(raw_dir, "#{split_page.id}.jpg")
        left_m = qrcode_regex.match left_qr_code_string
        if !left_m.nil?
          m = left_m
        else # if parsing fails, try the top right corner of the PDF
          imglist.each do |img|
            # Snip out the top right corner of PDF that contains the QR code
            top_right_qr_img = img.crop 510, 25, img.columns / 3.8, img.rows / 5.0
            top_right_qr_img.write(File.join(raw_dir, "#{split_page.id}.jpg"))
            right_qr_code_string = ZXing.decode File.join(raw_dir, "#{split_page.id}.jpg")
            right_m = qrcode_regex.match right_qr_code_string
            m = right_m
          end
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
      end
      num_complete = save_pages(exam_template, partial_exams, filename, split_pdf_log)
      num_incomplete = partial_exams.length - num_complete

      split_pdf_log.update(
        num_groups_in_complete: num_complete,
        num_groups_in_incomplete: num_incomplete,
        num_pages_qr_scan_error: num_pages_qr_scan_error
      )

      m_logger.log('Split pdf process done')
      split_pdf_log
    rescue StandardError => e
      # Clean tmp folder
      Dir.glob('/tmp/magick-*').each { |file| File.delete(file) }
      raise e
    end
  end

  # Save the pages into groups for this assignment
  def save_pages(exam_template, partial_exams, filename = nil, split_pdf_log = nil)
    return unless exam_template.course.instructors.exists?
    complete_dir = File.join(exam_template.base_path, 'complete')
    incomplete_dir = File.join(exam_template.base_path, 'incomplete')
    error_dir = File.join(exam_template.base_path, 'error')
    raw_dir = File.join(exam_template.base_path, 'raw')

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

      # Save raw pages
      if pages.length == exam_template.num_pages
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
        # if a page already exists, move the page to error directory instead of overwriting it
        if File.exist?(File.join(destination, "#{page_num}.pdf"))
          new_pdf.save File.join(error_dir, "#{split_page.id}.pdf")
          status = "ERROR: #{exam_template.name}: exam number #{exam_num}, page #{page_num} already exists"
        else
          new_pdf.save File.join(destination, "#{page_num}.pdf")
          # set status depending on whether parent directory of destination is complete or incomplete
          if File.dirname(destination) == complete_dir
            status = 'Saved to complete directory'
          else
            status = 'Saved to incomplete directory'
          end
        end
        # update status of page
        split_page.update(status: status)
      end

      grouping.access_repo do |repo|
        assignment_folder = exam_template.assignment.repository_folder
        txn = repo.get_transaction(exam_template.course.instructors.first.user_name)

        # Pages that belong to a division
        exam_template.template_divisions.each do |division|
          new_pdf = CombinePDF.new
          pages.each do |page_num, page|
            if division.start <= page_num && page_num <= division.end
              new_pdf << page
            end
          end
          if File.exist? File.join(assignment_folder, "#{division.label}.pdf")
            txn.replace(File.join(assignment_folder,
                                  "#{division.label}.pdf"),
                        new_pdf.to_pdf,
                        'application/pdf')
          else
            txn.add(File.join(assignment_folder,
                              "#{division.label}.pdf"),
                    new_pdf.to_pdf,
                    'application/pdf')
          end
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
        if !extra_pages.empty? && extra_pages[0][0] == 1
          cover_pdf << extra_pages[0][1]
          start_page = 1
        end
        extra_pdf << extra_pages[start_page..extra_pages.size].collect { |_, page| page }

        if File.exist? File.join(assignment_folder, 'EXTRA.pdf')
          txn.replace(File.join(assignment_folder,
                                'EXTRA.pdf'),
                      extra_pdf.to_pdf,
                      'application/pdf')
        else
          txn.add(File.join(assignment_folder,
                            'EXTRA.pdf'),
                  extra_pdf.to_pdf,
                  'application/pdf')
        end

        if File.exist? File.join(assignment_folder, 'COVER.pdf')
          txn.replace(File.join(assignment_folder,
                                'COVER.pdf'),
                      cover_pdf.to_pdf,
                      'application/pdf')
        else
          txn.add(File.join(assignment_folder,
                            'COVER.pdf'),
                  cover_pdf.to_pdf,
                  'application/pdf')
        end
        repo.commit(txn)

        next unless exam_template.automatic_parsing
        begin
          # convert PDF to an image
          imglist = Magick::Image.from_blob(cover_pdf.to_pdf) do
            self.quality = 100
            self.density = '300'
          end
        rescue StandardError
          next
        end

        img = imglist.first
        # Snip out the middle of PDF that contains the student information
        student_info = img.crop exam_template.crop_x * img.columns, exam_template.crop_y * img.rows,
                                exam_template.crop_width * img.columns, exam_template.crop_height * img.rows
        student_info_file = File.join(raw_dir, "#{grouping.id}_info.jpg")
        student_info.write(student_info_file)

        python_exe = File.join(Settings.python.bin, 'python')
        read_chars_py_file = File.join(::Rails.root, 'lib', 'scanner', 'read_chars.py')
        stdout, status = Open3.capture2(python_exe, read_chars_py_file, student_info_file)
        next unless status.success?

        student = match_student(stdout.strip.split("\n"), exam_template)

        unless student.nil?
          StudentMembership.find_or_create_by(role: student,
                                              grouping: grouping,
                                              membership_status: StudentMembership::STATUSES[:inviter])
        end
      end
    end
    num_complete
  end

  # Determine a match using the parsed handwritten text and the user identifying field (+exam_template.cover_fields+).
  # If the parsing was successful, +parsed+ is a list of two strings parsed from the handwritten text:
  # the first is the result of attempting to parse alphabetic characters, and the second is the result of
  # attempting to parse numeric digits.
  def match_student(parsed, exam_template)
    return if parsed.size < 2

    case exam_template.cover_fields
    when 'id_number'
      Student.joins(:user).find_by('user.id_number': parsed[1])
    when 'user_name'
      Student.joins(:user).find_by(User.arel_table[:user_name].matches(parsed[0]))
    end
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
