class AutoMatchJob < ApplicationJob
  def self.on_complete_js(_status)
    '() => {window.groupsManager && window.groupsManager.current.fetchData()}'
  end

  def self.show_status(status)
    I18n.t('poll_job.auto_match_job', progress: status[:progress], total: status[:total])
  end

  def perform(groupings, exam_template)
    return unless exam_template.automatic_parsing && Rails.application.config.scanner_enabled
    progress.total = groupings.length
    raw_dir = File.join(exam_template.base_path, 'raw')

    groupings.each do |grouping|
      # get cover page
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        cover_pdf_raw = repo.download_as_string(
          revision.files_at_path(exam_template.assignment.repository_folder)['COVER.pdf']
        )
        cover_pdf = CombinePDF.parse(cover_pdf_raw)

        begin
          # convert PDF to an image
          imglist = Magick::Image.from_blob(cover_pdf.to_pdf) do |options|
            options.quality = 100
            options.density = '300'
          end
        rescue StandardError
          progress.increment
          next
        end

        img = imglist.first
        # Snip out the middle of PDF that contains the student information
        student_info = img.crop exam_template.crop_x * img.columns, exam_template.crop_y * img.rows,
                                exam_template.crop_width * img.columns, exam_template.crop_height * img.rows
        student_info_file = File.join(raw_dir, "#{grouping.id}_info.jpg")
        student_info.write(student_info_file)
        img.destroy!
        student_info.destroy!

        python_exe = Rails.application.config.python
        char_type = exam_template.cover_fields == 'id_number' ? 'digit' : 'letter'
        stdout, status = Open3.capture2(python_exe, '-m', 'markus_exam_matcher', 'char', student_info_file,
                                        '--char_type', char_type)
        parsed = stdout.strip.split("\n")

        next unless status.success? && parsed.length == 1

        student = match_student(parsed[0], exam_template)

        # Store OCR match result in Redis for later suggestions
        OcrMatchService.store_match(
          grouping.id,
          parsed[0],
          exam_template.cover_fields,
          matched: !student.nil?,
          student_id: student&.id
        )

        unless student.nil?
          StudentMembership.find_or_create_by(role: student,
                                              grouping: grouping,
                                              membership_status: StudentMembership::STATUSES[:inviter])
        end
      end
      progress.increment
    end
  end

  # Determine a match using the parsed handwritten text and the user identifying field (+exam_template.cover_fields+).
  # If the parsing was successful, +parsed+ is a string parsed from the handwritten text: if
  # +exam_template.cover_fields+ is 'id_number', it is the result of attempting to parse numeric digits, and if
  # +exam_template.cover_fields+ is 'user_name', it is the result of attempting to parse alphanumeric characters.
  def match_student(parsed, exam_template)
    case exam_template.cover_fields
    when 'id_number'
      Student.joins(:user).find_by('users.id_number': parsed)
    when 'user_name'
      Student.joins(:user).find_by(User.arel_table[:user_name].matches(parsed))
    end
  end
end
