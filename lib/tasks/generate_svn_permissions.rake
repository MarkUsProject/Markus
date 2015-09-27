namespace :markus do
  desc "Generates a Subversion permission file (svn_authz)"
  task(generate_svn_authz: [:environment]) do
    valid_groupings_and_members = {}
    # Start collecting data
    #
    # Get all assignments with no web submissions allowed
    assignments = Assignment.where(allow_web_submits: false)
    assignments.each do |assignment|
      # Get valid/admin approved groupings
      valid_groupings = assignment.valid_groupings
      valid_groupings.each do |gr|
        accepted_students = gr.accepted_students
        accepted_students = accepted_students.map { |student| student.user_name }
        valid_groupings_and_members[gr.group.repo_name] = accepted_students
      end
    end
    # TAs and Admins should have permissions anyway
    tas = Ta.all
    tas = tas.map { |ta| ta.user_name }
    admins = Admin.all
    admins = admins.map { |admin| admin.user_name }
    tas_and_admins = tas + admins # we only need their user_names
    # TAs and Admins should have access to "dead" repositories
    invalid_groups = Group.all
    invalid_groups = invalid_groups.map { |group| group.repo_name }
    #
    # We have the data, print permission string
    #
    valid_groupings_and_members.each do |repo_name, students|
      $stdout.print "[#{repo_name}:/]\n"
      # add students
      students.each do |user_name|
        $stdout.print "#{user_name} = rw\n"
      end
      # add TAs and Admins
      tas_and_admins.each do |admin_user|
        $stdout.print "#{admin_user} = rw\n"
      end
      $stdout.print "\n"
      invalid_groups.delete(repo_name)
    end
    # Add TAs and Admins to be allowed to access any repository
    # created at some point
    invalid_groups.each do |repo_name|
      $stdout.print "[#{repo_name}:/]\n"
      # add TAs and Admins, only
      tas_and_admins.each do |admin_user|
        $stdout.print "#{admin_user} = rw\n"
      end
      $stdout.print "\n"
    end
  end
end
