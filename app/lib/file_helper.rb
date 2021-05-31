module FileHelper
  def sanitize_file_name(file_name)
    # If file_name is blank, return the empty string
    return '' if file_name.nil?
    File.basename(file_name).gsub(
      SubmissionFile::FILENAME_SANITIZATION_REGEXP,
      SubmissionFile::SUBSTITUTION_CHAR)
  end
end
