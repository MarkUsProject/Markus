namespace :db do
  desc 'Create assignments'
  task assignments: :environment do
    # Assignments
    rule = GracePeriodSubmissionRule.new
    puts 'Assignment 0: Grace Credit usage'
    Assignment.create(
      course: Course.first,
      short_identifier: 'A0',
      description: 'Variables and Simple Operations',
      message: 'using basic operators and assigning variables',
      due_date: Time.current, # Will be adjusted in marks.rake
      is_hidden: false,
      assignment_properties_attributes: {
        group_min: 2,
        group_max: 3,
        student_form_groups: true,
        repository_folder: 'A0',
        token_start_date: Time.current,
        token_period: 1
      },
      submission_rule: rule
    )
    Period.create(submission_rule: rule, hours: 24)

    puts 'Assignment 1: Single Student Assignment No Marks'
    Assignment.create(
      course: Course.first,
      short_identifier: 'A1',
      description: 'Conditionals and Loops',
      message: 'Learn to use conditional statements, and loops.',
      due_date: Time.current, # Will be adjusted in marks.rake
      is_hidden: false,
      assignment_properties_attributes: {
        repository_folder: 'A1',
        allow_remarks: true,
        remark_due_date: 2.days.ago,
        token_start_date: Time.current,
        token_period: 1
      }
    )

    assignment_msg = <<-DESCRIPTION
    Basic exercise in Object Oriented Programming.
    Implement Animal, Cat, and Dog, as described in class.
    DESCRIPTION
    puts 'Assignment 2: Group Assignment No Marks'
    Assignment.create(
      course: Course.first,
      short_identifier: 'A2',
      description: 'Cats and Dogs',
      message: assignment_msg,
      due_date: Time.current, # Will be adjusted in marks.rake
      is_hidden: false,
      assignment_properties_attributes: {
        group_min: 2,
        group_max: 3,
        student_form_groups: true,
        repository_folder: 'A2',
        token_start_date: Time.current,
        token_period: 1
      }
    )

    puts 'Assignment 3: Single Student Sporadic Marks'
    Assignment.create(
      course: Course.first,
      short_identifier: 'A3',
      description: 'Ode to a Python program',
      message: 'Learn to use files, dictionaries, and testing.',
      due_date: 2.months.from_now,
      is_hidden: false,
      assignment_properties_attributes: {
        repository_folder: 'A3',
        token_start_date: Time.current,
        token_period: 1,
        section_due_dates_type: true
      }
    )

    puts 'Assignment 4: Group Assignment Sporadic Marks'
    Assignment.create(
      course: Course.first,
      short_identifier: 'A4',
      description: 'Introduction to Recursion',
      message: 'Implement functions using Recursion',
      due_date: 2.months.from_now,
      is_hidden: false,
      assignment_properties_attributes: {
        group_min: 2,
        group_max: 3,
        student_form_groups: true,
        repository_folder: 'A4',
        token_start_date: Time.current,
        token_period: 1,
        section_due_dates_type: true
      }
    )

    puts 'Assignment 5: Timed Assessment'
    Assignment.create(
      course: Course.first,
      short_identifier: 'A5',
      description: 'Timed Assessment',
      message: 'A timed assessment',
      due_date: 2.months.from_now,
      is_hidden: false,
      assignment_properties_attributes: {
        group_min: 1,
        group_max: 1,
        student_form_groups: false,
        is_timed: true,
        start_time: 2.months.from_now - 10.hours,
        duration: 2.hours,
        repository_folder: 'A5',
        token_start_date: Time.current,
        token_period: 1,
        section_due_dates_type: true
      }
    )

    Assignment.joins(:assignment_properties)
              .where(assignment_properties: { section_due_dates_type: true })
              .find_each do |assignment|
      assignment.course.sections.find_each.with_index do |section, i|
        AssessmentSectionProperties.create(assessment: assignment,
                                           section: section, due_date: assignment.due_date + (i + 1).days)
      end
    end
  end
end
