describe AssignmentProperties do
  describe 'ActiveModel validations' do
    it { is_expected.to validate_presence_of(:repository_folder) }
    it { is_expected.to validate_presence_of(:group_min) }
    it { is_expected.to validate_presence_of(:group_max) }
    it { is_expected.to validate_inclusion_of(:starter_file_type).in_array(AssignmentProperties::STARTER_FILE_TYPES) }

    it { is_expected.to validate_numericality_of(:group_min).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:group_max).is_greater_than(0) }

    it { should allow_value(true).for(:allow_web_submits) }
    it { should allow_value(false).for(:allow_web_submits) }
    it { should allow_value(true).for(:display_grader_names_to_students) }
    it { should allow_value(false).for(:display_grader_names_to_students) }

    it 'should not be valid with a negative duration' do
      extension = build(:timed_assignment, assignment_properties_attributes: { duration: -10.hours })
      expect(extension.valid?).to be(false)
    end
    it 'should be valid with a positive duration' do
      expect(build(:timed_assignment).valid?).to be(true)
    end
    it 'should not be valid with a nil duration' do
      extension = build(:timed_assignment, assignment_properties_attributes: { duration: nil })
      expect(extension.valid?).to be(false)
    end
    it 'should be valid with a bad duration if the assignment is not timed' do
      extension = build(:assignment, assignment_properties_attributes: { duration: -10.hours })
      expect(extension.valid?).to be(true)
    end
    it 'should check presence of start_time if this is a timed assignment' do
      extension = build(:timed_assignment, assignment_properties_attributes: { start_time: nil })
      expect(extension.valid?).to be(false)
    end
    it 'should not check presence of start_time if this is a timed assignment' do
      extension = build(:assignment, assignment_properties_attributes: { start_time: nil })
      expect(extension.valid?).to be(true)
    end
    it 'should check that the start_time is before the due_date if this is a timed assignment' do
      extension = build(:timed_assignment,
                        due_date: Time.now,
                        assignment_properties_attributes: { start_time: Time.now + 1.hour })
      expect(extension.valid?).to be(false)
    end
    it 'should not check that the start_time is before the due_date if this is a timed assignment' do
      extension = build(:assignment,
                        due_date: Time.now,
                        assignment_properties_attributes: { start_time: Time.now + 1.hour })
      expect(extension.valid?).to be(true)
    end
    it 'should not permit an assignment to be both scanned and timed' do
      extension = build(:timed_assignment, assignment_properties_attributes: { scanned_exam: true })
      expect(extension.valid?).to be(false)
    end
  end
  describe '#duration_parts' do
    let(:assignment) { create(:timed_assignment) }
    let(:parts) { assignment.duration_parts }
    it 'should return the duration attribute calculated as DURATION_PARTS' do
      duration_from_parts = AssignmentProperties::DURATION_PARTS.map { |part| parts[part].to_i.send(part) }.sum
      expect(assignment.duration).to eq(duration_from_parts)
    end
    it 'should return only the parts in DURATION_PARTS' do
      expect(parts.keys).to contain_exactly(*AssignmentProperties::DURATION_PARTS)
    end
  end
  describe 'self.duration_parts' do
    it 'should return the duration attribute calculated as DURATION_PARTS' do
      expect(AssignmentProperties.duration_parts(1.hour + 2.minutes)).to eq(hours: 1, minutes: 2)
    end
    it 'should return only the parts in DURATION_PARTS' do
      parts = AssignmentProperties.duration_parts(1.hour + 2.seconds)
      expect(parts.keys).to contain_exactly(*AssignmentProperties::DURATION_PARTS)
    end
  end
  describe '#adjusted_duration' do
    let(:assignment) { create(:timed_assignment) }
    context 'when there is no penalty period' do
      it 'should return the duration' do
        expect(assignment.adjusted_duration).to eq assignment.duration
      end
    end
    context 'when there is a penalty period' do
      let(:rule) { create :penalty_period_submission_rule, assignment: assignment }
      let!(:period) { create :period, submission_rule: rule }
      it 'should return the duration plus penalty period hours' do
        skip 'fails on travis only because the object is not properly reloaded'
        expect(assignment.reload.adjusted_duration).to eq(assignment.duration + period.hours.hours)
      end
    end
  end
end
