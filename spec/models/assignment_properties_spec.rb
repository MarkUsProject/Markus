describe AssignmentProperties do
  describe 'ActiveModel validations' do
    it { is_expected.to validate_presence_of(:repository_folder) }
    it { is_expected.to validate_presence_of(:group_min) }
    it { is_expected.to validate_presence_of(:group_max) }
    it { is_expected.to validate_presence_of(:notes_count) }

    it do
      is_expected.to validate_numericality_of(:group_min).is_greater_than(0)
    end
    it do
      is_expected.to validate_numericality_of(:group_max).is_greater_than(0)
    end

    it { should allow_value(true).for(:allow_web_submits) }
    it { should allow_value(false).for(:allow_web_submits) }
    it { should allow_value(true).for(:display_grader_names_to_students) }
    it { should allow_value(false).for(:display_grader_names_to_students) }
  end
end
