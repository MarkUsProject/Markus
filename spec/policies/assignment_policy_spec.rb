describe AssignmentPolicy do
  let(:context) { { user: user } }
  let(:record) { assignment }
  let(:user) { create :admin }
  let(:assignment) { create :assignment }

  describe_rule :index? do
    succeed
  end

  describe_rule :switch? do
    succeed
  end

  describe_rule :manage? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    context 'user is a ta' do
      succeed 'that can manage assessments' do
        let(:user) { create :ta, manage_assessments: true }
      end
      failed 'that cannot manage assessments' do
        let(:user) { create :ta, manage_assessments: false }
      end
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :view_test_options? do
    context 'user is an admin' do
      let(:user) { create(:admin) }
      succeed 'when tests enabled' do
        let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
      end
      failed 'when tests disabled' do
        let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
      end
    end
    context 'user is a ta' do
      context 'that can run tests' do
        let(:user) { create :ta, run_tests: true }
        succeed 'when tests enabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
        end
        failed 'when tests disabled' do
          let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
        end
      end
      failed 'that cannot run tests' do
        let(:user) { create :ta, run_tests: false }
      end
    end
    context 'user is a student' do
      let(:user) { create(:student) }
      failed 'when student tests disabled' do
        let(:assignment) { build :assignment, assignment_properties_attributes: { enable_student_tests: false } }
      end
      context 'when student tests enabled' do
        let(:assignment) { build :assignment, assignment_properties_attributes: properties }
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
      let(:assignment) { build :assignment, assignment_properties_attributes: { enable_student_tests: false } }
    end
    context 'when student tests enabled' do
      let(:assignment) { build :assignment, assignment_properties_attributes: properties }
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
      let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: true } }
    end
    failed 'when tests disabled' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { enable_test: false } }
    end
  end

  describe_rule :test_groups_exist? do
    succeed 'when test groups exist' do
      before { create :test_group, assignment: assignment }
    end
    failed 'when test groups do not exist'
  end

  describe_rule :tokens_released? do
    succeed 'when token start date is in the past' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { token_start_date: 1.hour.ago } }
    end
    failed 'when token start date is in the future' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { token_start_date: 1.hour.from_now } }
    end
    failed 'when token start date is nil'
  end

  describe_rule :create_group? do
    let(:user) { create :student }
    let(:assignment) { create :assignment, assignment_properties_attributes: properties }
    let(:properties) { { student_form_groups: true, invalid_override: false } }
    let(:past_collection_date?) { false }
    let(:has_accepted_grouping_for?) { false }
    before do
      allow(record).to receive(:past_collection_date?).and_return past_collection_date?
      allow(user).to receive(:has_accepted_grouping_for?).and_return has_accepted_grouping_for?
    end
    succeed 'when collection date has not passed and students can form groups and the user is not in a group yet'
    failed 'when collection date has passed' do
      let(:past_collection_date?) { true }
    end
    failed 'when students cannot form groups' do
      let(:properties) { { student_form_groups: false, invalid_override: false } }
    end
    failed 'when the student is in a group for this assignment' do
      let(:has_accepted_grouping_for?) { true }
    end
  end

  describe_rule :work_alone? do
    succeed 'when group min is one' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { group_min: 1 } }
    end
    failed 'when group min is not one' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { group_min: 2, group_max: 2 } }
    end
  end

  describe_rule :collection_date_passed? do
    let(:user) { create :student }
    succeed 'when the collection date has passed' do
      before { allow(record).to receive(:past_collection_date?).and_return true }
    end
    failed 'when the collection date has not passed' do
      before { allow(record).to receive(:past_collection_date?).and_return false }
    end
  end

  describe_rule :students_form_groups? do
    let(:assignment) { create :assignment, assignment_properties_attributes: properties }
    failed 'when students cannot form groups' do
      let(:properties) { { student_form_groups: false, invalid_override: false } }
    end
    succeed 'when students can form groups' do
      let(:properties) { { student_form_groups: true, invalid_override: false } }
    end
  end

  describe_rule :not_yet_in_group? do
    succeed 'when the user is not in a group' do
      before { allow(user).to receive(:has_accepted_grouping_for?).and_return false }
    end
    failed 'when the user is in a group' do
      before { allow(user).to receive(:has_accepted_grouping_for?).and_return true }
    end
  end

  describe_rule :autogenerate_group_name? do
    succeed 'when group name is autogenerated' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { group_name_autogenerated: true } }
    end
    failed 'when group name is not autogenerated' do
      let(:assignment) { create :assignment, assignment_properties_attributes: { group_name_autogenerated: false } }
    end
  end

  describe_rule :view? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    succeed 'user is a ta' do
      let(:user) { create :ta }
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :manage_tests? do
    succeed 'user is an admin' do
      let(:user) { create(:admin) }
    end
    context 'user is a ta' do
      succeed 'that can manage assessments' do
        let(:user) { create :ta, manage_assessments: true }
      end
      failed 'that cannot manage assessments' do
        let(:user) { create :ta, manage_assessments: false }
      end
    end
    failed 'user is a student' do
      let(:user) { create(:student) }
    end
  end

  describe_rule :start_timed_assignment? do
    let(:user) { create :student }
    let(:due_date) { 2.hours.from_now }
    let(:start_time) { 2.hours.ago }
    let(:assignment) do
      create :timed_assignment,
             due_date: due_date,
             assignment_properties_attributes: { start_time: start_time }
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
          rule = create :penalty_period_submission_rule, assignment: assignment
          create :period, hours: 2, submission_rule: rule
        end
      end
    end
    context 'when the student is in a group' do
      let(:grouping_start_time) { nil }
      let!(:grouping) do
        create :grouping_with_inviter, inviter: user, assignment: assignment, start_time: grouping_start_time
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
    let(:new_section) { create :section }
    let(:user) { create :student, section: new_section }
    let(:assignment) do
      create(:assignment,
             assignment_properties_attributes: { section_due_dates_type: false })
    end
    let(:section_due_date) do
      create(:section_due_date, assessment: assignment,
             section: new_section,
             due_date: 2.days.from_now,
             is_hidden: false)
    end


    context 'when the user is an admin' do
      let(:admin_user) { create(:admin) }

      succeed 'user is an admin' do
        before { assignment.update(is_hidden: true) }
        let(:context) { { user: admin_user } }
      end
    end
    context 'when the user is a TA' do
      let(:ta_user) { create(:ta) }
      succeed 'user is an admin' do
        before { assignment.update(is_hidden: true) }
        let(:context) { { user: ta_user } }
      end
    end
    context 'when there are no section due dates' do
      succeed 'when the assignment is not hidden' do
      end
      failed 'when the assignment is hidden' do
        before { assignment.update(is_hidden: true) }
      end
    end
    context 'when there are section due dates' do
      before do
        assignment.assignment_properties.update(section_due_dates_type: true)
        section_due_date
      end
      succeed 'when visible with section due date and assignment' do
      end
      succeed 'when assignment hidden but section do date ' do
        before {assignment.update(is_hidden: true)}
      end
      failed 'when section due date hidden' do
        before { section_due_date.update(is_hidden: true) }
      end
    end
  end
end
