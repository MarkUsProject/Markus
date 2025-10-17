describe AssignmentPolicy do
  let(:context) { { role: role, real_user: role.user } }
  let(:record) { assignment }
  let(:role) { create(:instructor) }
  let(:assignment) { create(:assignment) }

  describe_rule :index? do
    succeed
  end

  describe_rule :switch? do
    succeed
  end

  describe_rule :manage? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'that can manage assessments' do
        let(:role) { create(:ta, manage_assessments: true) }
      end
      failed 'that cannot manage assessments' do
        let(:role) { create(:ta, manage_assessments: false) }
      end
    end

    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :view_test_options? do
    context 'role is an instructor' do
      let(:role) { create(:instructor) }

      succeed 'when tests enabled' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: true }) }
      end
      failed 'when tests disabled' do
        let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: false }) }
      end
    end

    context 'role is a ta' do
      context 'that can run tests' do
        let(:role) { create(:ta, run_tests: true) }

        succeed 'when tests enabled' do
          let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: true }) }
        end
        failed 'when tests disabled' do
          let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: false }) }
        end
      end

      failed 'that cannot run tests' do
        let(:role) { create(:ta, run_tests: false) }
      end
    end

    context 'role is a student' do
      let(:role) { create(:student) }

      failed 'when student tests disabled' do
        let(:assignment) { build(:assignment, assignment_properties_attributes: { enable_student_tests: false }) }
      end
      context 'when student tests enabled' do
        let(:assignment) { build(:assignment, assignment_properties_attributes: properties) }

        failed 'when there are no tokens given' do
          let(:properties) { { enable_student_tests: true, unlimited_tokens: false, tokens_per_period: 0 } }
        end
        succeed 'when there are unlimited tokens' do
          let(:properties) { { enable_student_tests: true, unlimited_tokens: true, tokens_per_period: 0 } }
        end
        succeed 'when there are some tokens available' do
          let(:properties) { { enable_student_tests: true, unlimited_tokens: true, tokens_per_period: 1 } }
        end
      end
    end
  end

  describe_rule :student_tests_enabled? do
    failed 'when student tests disabled' do
      let(:assignment) { build(:assignment, assignment_properties_attributes: { enable_student_tests: false }) }
    end
    context 'when student tests enabled' do
      let(:assignment) { build(:assignment, assignment_properties_attributes: properties) }

      failed 'when there are no tokens given' do
        let(:properties) { { enable_student_tests: true, unlimited_tokens: false, tokens_per_period: 0 } }
      end
      succeed 'when there are unlimited tokens' do
        let(:properties) { { enable_student_tests: true, unlimited_tokens: true, tokens_per_period: 0 } }
      end
      succeed 'when there are some tokens available' do
        let(:properties) { { enable_student_tests: true, unlimited_tokens: true, tokens_per_period: 1 } }
      end
    end
  end

  describe_rule :tests_enabled? do
    succeed 'when tests enabled' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: true }) }
    end
    failed 'when tests disabled' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { enable_test: false }) }
    end
  end

  describe_rule :stop_test? do
    succeed 'when role is an instructor' do
      let(:role) { create(:instructor) }
    end

    context 'when role is a ta' do
      succeed 'that can manage assessments' do
        let(:role) { create(:ta, manage_assessments: true) }
      end
      failed 'that cannot manage assessments' do
        let(:role) { create(:ta, manage_assessments: false) }
      end
    end

    context 'when role is a student' do
      let(:context) { { role: role, real_user: role.user, test_run_id: test_run_id } }
      let(:role) { create(:student) }

      succeed 'when student can cancel test' do
        let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
        let(:test_run) { create(:student_test_run, grouping: grouping, status: :in_progress) }
        let(:test_run_id) { test_run.id }
        let(:assignment) do
          build(:assignment_for_student_tests,
                assignment_properties_attributes: { enable_student_tests: true,
                                                    unlimited_tokens: true,
                                                    tokens_per_period: 0 })
        end
      end

      failed 'when student cannot cancel test' do
        let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
        let(:test_run) { create(:student_test_run, grouping: grouping, status: :in_progress) }
        let(:test_run_id) { test_run.id + 1 }
        let(:assignment) do
          build(:assignment_for_student_tests,
                assignment_properties_attributes: { enable_student_tests: true,
                                                    unlimited_tokens: true,
                                                    tokens_per_period: 0 })
        end
      end
      context 'when authorized with an assignment' do
        let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
        let(:test_run) { create(:student_test_run, grouping: grouping, status: :in_progress) }
        let(:test_run_id) { test_run.id }

        succeed 'when student tests enabled' do
          let(:assignment) do
            build(:assignment_for_student_tests, assignment_properties_attributes: { enable_student_tests: true,
                                                                                     unlimited_tokens: true,
                                                                                     tokens_per_period: 0 })
          end
        end
        failed 'when student tests disabled' do
          let(:assignment) { build(:assignment_for_student_tests) }
        end
      end

      context 'when authorized with a grouping' do
        let(:test_run) { create(:student_test_run, grouping: grouping, status: :in_progress) }
        let(:test_run_id) { test_run.id }

        let(:assignment) do
          create(:assignment_for_student_tests, assignment_properties_attributes: { unlimited_tokens: true })
        end

        succeed 'when the role is a member' do
          let!(:grouping) { create(:grouping_with_inviter, inviter: role, assignment: assignment) }
        end
        failed 'when the role is not a member' do
          let(:grouping) { create(:grouping_with_inviter, assignment: assignment) }
        end
        failed 'when the due date has passed' do
          before { assignment.update!(due_date: 1.day.ago) }

          let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
        end
        succeed 'when the due date has not passed' do
          let(:grouping) { create(:grouping_with_inviter, assignment: assignment, inviter: role) }
        end
      end
    end
  end

  describe_rule :tests_set_up? do
    succeed 'when remote_autotest_settings_id exist' do
      before { assignment.update! remote_autotest_settings_id: 1 }
    end
    failed 'when remote_autotest_settings_id do not exist'
  end

  describe_rule :tokens_released? do
    succeed 'when token start date is in the past' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { token_start_date: 1.hour.ago }) }
    end
    failed 'when token start date is in the future' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { token_start_date: 1.hour.from_now }) }
    end
    failed 'when token start date is nil'
  end

  describe_rule :before_token_end_date? do
    succeed 'when current date is before the token end date' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { token_end_date: 1.hour.from_now }) }
    end
    failed 'when current date is after the token end date' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { token_end_date: 1.hour.ago }) }
    end
  end

  describe_rule :create_group? do
    let(:role) { create(:student) }
    let(:assignment) { create(:assignment, assignment_properties_attributes: properties) }
    let(:properties) { { student_form_groups: true } }
    let(:past_collection_date?) { false }
    let(:has_accepted_grouping_for?) { false }
    before do
      allow(record).to receive(:past_collection_date?).and_return past_collection_date?
      allow(role).to receive(:has_accepted_grouping_for?).and_return has_accepted_grouping_for?
    end

    succeed 'when collection date has not passed and students can form groups and the user is not in a group yet'
    failed 'when collection date has passed' do
      let(:past_collection_date?) { true }
    end
    failed 'when students cannot form groups' do
      let(:properties) { { student_form_groups: false, group_max: 1 } }
    end
    failed 'when the student is in a group for this assignment' do
      let(:has_accepted_grouping_for?) { true }
    end
  end

  describe_rule :work_alone? do
    succeed 'when group min is one' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { group_min: 1 }) }
    end
    failed 'when group min is not one' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { group_min: 2, group_max: 2 }) }
    end
  end

  describe_rule :collection_date_passed? do
    let(:role) { create(:student) }
    succeed 'when the collection date has passed' do
      before { allow(record).to receive(:past_collection_date?).and_return true }
    end
    failed 'when the collection date has not passed' do
      before { allow(record).to receive(:past_collection_date?).and_return false }
    end
  end

  describe_rule :students_form_groups? do
    let(:assignment) { create(:assignment, assignment_properties_attributes: properties) }
    failed 'when students cannot form groups' do
      let(:properties) { { student_form_groups: false, group_max: 1 } }
    end
    succeed 'when students can form groups' do
      let(:properties) { { student_form_groups: true } }
    end
  end

  describe_rule :not_yet_in_group? do
    succeed 'when the user is not in a group' do
      before { allow(role).to receive(:has_accepted_grouping_for?).and_return false }
    end
    failed 'when the user is in a group' do
      before { allow(role).to receive(:has_accepted_grouping_for?).and_return true }
    end
  end

  describe_rule :autogenerate_group_name? do
    succeed 'when group name is autogenerated' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { group_name_autogenerated: true }) }
    end
    failed 'when group name is not autogenerated' do
      let(:assignment) { create(:assignment, assignment_properties_attributes: { group_name_autogenerated: false }) }
    end
  end

  describe_rule :view? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    succeed 'role is a ta' do
      let(:role) { create(:ta) }
    end
    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :manage_tests? do
    succeed 'role is an instructor' do
      let(:role) { create(:instructor) }
    end
    context 'role is a ta' do
      succeed 'that can manage assessments' do
        let(:role) { create(:ta, manage_assessments: true) }
      end
      failed 'that cannot manage assessments' do
        let(:role) { create(:ta, manage_assessments: false) }
      end
    end

    failed 'role is a student' do
      let(:role) { create(:student) }
    end
  end

  describe_rule :start_timed_assignment? do
    let(:role) { create(:student) }
    let(:due_date) { 2.hours.from_now }
    let(:start_time) { 2.hours.ago }
    let(:assignment) do
      create(:timed_assignment,
             due_date: due_date,
             assignment_properties_attributes: { start_time: start_time })
    end

    context 'when the student is not in a group yet' do
      failed 'when before the start time' do
        let(:start_time) { 1.hour.from_now }
      end
      succeed 'when between the start and end time'
      failed 'when between the start and end time, but the student must work in a group' do
        before { assignment.assignment_properties.update(group_max: 2) }
      end
      failed 'when after the end time' do
        let(:due_date) { 1.hour.ago }
      end
      failed 'when after the end time but within a penalty period' do
        let(:due_date) { 1.hour.ago }
        before do
          rule = create(:penalty_period_submission_rule, assignment: assignment)
          create(:period, hours: 2, submission_rule: rule)
        end
      end
    end

    context 'when the student is in a group' do
      let(:grouping_start_time) { nil }

      before do
        create(:grouping_with_inviter, inviter: role, assignment: assignment, start_time: grouping_start_time)
      end

      failed 'when before the start time' do
        let(:start_time) { 1.hour.from_now }
      end
      succeed 'when between the start and end time and the group has not started'
      failed 'when between the start and end time and the group has already started' do
        let(:grouping_start_time) { Time.current }
      end
      failed 'when after the end time' do
        let(:due_date) { 1.hour.ago }
      end
    end
  end

  describe_rule :see_hidden? do
    let(:new_section) { create(:section) }
    let(:role) { create(:student, section: new_section) }
    let(:assignment) do
      create(:assignment,
             assignment_properties_attributes: { section_due_dates_type: false })
    end
    let(:assessment_section_properties) do
      create(:assessment_section_properties, assessment: assignment,
                                             section: new_section,
                                             due_date: 2.days.from_now,
                                             is_hidden: false)
    end
    context 'when the role is an instructor' do
      let(:instructor_role) { create(:instructor) }

      succeed 'role is an instructor' do
        before { assignment.update(is_hidden: true) }

        let(:context) { { role: instructor_role, real_user: instructor_role.user } }
      end
    end

    context 'when the role is a TA' do
      let(:ta_role) { create(:ta) }

      succeed 'user is an instructor' do
        before { assignment.update(is_hidden: true) }

        let(:context) { { role: ta_role, real_user: ta_role.user } }
      end
    end

    context 'when there are no section due dates' do
      succeed 'when the assignment is not hidden'
      failed 'when the assignment is hidden' do
        before { assignment.update(is_hidden: true) }
      end
    end

    context 'when there are section due dates' do
      before do
        assignment.assignment_properties.update(section_due_dates_type: true)
        assessment_section_properties
      end

      succeed 'when visible with section due date and assignment'
      succeed 'when assignment hidden but section do date ' do
        before { assignment.update(is_hidden: true) }
      end
      failed 'when section due date hidden' do
        before { assessment_section_properties.update(is_hidden: true) }
      end
    end

    context 'with datetime visibility' do
      let(:role) { create(:student) }

      succeed 'when visible_on is in the past and visible_until is in the future' do
        before { assignment.update(is_hidden: true, visible_on: 1.day.ago, visible_until: 1.day.from_now) }
      end

      failed 'when visible_on is in the future' do
        before { assignment.update(is_hidden: false, visible_on: 1.day.from_now, visible_until: 2.days.from_now) }
      end

      failed 'when visible_until is in the past' do
        before { assignment.update(is_hidden: false, visible_on: 2.days.ago, visible_until: 1.day.ago) }
      end

      succeed 'when only visible_on is set and in the past' do
        before { assignment.update(is_hidden: true, visible_on: 1.day.ago, visible_until: nil) }
      end

      succeed 'when only visible_until is set and in the future' do
        before { assignment.update(is_hidden: true, visible_on: nil, visible_until: 1.day.from_now) }
      end

      context 'with section-specific datetime' do
        let(:role) { create(:student, section: new_section) }

        succeed 'when section datetime is valid' do
          before do
            assignment.update(is_hidden: true)
            create(:assessment_section_properties, assessment: assignment, section: new_section,
                                                   visible_on: 1.day.ago, visible_until: 1.day.from_now)
          end
        end

        failed 'when section visible_on is in the future' do
          before do
            assignment.update(is_hidden: false)
            create(:assessment_section_properties, assessment: assignment, section: new_section,
                                                   visible_on: 1.day.from_now, visible_until: 2.days.from_now)
          end
        end

        failed 'when section visible_until is in the past' do
          before do
            assignment.update(is_hidden: false)
            create(:assessment_section_properties, assessment: assignment, section: new_section,
                                                   visible_on: 2.days.ago, visible_until: 1.day.ago)
          end
        end
      end
    end
  end
end
