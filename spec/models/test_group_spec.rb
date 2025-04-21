describe TestGroup do
  subject { create(:test_group, criterion: create(:rubric_criterion)) }

  it { is_expected.to belong_to(:assignment) }
  it { is_expected.to have_many(:test_group_results) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'

  # For booleans, should validate_presence_of does
  # not work: see the Rails API documentation for should validate_presence_of
  # (Model validations)
  # should validate_presence_of does not work for boolean value false.
  # Using should allow_value instead

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :display_output }

  it do
    expect(subject).to(
      define_enum_for(:display_output)
        .with_values(TestGroup.display_outputs.keys)
        .with_prefix(:display_to)
    )
  end

  # create
  context 'A valid test group' do
    before do
      @asst = create(:assignment,
                     due_date: 2.days.from_now,
                     assignment_properties_attributes: { section_due_dates_type: false })

      @test_group = create(:test_group, assignment: @asst)
    end

    it 'return true when a valid test group is created' do
      expect(@test_group).to be_valid
    end
  end

  # update
  context 'An invalid test group' do
    before do
      @asst = create(:assignment,
                     due_date: 2.days.from_now,
                     assignment_properties_attributes: { section_due_dates_type: false })

      @valid_test_group = create(:test_group, assignment: @asst, display_output: :instructors_and_students)
      @invalid_test_group = create(:test_group, assignment: @asst, display_output: :instructors)
    end

    context 'test group expected to be invalid when assignment is nil' do
      it 'return false when assignment is nil' do
        @invalid_test_group.assessment_id = nil
        expect(@invalid_test_group).not_to be_valid
      end
    end

    context 'test group expected to be invalid when the display_output option has an invalid option' do
      it 'raise an ArgumentError when the display_output option has an invalid option' do
        expect { @invalid_test_group.display_output = 'something_else' }.to raise_error(ArgumentError)
      end
    end
  end
end
