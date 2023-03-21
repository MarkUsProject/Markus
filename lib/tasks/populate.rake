namespace :markus do
  desc 'Print MarkUs version'
  task :version do # rubocop:disable Rails/RakeEnvironment
    VERSION_FILE = File.expand_path(File.join(__FILE__, '..', '..', '..', 'app', 'MARKUS_VERSION'))
    unless File.exist?(VERSION_FILE)
      warn 'Could not determine MarkUs version, please check your installation!'
      exit(1)
    end
    content = File.new(VERSION_FILE).read
    version_info = {}
    content.split(',').each do |token|
      k, v = token.split('=')
      version_info[k.downcase] = v
    end
    puts "MarkUs version: #{version_info['version']}.#{version_info['patch_level']}"
  end

  desc 'Create a single Instructor'
  task(instructor: :environment) do
    user_name = ENV.fetch('user_name', nil)
    first_name = ENV.fetch('first_name', nil)
    last_name = ENV.fetch('last_name', nil)
    if user_name.blank? || first_name.blank? || last_name.blank?
      warn 'usage:  rake markus:instructor user_name=[user name] first_name=[first name] last_name=[last name]'
      exit(1)
    end
    puts "Creating Instructor #{user_name} (#{first_name} #{last_name})"
    a = Instructor.new(user_name: user_name, first_name: first_name, last_name: last_name)
    if !a.save
      warn 'Error saving record:'
      a.errors.each do |error_message|
        warn "#{error_message[0]} #{error_message[1]}"
      end
    else
      a.reset_api_key
      puts "Instructor #{user_name} successfully created"
    end
  end

  desc 'Add more student users to the database'
  # this task depends on :environment and :seed
  task(add_students: [:environment, :'db:seed']) do
    puts 'Populate database with some additional students'
    STUDENT_CSV = File.expand_path(File.join(__FILE__, '..', '..', '..', 'test', 'fixtures', 'classlist-csvs',
                                             'new_students.csv'))
    if File.readable?(STUDENT_CSV)
      csv_students = File.new(STUDENT_CSV)
      User.upload_user_list(Student, csv_students.read, nil)
    else
      warn "File not found or not readable: #{STUDENT_CSV}"
    end
  end

  desc 'Create a setup for usability testing.'
  # this task depends on :environment and :seed
  task(usability_test_setup: [:environment, :'db:seed']) do
    puts 'Creating a setup for usability testing'
    # modify settings for A1 (solo assignment)
    a1 = Assignment.find_by(short_identifier: 'A1')
    req_file1 = AssignmentFile.new
    req_file1.filename = 'conditionals.py'
    req_file1.assessment_id = a1.id
    req_file2 = AssignmentFile.new
    req_file2.filename = 'loops.py'
    req_file2.assessment_id = a1.id
    a1.due_date = 1.week.from_now # due date is a week from now
    a1.message += "\nNote: You are working alone for this assignment."
    a1.group_min = 1
    a1.group_max = 1
    a1.save!
    req_file1.save!
    req_file2.save!

    # modify settings for A2
    a2 = Assignment.find_by(short_identifier: 'A2')
    a2.due_date = 2.weeks.from_now # due date is 2 weeks from now
    a2.message += "\nNote: You are working in groups for this assignment. Please form groups on your own."
    # students can form groups
    a2.group_min = 3
    a2.group_max = 5
    req_file1 = AssignmentFile.new
    req_file1.filename = 'Animal.java'
    req_file1.assignment = a2
    req_file2 = AssignmentFile.new
    req_file2.filename = 'Cat.java'
    req_file2.assignment = a2
    req_file3 = AssignmentFile.new
    req_file3.filename = 'Dog.java'
    req_file3.assignment = a2
    a2.save!
    req_file1.save!
    req_file2.save!
    req_file3.save!

    # Create a third assignment, for which the instructor has formed groups
    groups_csv_string = "Saturn,ignored_repo,c9magnar,c6scriab,g9merika\n
Mars,irgnored_repo,c9puccin,c7stanfo,g5dindyv\n
Neptune,ignored_repo,c7dallap,c7guarni,c7kimear\n"
    a3 = Assignment.create(
      short_identifier: 'A3',
      description: 'Shell Scripting',
      message: "Learn how to use functions, parameter passing and proper return codes.\n
Note: You have been assigned to a group by the instructor.",
      repository_folder: 'A3',
      due_date: 3.weeks.from_now,
      group_max: 3,
      student_form_groups: false
    )
    req_file1 = AssignmentFile.new
    req_file1.filename = 'gcd.sh'
    req_file1.assignment = a3
    a3.save!
    # create groupings/groups
    data = groups_csv_string.split("\n").map do |row|
      a3.add_csv_group(row.split(','))
    end
    CreateGroupsJob.perform_now(a3, data)
    req_file1.save!
  end
end
