describe TestGroup do
  it { is_expected.to belong_to(:assignment) }
  it { is_expected.to have_many(:test_group_results) }

  # For booleans, should validate_presence_of does
  # not work: see the Rails API documentation for should validate_presence_of
  # (Model validations)
  # should validate_presence_of does not work for boolean value false.
  # Using should allow_value instead

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :display_output }
  it { is_expected.to allow_value(true).for(:run_by_instructors) }
  it { is_expected.to allow_value(false).for(:run_by_instructors) }
  it { is_expected.to allow_value(true).for(:run_by_students) }
  it { is_expected.to allow_value(false).for(:run_by_students) }
  it { is_expected.to validate_inclusion_of(:display_output).in_array(TestGroup::DISPLAY_OUTPUT_OPTIONS) }

  # create
  context 'A valid test group' do
    before(:each)  do
      @asst = create(:assignment,
                     section_due_dates_type: false,
                     due_date: 2.days.from_now)

      @test_group = TestGroup.create(assignment_id:      @asst.id,
                                     name:               'test_group',
                                     run_by_instructors: true,
                                     run_by_students:    true,
                                     display_output:     TestGroup::TO_INSTRUCTORS)
    end

    it 'return true when a valid test group is created' do
      expect(@test_group).to be_valid
    end
  end

  # update
  context 'An invalid test group' do
    before(:each)  do
      @asst = create(:assignment,
                     section_due_dates_type: false,
                     due_date: 2.days.from_now)
      display_option = TestGroup::DISPLAY_OUTPUT_OPTIONS

      @valid_test_group = TestGroup.create(assignment_id:        @asst.id,
                                           name:                 'valid_test_group',
                                           run_by_instructors:   true,
                                           run_by_students:      true,
                                           display_output:       display_option[2])

      @invalid_test_group = TestGroup.create(assignment_id:      @asst.id,
                                             name:               'invalid_test_group',
                                             run_by_instructors: true,
                                             run_by_students:    true,
                                             display_output:     display_option[0])
    end

    context 'test group expected to be invalid when assignment is nil' do
      it 'return false when assignment is nil' do
        @invalid_test_group.assignment_id = nil
        expect(@invalid_test_group).not_to be_valid
      end
    end

    context 'test group expected to be invalid when the name already exists in the same assignment' do
      it 'return false when the file_name already exists' do
        @invalid_test_group.name = 'valid_test_group'
        expect(@invalid_test_group).not_to be_valid
      end
    end

    context 'test group expected to be invalid when the display_output option has an invalid option' do
      it 'return false when the display_output option has an invalid option' do
        @invalid_test_group.display_output = 'something_else'
        expect(@invalid_test_group).not_to be_valid
      end
    end
  end
end
