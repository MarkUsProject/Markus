namespace :db do

  desc 'Create groups for assignments'
  task :groups => :environment do
    puts 'Assign Groups/Students for Assignments'

    students = Student.all
    Assignment.all.each do |assignment|
      num_groups = (assignment.short_identifier == 'A1' || assignment.short_identifier == 'A3') ? students.length : 15
      num_groups.times do |time|
        student = students[time]
        # if this is an individual assignment
        if assignment.group_min == 1 && assignment.group_max == 1
          student.create_group_for_working_alone_student(assignment.id)
          group = Group.find_by group_name: student.user_name
        # if this is a group assignment
        else
          group = Group.create(
            group_name: "#{ student.user_name } #{ assignment.short_identifier }"
          )
          grouping = Grouping.create(
            group: group,
            assignment: assignment
          )
          grouping.invite(
            [student.user_name],
            StudentMembership::STATUSES[:inviter],
            invoked_by_admin: true)
          grouping.invite(
            [students[time + 15].user_name],
            StudentMembership::STATUSES[:accepted],
            invoked_by_admin: true)
        end

        group.access_repo do |repo|
          # add files to the root folder of the repo (e.g. "A1")
          # recursively copying contents(files & directories) inside the file_dir
          txn = repo.get_transaction(group.grouping_for_assignment(assignment.id).inviter.user_name)
          file_dir  = File.join(File.dirname(__FILE__), '/../../db/data/submission_files')
          copy_dir(file_dir, txn, assignment.repository_folder)
          repo.commit(txn)
        end
      end
    end
    Repository.get_class.update_permissions
  end

  def copy_dir(seed_dir, txn, repo_dir)
    Dir.foreach(seed_dir) do |filename|
      if filename[0] == '.' # skip dir and files starting with .
        next
      end
      seed_path = File.join(seed_dir, filename)
      repo_path = File.join(repo_dir, filename)
      if File.directory?(seed_path)
        txn.add_path(repo_path)
        copy_dir(seed_path, txn, repo_path)
      else
        File.open(seed_path, 'r') do |file|
          txn.add(repo_path, file.read, '')
        end
      end
    end
  end
end
