# Copy all collected submissions from this MarkUs instance to the +target_dir+
# organized by assignment and grouping. If a relative_url_root is set for this instance
# the files will be copied into +target_dir+/relative_url_root, otherwise they will be
# put directly into the +target_dir+.
#
# Group names are anonymized by naming each group directory as "group" plus integers in
# ascending order. A file named group_memberships.csv will be written to the top level
# directory which will contain a mapping of group directory names to student usernames.
# For example:
#
# group0,student1,student2
# group1,student3,
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
  task :archive_submissions, [:target_dir] => :environment do |_task, args|
    target_dir = Pathname.new(args[:target_dir])
    raise "Directory #{target_dir} does not exist" unless Dir.exist?(target_dir)

    relative_root = Rails.application.config.relative_url_root
    if relative_root
      target_dir += relative_root
      FileUtils.makedirs target_dir
    end

    total_groupings = Grouping.joins(current_submission_used: :submission_files).uniq.count
    processed_groupings = 0
    print "\r"
    CSV.open(target_dir + 'group_memberships.csv', 'w') do |csv|
      Assignment.where(parent_assessment_id: nil).pluck(:id, :short_identifier).each do |aid, short_id|
        short_id_dir = Pathname.new(short_id)
        assignment_dir = target_dir + short_id_dir
        FileUtils.makedirs(assignment_dir)
        Grouping.where(assessment_id: aid)
                .includes(current_submission_used: :submission_files)
                .find_each.with_index do |grouping, i|
          submission = grouping.current_submission_used
          next unless submission
          next unless submission.submission_files

          group_dir = assignment_dir + "group#{i}"
          csv << [group_dir.relative_path_from(target_dir).to_s, *grouping.accepted_students.pluck(:user_name)]
          FileUtils.makedirs(group_dir)

          submission.submission_files.each do |file|
            file_content = file.retrieve_file
            rel_path = Pathname.new(file.path).relative_path_from(short_id_dir)
            file_dir = group_dir + rel_path
            FileUtils.makedirs(file_dir)
            mode = SubmissionFile.is_binary?(file_content) ? 'wb' : 'w'
            File.write(file_dir + file.filename, file_content, mode: mode)
          end
          processed_groupings += 1
          print "archived files for #{processed_groupings}/#{total_groupings} groupings\r"
          $stdout.flush
        end
      end
    end
    puts "\nfinished"
  end
end
