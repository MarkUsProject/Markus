# Copy all collected submissions from this MarkUs instance to the +target_dir+
# organized by assignment and grouping. If a relative_url_root is set for this instance
# the files will be copied into +target_dir+/relative_url_root, otherwise they will be
# put directly into the +target_dir+.
#
# Group names are anonymized by naming each group directory as "group" plus integers in
# ascending order.
#
# Example usage:
#   (relative_url_root is "/markus_instance" for this example)
#
#   $ bundle exec rails markus:archive_submissions[/home/userA/markus_archive]
#
#   This will create the following tree structure:
#
#   /home/userA/markus_archive/markus_instance
#   └── A0
#       ├── group0
#       │   ├── file1.py
#       │   └── some_inner_dir
#       │       ├── file2.py
#       │       └── file3.py
#       ├── group1
#       │   ├── file1.py
#       │   └── some_inner_dir
#       │       ├── file2.py
#       │       └── file3.py
#       └── group2
#           ├── file1.py
#           └── some_inner_dir
#               ├── file2.py
#               └── file3.py

namespace :markus do
  task :archive_submissions, [:target_dir] => :environment  do |_task, args|
    target_dir = Pathname.new(args[:target_dir])
    raise "Directory #{target_dir} does not exist" unless Dir.exist?(target_dir)

    relative_root = Rails.application.config.action_controller.relative_url_root
    if relative_root
      target_dir += relative_root
      FileUtils.makedirs target_dir
    end

    total_files = Grouping.joins(current_submission_used: :submission_files).count
    processed_files = 0
    print "\r"

    Assignment.all.pluck(:id, :short_identifier).each do |aid, short_id|
      short_id_dir = Pathname.new(short_id)
      assignment_dir = target_dir + short_id_dir
      FileUtils.makedirs(assignment_dir)
      Grouping.where(assignment_id: aid).find_each.with_index do |grouping, i|
        submission = grouping.current_submission_used
        next unless submission

        group_dir = assignment_dir + "group#{i}"
        FileUtils.makedirs(group_dir)

        submission.submission_files.each do |file|
          file_content = file.retrieve_file
          rel_path = Pathname.new(file.path).relative_path_from(short_id_dir)
          file_dir = group_dir + rel_path
          FileUtils.makedirs(file_dir)
          mode = SubmissionFile.is_binary?(file_content) ? 'wb' : 'w'
          File.write(file_dir + file.filename, file_content, mode: mode)
          processed_files += 1
          print "written #{processed_files}/#{total_files} files\r"
          $stdout.flush
        end
      end
    end
    puts "\nfinished"
  end
end
