namespace :db do
  
  desc 'Create groups for assignments'
  task :groups => :environment do
    puts 'Assign Groups/Students for Assignments'
    students = Student.all
    Assignment.all.each do |assignment|
      15.times do |time|
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
                          invoked_by_admin=true)
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
              invoked_by_admin = true)
          end
          group.set_repo_permissions
        end

        file_dir  = File.join(File.dirname(__FILE__), '/../../db/data')
        Dir.foreach(file_dir) do |filename|
          unless File.directory?(File.join(file_dir, filename))
            file_contents = File.open(File.join(file_dir, filename))
            file_contents.rewind
            group.access_repo do |repo|
              txn = repo.get_transaction(group.grouping_for_assignment(assignment.id).inviter.user_name)
              path = File.join(assignment.repository_folder, filename)
              txn.add(path, file_contents.read, '')
              repo.commit(txn)
            end
          end


        end

        #add extra files here

        group.access_repo do |repo|
          txn = repo.get_transaction(group.grouping_for_assignment(assignment.id).inviter.user_name)
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
          repo.commit(txn)
        end

        file_dir  = File.join(File.dirname(__FILE__), '/../../db/data/test-files-in-inner-dirs')
        inner_repo_dirs = ['a', 'a/b', 'a/c', 'a/c/d', 'e', 'e/f']
        Dir.foreach(file_dir) do |filename|
          unless File.directory?(File.join(file_dir, filename))

            file_contents = File.open(File.join(file_dir, filename))
            file_contents.rewind

            inner_repo_dirs.each do |inner_repo_dir|
              group.access_repo do |repo|
                txn = repo.get_transaction(group.grouping_for_assignment(assignment.id).inviter.user_name)
                path = File.join(File.join(assignment.repository_folder, inner_repo_dir), filename)
                txn.add(path, file_contents.read, '')
                repo.commit(txn)
              end
            end


          end
        end


      end
    end
    # This really should be done in a more generic way
    Repository::SubversionRepository.__generate_authz_file
  end
end
