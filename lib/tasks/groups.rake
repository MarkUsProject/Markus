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
          # recursively copying contents(files & directories) inside the file_dir
          copy_dir(file_dir, txn, assignment.repository_folder)

          repo.commit(txn)
        end
      end
    end
    # This really should be done in a more generic way
    repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type)
    repo.__set_all_permissions
  end

  def copy_dir(file_dir, txn, saving_repo)
    txn.add_path(saving_repo)
    Dir.foreach(file_dir) do |filename|
      content = File.join(file_dir, filename)
      if filename[0] != '.'
        if not File.directory?(content)  # if content is a file
          file_contents = File.open(content)
          file_contents.rewind
          path = File.join(saving_repo, filename)
          txn.add(path, file_contents.read, '')
        else # if content is a directory and filename doesn't start with .
          new_saving_repo = File.join(saving_repo, filename) # generating new saving repo for recursion
          txn.add_path(new_saving_repo)
          new_dir = File.join(file_dir, filename) # generating new file path for recursion
          copy_dir(new_dir, txn, new_saving_repo)
        end
      end
    end
  end
end
