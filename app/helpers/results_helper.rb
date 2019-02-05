module ResultsHelper

  def remark_result_unsubmitted_or_released(remark_result)
    remark_result.marking_state == Result::MARKING_STATES[:incomplete] ||
      remark_result.released_to_students
  end

  def student_can_edit_remark_request(submission)
    !submission.remark_result ||
      submission.remark_result.marking_state ==
        Result::MARKING_STATES[:incomplete]
  end

  def can_show_feedback_files_tab?(submission)
    not submission.feedback_files.empty?
  end

  def create_nested_files_hash_table(files)
    # arrange the files list into a nested hashtable for displaying in a recursive menu
    outermost_dir = Hash.new
    files.each do |file|
      innermost_dir = outermost_dir
      innermost_dir[:files] = Array.new
      folders = file.path.split('/')
      folders.each do |folder_name|
        unless innermost_dir.key?(folder_name)
          innermost_dir[folder_name] = Hash.new
          innermost_dir[folder_name][:files] = Array.new
        end
        innermost_dir = innermost_dir[folder_name]
      end
      innermost_dir[:files].push(file)
    end
    outermost_dir
  end
end
