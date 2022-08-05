namespace :markus do
  namespace :load do
    desc "Loads 'faked' results into database"
    task(results: :environment) do
      if ENV['short_id'].nil?
        warn "Usage: rake load:results short_id=string\n\nNOTE: Assignment must not exist."
        exit(1)
      end

      puts 'Loading results into database (this might take a long time)... '
      # set up assignments
      a1 = Assignment.new
      rule = PenaltyPeriodSubmissionRule.new
      a1.short_identifier = ENV.fetch('short_id', nil)
      a1.description = 'Conditionals and Loops'
      a1.message = 'Learn to use conditional statements, and loops.'
      a1.due_date = Time.current
      a1.repository_folder = a1.short_identifier
      a1.submission_rule = rule
      a1.save!

      # load users
      STUDENT_CSV = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'db', 'data', 'students.csv'))
      if File.readable?(STUDENT_CSV)
        csv_students = File.new(STUDENT_CSV)
        User.upload_user_list(Student, csv_students, nil)
      end

      # create groupings for each student in A1
      students = Student.all
      students.each do |student|
        student.create_group_for_working_alone_student(a1.id)
        grouping = student.accepted_grouping_for(a1.id)
        grouping.create_starter_files
      rescue StandardError => e
        puts "Caught exception on #{student.user_name}: #{e.message}" # ignore exceptions
      end

      # create rubric criteria for a1
      rubric_criteria = [{ name: 'Uses Conditionals', max_mark: 4 }, { name: 'Code Clarity', max_mark: 8 },
                         { name: 'Code Is Documented', max_mark: 12 }, { name: 'Uses For Loop', max_mark: 4 }]
      default_levels = [
        { name: 'Quite Poor', description: 'This criterion was not satisfied whatsoever', mark: 0 },
        { name: 'Satisfactory', description: 'This criterion was satisfied', mark: 1 },
        { name: 'Good', description: 'This criterion was satisfied well', mark: 2 },
        { name: 'Great', description: 'This criterion was satisfied really well!', mark: 3 },
        { name: 'Excellent', description: 'This criterion was satisfied excellently', mark: 4 }
      ]
      rubric_criteria.each do |rubric_criterion|
        params = {
          assignment: a1, levels_attributes: default_levels
        }
        rubric_criterion.merge(params)
        RubricCriterion.create(rubric_criterion)
      end

      # create submissions
      students.each do |student|
        if student.has_accepted_grouping_for?(a1.id)
          grouping = student.accepted_grouping_for(a1.id)
          # commit some files into the group repository
          file_dir = File.join(File.dirname(__FILE__), '..', '..', 'db', 'data', 'submission_files')
          Dir.foreach(file_dir) do |filename|
            unless File.directory?(File.join(file_dir, filename))
              file_contents = File.open(File.join(file_dir, filename))
              file_contents.rewind
              grouping.access_repo do |repo|
                txn = repo.get_transaction(student.user_name)
                path = File.join(a1.repository_folder, filename)
                txn.add(path, file_contents.read, '')
                repo.commit(txn)
              end
              file_contents.close
            end
          end
          submission = Submission.create_by_timestamp(grouping, Time.current)
          result = submission.get_latest_result
          # create marks for each criterion and attach to result
          a1.criteria.each do |criterion|
            # save a mark for each criterion
            m = Mark.new
            m.criterion = criterion
            m.result = result
            m.mark = rand(5) # assign some random mark
            m.save
          end
          result.overall_comment = "Assignment goals pretty much met, but some things would need improvement. \
            Other things are absolutely fantastic! Seriously, this is just some random text."
          result.marking_state = Result::MARKING_STATES[:complete]
          result.released_to_students = true
          result.save
        end
      end
      puts 'Done!'
    end
  end
end
