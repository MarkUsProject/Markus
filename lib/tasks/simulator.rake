# A new rake to generate assignments, random students, submissions and TA data
class Time
  # Return a random Time
  # From http://jroller.com/obie/entry/random_times_for_rails
  def self.random(params = {})
    years_back = params[:year_range] || 5
    year = (rand * years_back).ceil + (Time.current.year - years_back)
    month = (rand * 12).ceil
    day = (rand * 31).ceil
    series = [date = Time.zone.local(year, month, day)]
    if params[:series]
      params[:series].each do |some_time_after|
        series << series.last + (rand * some_time_after).ceil
      end
      return series
    end
    date
  end
end

namespace :markus do
  namespace :simulator do
    desc 'Generate assignments, random students, submissions and TA data'
    task(create: :environment) do
      num_of_assignments = Integer(ENV.fetch('NUM_OF_ASSIGNMENTS', nil))
      # If the uer did not provide the environment variable "NUM_OF_ASSIGNMENTS",
      # the simulator will create two assignments
      if ENV['NUM_OF_ASSIGNMENTS'].nil?
        num_of_assignments = 2
      end
      curr_assignment_num = 1
      # This variable is to be put in the assignment short identifier. The
      # usage if this variable will be explained later.
      curr_assignment_num_for_name = 1
      while curr_assignment_num <= num_of_assignments
        puts "start generating assignment ##{curr_assignment_num}... "
        assignment_short_identifier = "A#{curr_assignment_num_for_name}"
        # There might be other assignemnts' whihc has the same short_identifier
        # as assignment_short_identifier. To solve thsi problem, keep
        # increasing curr_assignment_num_for_name by one till we get a
        # assignment_short_identifier which does not exist in the database.
        while Assignment.find_by(short_identifier: assignment_short_identifier)
          curr_assignment_num_for_name += 1
          assignment_short_identifier = "A#{curr_assignment_num_for_name}"
        end

        puts assignment_short_identifier
        assignment = Assignment.create
        assignment.short_identifier = assignment_short_identifier
        assignment.description = 'Conditionals and Loops'
        assignment.message = 'Learn to use conditional statements, and loops.'

        # The default assignemnt_due_date is a randon date whithin six months
        # before and six months after now.
        assignment_due_date = Time.random(year_range: 1)
        # If the user wants the assignment's due date to be passed, set the
        # assignment_due_date to Time.current.
        if !ENV['PASSED_DUE_DATE'].nil? && (ENV.fetch('PASSED_DUE_DATE', nil) == 'true')
          assignment_due_date = Time.current
        # If the user wants the assignemnt's due date to be not passed, then
        # set  assignment_due_date to two months from now.
        elsif !ENV['PASSED_DUE_DATE'].nil? && (ENV.fetch('PASSED_DUE_DATE', nil) == 'false')
          assignment_due_date = Time.current + 5_184_000
        end
        assignment.due_date = assignment_due_date
        assignment.repository_folder = assignment_short_identifier
        assignment.save!

        puts "Creating the Rubric for #{assignment_short_identifier} ..."
        max_mark1 = rand(5..9)
        max_mark2 = rand(5..9)
        max_mark3 = rand(5..9)
        max_mark4 = rand(5..9)
        rubric_criteria = [{
          name: 'Uses Conditionals',
          max_mark: max_mark1
        },
                           { name: 'Code Clarity',
                             max_mark: max_mark2 }, {
                               name: 'Code Is Documented',
                               max_mark: max_mark3
                             },
                           { name: 'Uses For Loop',
                             max_mark: max_mark4 }]
        default_levels = [
          { name: 'Quite Poor', description: 'This criterion was not satisfied whatsoever', mark: 0 },
          { name: 'Satisfactory', description: 'This criterion was satisfied', mark: 1 },
          { name: 'Good', description: 'This criterion was satisfied well', mark: 2 },
          { name: 'Great', description: 'This criterion was satisfied really well!', mark: 3 },
          { name: 'Excellent', description: 'This criterion was satisfied excellently', mark: 4 }
        ]
        rubric_criteria.each do |rubric_criterion|
          params = { rubric: {
            assignment: assignment, levels_attributes: default_levels
          } }
          rubric_criterion.merge(params[:rubric])
          RubricCriterion.create(rubric_criterion)
          assignment.criteria << rc
        end
        assignment.save

        puts "#{assignment_short_identifier} mark is #{assignment.max_mark}"
        puts "Finish creating assignment#{assignment_short_identifier}."

        puts 'Generating TAs ...'
        num_of_tas = Integer(ENV.fetch('NUM_OF_TAS', nil))
        # If the uer did not provide the environment variable "NUM_OF_TAS"
        if ENV['NUM_OF_TAS'].nil?
          num_of_tas = rand(1..3)
        end
        curr_ta_num = 1
        # student_num is the student number for students created in this
        # assignment. The number will increase by one for the next created
        # student.
        student_num = 1
        while curr_ta_num <= num_of_tas
          puts ''
          # Form a new TA membership with some default value.
          ta_last_name = curr_assignment_num_for_name.to_s + curr_ta_num.to_s +
            student_num.to_s
          ta_user_name = "TA#{ta_last_name}"

          puts "Start generating #{ta_user_name}... "
          ta = Ta.create(user_name: ta_user_name, first_name: 'TA', last_name: ta_last_name)

          puts "Finish creating TA ##{ta_user_name}... "

          puts 'Start generating students ...'

          num_of_students = Integer(ENV.fetch('NUM_OF_STUDENTS', nil))
          # If the uer did not provide the environment variable "NUM_OF_STUDENTS"
          if ENV['NUM_OF_STUDENTS'].nil?
            num_of_students = rand(10..15)
          end

          curr_student_num = 1
          while curr_student_num <= num_of_students
            student_last_name = curr_assignment_num_for_name.to_s + curr_ta_num.to_s +
              student_num.to_s

            student_user_name = "Student # #{student_last_name}"

            puts "Start generating #{student_user_name}... "
            student = Student.create(user_name: student_user_name,
                                     last_name: student_last_name,
                                     first_name: 'Student',
                                     type: 'Student')

            student.save!
            student.create_group_for_working_alone_student(assignment.id)
            student.save
            grouping = student.accepted_grouping_for(assignment.id)
            grouping.save!
            grouping.create_starter_files
            grouping.save!
            Grouping.assign_all_tas(grouping.id, [ta.id], assignment)

            assignment.groupings << grouping
            assignment.save!

            grouping.access_repo do |assignment_repo|
              txn = assignment_repo.get_transaction(student_user_name)
              file_data = %|class assignment {
        // This method should sum only positive values
        public static void main(String args[]) {
          // First, I create an array
          double[] ar = {-1.2, 0.5, -0.15, 55.2, -5.2, 8.5, -9.12}
          int sum = 0;
          for (double num : ar) {
            if (num > 0) {
              sum += num
            }
          }
          System.out.println("The sum of the positive values is: " + sum);
        }
      }|
              folder_name = "#{assignment_short_identifier}/#{assignment_short_identifier}.java"
              puts folder_name
              txn.add(folder_name, file_data, 'text/java')
              assignment_repo.commit(txn)
            end
            assignment.save!

            num_of_submissions = rand(4)
            curr_submission_num = 1

            while curr_submission_num <= num_of_submissions
              date_of_submission = Time.random(year_range: 1)
              submission = Submission.create_by_timestamp(grouping, date_of_submission)
              submission.save!
              curr_submission_num += 1
              submission.save!
            end

            submission = grouping.current_submission_used
            # If marked is 1, then the accepted submission, if any, is partially marked;
            # if marked is 2, then it is completely marked
            marked = rand(3)
            if (marked == 1) && !submission.nil?
              @result = submission.get_latest_result
              @result.marking_state = Result::MARKING_STATES[:incomplete]
              @result.save!
              submission.save!
            elsif (marked == 2) && !submission.nil?
              result = submission.get_latest_result
              # Create a mark for each criterion and attach to result
              puts 'Generating mark ...'
              assignment.criteria.each do |criterion|
                # Save a mark for each criterion
                m = Mark.new
                m.criterion = criterion
                m.result = result
                m.mark = rand(4) # assign some random mark
                m.save!
              end

              result.overall_comment = "Assignment goals pretty much met, but some things would need improvement. '\
                'Other things are absolutely fantastic! Seriously, this is just some random text."
              result.marking_state = Result::MARKING_STATES[:complete]
              result.released_to_students = true
              result.save!
              submission.save!
            end

            puts "Finish creating #{student_user_name}"
            curr_student_num += 1
            student_num += 1

          end

          curr_ta_num += 1
        end

        curr_assignment_num += 1
        curr_assignment_num_for_name += 1
      end

      # Create s standard instructor; if it does not already exist.
      unless Instructor.find_by(user_name: 'a')
        Instructor.create(user_name: 'a', first_name: 'instructor', last_name: 'instructor')
      end

      # Create Reid; if it does not already exist.
      unless Instructor.find_by(user_name: 'reid')
        Instructor.create(user_name: 'reid', first_name: 'Karen', last_name: 'Reid')
      end
    end
  end
end
