namespace :markus do
  desc 'Markus demo'

  def submit_files(group, a)
    grouping = group.grouping_for_assignment(a.id)
    grouping.access_repo do |repo|
      txn = repo.get_transaction(grouping.inviter.user_name)
      repo_path = File.join(a.repository_folder, 'hello_world.py')
      txn.add(repo_path, 'print("Hello World")', '')
      repo.commit(txn)
    end
  end

  def collect(group, a)
    grouping = group.groupings.where(assessment_id: a.id).first
    time = grouping.assignment.submission_rule.calculate_collection_time.localtime
    submission = Submission.create_by_timestamp(grouping, time)
    a.submission_rule.apply_submission_rule(submission)
    grouping.is_collected = true
    grouping.save
    submission
  end

  def create_group(a, students)
    if students.length == 1
      students[0].create_group_for_working_alone_student(a.id)
      Group.find_by group_name: students[0].user_name
    else
      group = Group.create(
        group_name: "#{students[0].user_name} #{a.short_identifier}",
        course: a.course
      )
      grouping = Grouping.create(
        group: group,
        assignment: a
      )
      grouping.invite(
        [students[0].user_name],
        StudentMembership::STATUSES[:inviter],
        invoked_by_instructor: true
      )
      students[1..-1].each do |student|
        grouping.invite(
          [student.user_name],
          StudentMembership::STATUSES[:accepted],
          invoked_by_instructor: true
        )
      end
      group
    end
  end

  def request_remark(submission)
    original_result = Result.find_by(submission_id: submission.id)
    original_result.released_to_students = false
    original_result.save

    # Create new entry in results table for the remark
    remark = Result.new(
      marking_state: Result::MARKING_STATES[:incomplete],
      submission_id: submission.id,
      remark_request_submitted_at: Time.current
    )
    remark.save

    # Update subission
    submission.update(
      remark_request: 'Please remark my assignment.',
      remark_request_timestamp: Time.current
    )

    submission.remark_result.update(marking_state: Result::MARKING_STATES[:incomplete])
  end

  def create_criteria(a)
    CheckboxCriterion.create(
      name: 'Mark1',
      assessment_id: a.id,
      description: '',
      position: 0,
      max_mark: 10,
      created_at: nil,
      updated_at: nil,
      assigned_groups_count: nil
    )
    FlexibleCriterion.create(
      name: 'Mark2',
      assessment_id: a.id,
      description: '',
      position: 1,
      max_mark: 10,
      created_at: nil,
      updated_at: nil,
      assigned_groups_count: nil
    )

    attributes = []
    5.times do |number|
      lvl = { name: random_words(1), description: random_sentences(5), mark: number }
      attributes.push(lvl)
    end
    params = {
      name: 'Mark3', assessment_id: a.id,
      position: 2, max_mark: 4, levels_attributes: attributes
    }
    RubricCriterion.create!(params)
  end

  def submit_half_on_time(a)
    Student.find_each.each_with_index do |student, i|
      student.create_group_for_working_alone_student(a.id)
      group = Group.find_by group_name: student.user_name
      if i == (Student.count / 2).ceil
        a.update(due_date: Time.current, token_start_date: Time.current)
        a.save
      end
      submit_files(group, a)
      collect(group, a)
    end
  end

  def mark_submission(submission)
    result = submission.results.last
    result.marks.each do |mark|
      criterion = mark.criterion
      if criterion.instance_of?(RubricCriterion)
        random_mark = criterion.max_mark / 4 * rand(0..4)
      elsif criterion.instance_of?(FlexibleCriterion)
        random_mark = rand(0..criterion.max_mark.to_i)
      else
        random_mark = rand(0..1)
      end
      mark.mark = random_mark
      mark.save
    end
    result.update_total_mark
    result.marking_state = 'complete'
    result.save
    result
  end

  task demo: :environment do
    puts 'RESET DATABASE'

    Rake::Task['db:drop'].invoke
    Rake::Task['markus:repos:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:schema:load'].invoke

    puts 'CREATE USERS'

    # Only use instructor if in dev mode
    puts 'Instructors'
    instructors = [%w[instructor William Wonka]]
    instructors.each do |instructor|
      Instructor.create(user_name: instructor[0], first_name: instructor[1], last_name: instructor[2])
    end

    puts 'Students'
    students = [%w[student1 Charlie Bucket],
                %w[student2 Augustus Gloop],
                %w[student3 Violet Beauregarde],
                %w[student4 Mike Teavee],
                %w[student5 Veruca Salt]]
    i = 0
    students.each do |student|
      i += rand(10 ** 7)
      stu = Student.create(user_name: student[0], first_name: student[1], last_name: student[2])
      stu.update_attribute(:id_number, format('%010d', i))
      stu.update_attribute(:grace_credits, 5)
    end

    puts 'TAs'
    tas = [%w[ta1 Angelo Muscat],
           %w[ta2 Rusty Goffe],
           %w[ta3 George Claydon]]
    tas.each do |ta|
      Ta.create(user_name: ta[0], first_name: ta[1], last_name: ta[2])
    end

    puts 'CREATE ASSIGNMENTS'

    puts '1: No Late Submissions'
    a = Assignment.create(
      course: Course.first,
      short_identifier: 'A1NoLate',
      description: 'No Late Submissions',
      message: '',
      repository_folder: 'A1NoLate',
      due_date: 24.hours.from_now,
      allow_web_submits: false,
      allow_remarks: true,
      remark_due_date: 1.week.from_now,
      enable_test: true,
      token_start_date: 24.hours.from_now,
      token_period: 1
    )

    create_criteria(a)
    submit_half_on_time(a)

    puts '2: Grace Period Submissions'
    a = Assignment.create(
      course: Course.first,
      short_identifier: 'A2Grace',
      description: 'Grace Period Submissions',
      message: '',
      repository_folder: 'A2Grace',
      due_date: 24.hours.from_now,
      allow_web_submits: false,
      submission_rule: GracePeriodSubmissionRule.new,
      allow_remarks: true,
      remark_due_date: 1.week.from_now,
      enable_test: true,
      tokens_per_period: 1,
      token_start_date: 24.hours.from_now,
      token_period: 1
    )
    a.submission_rule.periods << Period.new(hours: 0.001) # remove 1 token every hour
    create_criteria(a)
    submit_half_on_time(a)

    puts '3: Penalty Decay Submissions'
    a = Assignment.create(
      course: Course.first,
      short_identifier: 'A3Penalty',
      description: 'Penalty Decay Submissions',
      message: '',
      repository_folder: 'A3Penalty',
      due_date: 24.hours.from_now,
      allow_web_submits: false,
      submission_rule: PenaltyDecayPeriodSubmissionRule.new,
      allow_remarks: true,
      remark_due_date: 1.week.from_now,
      enable_test: true,
      token_start_date: 24.hours.from_now,
      token_period: 1
    )

    a.submission_rule.periods << Period.new(hours: 1, deduction: 10, interval: 0.01)
    create_criteria(a)

    submit_half_on_time(a)

    a.submission_rule.periods = []
    a.submission_rule.periods << Period.new(hours: 0.001, deduction: 10, interval: 1) # remove 10%/hour for 3 hours

    puts '4: Students work in groups'
    a = Assignment.create(
      course: Course.first,
      short_identifier: 'A4Groups',
      description: 'Students work in groups',
      message: '',
      group_max: 3,
      student_form_groups: true,
      repository_folder: 'A4Groups',
      due_date: 1.month.from_now,
      allow_web_submits: false,
      allow_remarks: true,
      remark_due_date: 2.months.from_now,
      enable_test: true,
      token_start_date: 1.month.from_now,
      token_period: 1
    )

    create_group(a, [students[0]].map { |s| Student.find_by(user_name: s) })
    create_group(a, students[1...3].map { |s| Student.find_by(user_name: s) })
    create_group(a, students[3..-1].map { |s| Student.find_by(user_name: s) })
    create_criteria(a)

    puts '5: Nothing collected'
    a = Assignment.create(
      course: Course.first,
      short_identifier: 'A5Collect',
      description: 'Nothing Collected',
      message: '',
      repository_folder: 'A5Collect',
      due_date: 1.month.from_now,
      allow_web_submits: false,
      allow_remarks: true,
      remark_due_date: 2.months.from_now,
      enable_test: true,
      token_start_date: 1.month.from_now,
      token_period: 1
    )
    create_criteria(a)

    Student.find_each do |student|
      student.create_group_for_working_alone_student(a.id)
      group = Group.find_by group_name: student.user_name
      submit_files(group, a)
    end

    a.update(due_date: Time.current, token_start_date: Time.current)
    a.save

    puts '6: Marking State examples'
    a = Assignment.create(
      course: Course.first,
      short_identifier: 'A6MarkingState',
      description: 'Marking State examples',
      message: '',
      repository_folder: 'A6MarkingState',
      due_date: 1.month.from_now,
      allow_web_submits: false,
      allow_remarks: true,
      remark_due_date: 2.months.from_now,
      enable_test: true,
      token_start_date: 1.month.from_now,
      token_period: 1
    )

    remark_submission = nil
    create_criteria(a)
    Student.find_each.each_with_index do |student, j|
      student.create_group_for_working_alone_student(a.id)
      group = Group.find_by group_name: student.user_name
      if j == Student.count - 1
        a.update(due_date: Time.current, token_start_date: Time.current)
        a.save
      end
      next if j == 1
      submit_files(group, a)
      submission = collect(group, a)
      remark_submission = submission if j.zero?
      next unless [2, 3].include?(j)
      result = mark_submission(submission)
      next unless j == 2
      result.released_to_students = true
      result.save
    end
    mark_submission(remark_submission)
    request_remark(remark_submission)
  end
end
