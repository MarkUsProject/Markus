class MatchStudentJob < ApplicationJob
  def perform(groupings, exam_template)
    return unless exam_template.automatic_parsing && Rails.application.config.scanner_enabled
    groupings.each do |grouping|
      begin
        # convert PDF to an image
        imglist = Magick::Image.from_blob(cover_pdf.to_pdf) do |options|
          options.quality = 100
          options.density = '300'
        end
      rescue StandardError
        return
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
      stdout, status = Open3.capture2(python_exe, '-m', 'markus_exam_matcher', student_info_file, char_type)
      parsed = stdout.strip.split("\n")

      next unless status.success? && parsed.length == 1

      student = match_student(parsed[0], exam_template)

      unless student.nil?
        StudentMembership.find_or_create_by(role: student,
                                            grouping: grouping,
                                            membership_status: StudentMembership::STATUSES[:inviter])
      end
    end
  end

  # Determine a match using the parsed handwritten text and the user identifying field (+exam_template.cover_fields+).
  # If the parsing was successful, +parsed+ is a string parsed from the handwritten text: if
  # +exam_template.cover_fields+ is 'id_number', it is the result of attempting to parse numeric digits, and if
  # +exam_template.cover_fields+ is 'user_name', it is the result of attempting to parse alphanumeric characters.
  def match_student(parsed, exam_template)
    case exam_template.cover_fields
    when 'id_number'
      Student.joins(:user).find_by('user.id_number': parsed)
    when 'user_name'
      Student.joins(:user).find_by(User.arel_table[:user_name].matches(parsed))
    end
  end
end
