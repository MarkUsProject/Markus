namespace :db do

  desc 'Create groups for assignments'
  task :groups => :environment do
    puts 'Assign Groups/Students for Assignments'
    students = Student.all
    Assignment.all.each do |assignment|
      num_groups = (assignment.short_identifier == 'A1' && ENV['A1_GROUP_AMOUNT']) ? ENV['A1_GROUP_AMOUNT'].to_i : 15
      puts "Populating #{assignment.short_identifier} with #{num_groups} groups"
      num_groups.times do |time|
        student = students[time]
        if assignment.short_identifier == 'A1' || assignment.short_identifier == 'A3'
          group = Group.create(
            group_name: "#{ student.user_name } #{ assignment.short_identifier }"
            )
          grouping = Grouping.create(
            group: group,
            assignment: assignment
            )
          grouping.invite([student.user_name],
            StudentMembership::STATUSES[:inviter],
            invoked_by_admin=true,
            update_permissions=false)
        elsif assignment.short_identifier == 'A2' || assignment.short_identifier == 'A4'
          group = Group.create(
            group_name: "#{ student.user_name } #{ assignment.short_identifier }"
            )
          grouping = Grouping.create(
            group: group,
            assignment: assignment
            )
          (0..1).each do |count|
            grouping.invite(
              [students[time + count * 15].user_name],
              StudentMembership::STATUSES[:inviter],
              invoked_by_admin=true,
              update_permissions=false)
          end
        end

        group.access_repo do |repo|
          txn = repo.get_transaction(group.grouping_for_assignment(assignment.id).inviter.user_name)
          #add files to the root folder of the repo (e.g. "A1")
          file_dir  = File.join(File.dirname(__FILE__), '/../../db/data')
          Dir.foreach(file_dir) do |filename|
            unless File.directory?(File.join(file_dir, filename))
              file_contents = File.open(File.join(file_dir, filename))
              file_contents.rewind
              path = File.join(assignment.repository_folder, filename)
              txn.add(path, file_contents.read, '')
            end
          end

          #create subdirectories in the repos
          path_a = File.join(assignment.repository_folder, 'a')
          txn.add_path(path_a)
          path_b = File.join(path_a, 'b')
          txn.add_path(path_b)
          path_c = File.join(path_a, 'c')
          txn.add_path(path_c)
          path_d = File.join(path_c, 'd')
          txn.add_path(path_d)
          path_e = File.join(assignment.repository_folder, 'e')
          txn.add_path(path_e)
          path_f = File.join(path_e, 'f')
          txn.add_path(path_f)

          #the files in "test-files-in-inner-dirs" folder are used to populate the subdirectories in the repos
          file_dir  = File.join(File.dirname(__FILE__), '/../../db/data/test-files-in-inner-dirs')
          subdirs_to_contents = {
              'a' => ['1.py', '2.py'],
              'a/b' => ['3.py'],
              'a/c' => ['4.py'],
              'a/c/d' => ['5.py', '6.py'],
              'e' => ['7.py'],
              'e/f'=> ['8.py', '9.py', '10.py']
          }

          subdirs_to_contents.each do |subdir, filenames|
            filenames.each do |filename|
              file_contents = File.open(File.join(file_dir, filename))
              file_contents.rewind
              path = File.join(File.join(assignment.repository_folder, subdir), filename)
              txn.add(path, file_contents.read, '')
            end
          end
          repo.commit(txn)
        end
      end
    end
    # This really should be done in a more generic way
    repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type)
    repo.__set_all_permissions
  end
end
